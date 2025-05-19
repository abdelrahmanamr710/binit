import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'user_credentials_cache_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();
  final UserCredentialsCacheService _userCredentialsCacheService = UserCredentialsCacheService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> init() async {
    print("FCM Service: Initializing");
    // Note: The background message handler is now registered in main.dart
    // This ensures it's set up before any FCM operations
    
    // Request permission for notifications with provisional permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
      criticalAlert: true,
      announcement: true,
      carPlay: true,
    );
    
    // Configure FCM for background operation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    print("FCM Authorization status: ${settings.authorizationStatus}");
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      String? token = await _messaging.getToken();
      print("FCM Token: $token");
      if (token != null) {
        // Save token to Firestore
        await _saveFCMToken(token);
        
        // Also update the cached FCM token
        await _userCredentialsCacheService.updateCachedFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((String token) async {
        await _saveFCMToken(token);
        await _userCredentialsCacheService.updateCachedFCMToken(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set background notification handling
      await _messaging.setAutoInitEnabled(true);
      
      // Handle initial message when app is terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print("App opened from terminated state with message: ${initialMessage.messageId}");
        _handleMessageOpenedApp(initialMessage);
      }
      
      // Handle when user taps on notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("App opened from background state with message: ${message.messageId}");
        _handleMessageOpenedApp(message);
      });

      // Subscribe to topics for bin owners
      await _subscribeToTopics();

      // Start the background database listener service
      await _startDatabaseListenerService();
      
      // Set up database listeners for bin levels
      await _setupDatabaseListeners();
      
      print("FCM Service: Initialization complete");
    } else {
      print("FCM authorization denied");
    }
  }

  Future<void> _setupDatabaseListeners() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("FCM: No user logged in, not setting up database listeners");
      return;
    }
    
    try {
      // Check if user is a bin owner
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      print("FCM: User type check - ${userDoc.data()?['userType']}");
      
      if (!userDoc.exists || userDoc.data()?['userType'] != 'binOwner') {
        print("FCM: User is not a binOwner, not setting up database listeners");
        return;
      }
      
      // Get user's registered bins
      final userBinsRef = _database.ref().child('users').child(user.uid).child('registeredBins');
      final snapshot = await userBinsRef.get();
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> bins = snapshot.value as Map;
        print("FCM: Found ${bins.length} registered bins");
        for (var binId in bins.keys) {
          // Set up listeners for plastic and metal levels
          _setupBinLevelListener(binId.toString(), 'plastic');
          _setupBinLevelListener(binId.toString(), 'metal');
        }
      } else {
        print("FCM: No registered bins found for user");
      }
    } catch (e) {
      print("Error setting up database listeners: $e");
    }
  }
  
  void _setupBinLevelListener(String binId, String material) {
    final levelRef = _database.ref().child('BIN').child(binId).child(material).child('level');
    print("Setting up FCM listener for path: BIN/$binId/$material/level");
    
    levelRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final level = event.snapshot.value?.toString();
        print("FCM received level update for $binId-$material: $level");
        
        _notificationService.showBinLevelUpdate(
          binName: 'Bin $binId',
          material: material[0].toUpperCase() + material.substring(1),
          level: level ?? '0%',
        );
      }
    });
  }

  Future<void> _subscribeToTopics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Check if we have cached credentials
        final isBinOwner = await _userCredentialsCacheService.isCachedUserBinOwner();
        if (isBinOwner) {
          // Subscribe to bin owner topics
          await _messaging.subscribeToTopic('bin_owners');
          print("Subscribed to bin_owners topic using cached credentials");
        }
        return;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data();
      if (userData == null) return;
      
      final userType = userData['userType'] as String?;
      
      if (userType == 'binOwner') {
        // Subscribe to bin owner topics
        await _messaging.subscribeToTopic('bin_owners');
        print("Subscribed to bin_owners topic");
        
        // Get registered bins
        final registeredBins = await _getRegisteredBins(user.uid);
        
        // Subscribe to each bin's topic
        for (final binId in registeredBins) {
          await _messaging.subscribeToTopic('bin_$binId');
          print("Subscribed to bin_$binId topic");
        }
        
        // Cache user credentials
        await _userCredentialsCacheService.cacheUserCredentials(
          userId: user.uid,
          userType: 'binOwner',
          registeredBins: registeredBins,
          fcmToken: await _messaging.getToken(),
        );
      } else if (userType == 'recyclingCompany') {
        // Subscribe to recycling company topics
        await _messaging.subscribeToTopic('recycling_companies');
        print("Subscribed to recycling_companies topic");
        
        // Cache user credentials
        await _userCredentialsCacheService.cacheUserCredentials(
          userId: user.uid,
          userType: 'recyclingCompany',
          registeredBins: [],
          fcmToken: await _messaging.getToken(),
        );
      }
    } catch (e) {
      print("Error subscribing to topics: $e");
    }
  }
  
  // Get registered bins for a user
  Future<List<String>> _getRegisteredBins(String userId) async {
    try {
      final registeredBinsSnapshot = await FirebaseFirestore.instance
          .collection('registered_bins')
          .where('owners', arrayContains: userId)
          .get();
      
      return registeredBinsSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting registered bins: $e');
      return [];
    }
  }

  Future<void> _startDatabaseListenerService() async {
    const platform = MethodChannel('com.sams.binit/background_service');
    try {
      await platform.invokeMethod('startDatabaseListenerService');
      print("Database listener service started successfully");
    } catch (e) {
      print('Failed to start database listener service: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        print("FCM token saved to Firestore");
      } catch (e) {
        print("Error saving FCM token: $e");
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print("Received foreground message: ${message.messageId}");
    print("Message data: ${message.data}");
    
    if (message.data['type'] == 'offer_accepted') {
      await _notificationService.showOfferAccepted(
        company: message.data['companyName'] ?? 'A company',
        kilos: num.tryParse(message.data['kilos']?.toString() ?? '0') ?? 0,
      );
    } else if (message.data['type'] == 'bin_level_update') {
      await _notificationService.showBinLevelUpdate(
        binName: message.data['binName'] ?? 'Unknown',
        material: message.data['material'] ?? 'Unknown',
        level: message.data['level']?.toString() ?? '0%',
        binId: message.data['binId'],
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle notification tap when app is in background
    // You can add navigation logic here if needed
    print("User tapped on notification: ${message.messageId}");
  }
  
  // Test function to send a notification for testing purposes
  Future<void> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in, can't send test notification");
        return;
      }
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        print("User document not found");
        return;
      }
      
      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        print("FCM token not found for user");
        return;
      }
      
      // Create a test notification using Cloud Functions
      await FirebaseFirestore.instance.collection('notifications').add({
        'token': fcmToken,
        'title': 'Test Notification',
        'body': 'This is a test notification',
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'created_at': FieldValue.serverTimestamp(),
      });
      
      print("Test notification sent");
    } catch (e) {
      print("Error sending test notification: $e");
    }
  }
  
  // Call the test notification Cloud Function
  Future<void> sendTestNotificationViaCloudFunction() async {
    try {
      print("Calling test notification Cloud Function");
      
      // Call the Cloud Function
      final result = await _functions.httpsCallable('sendTestNotification').call();
      
      print("Cloud Function result: ${result.data}");
    } catch (e) {
      print("Error calling Cloud Function: $e");
    }
  }
}

// Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
  
  // Extract data from the message
  final data = message.data;
  final messageType = data['type'] ?? '';
  
  try {
    // Handle different message types
    switch (messageType) {
      case 'bin_level_update':
        final binName = data['binName'] ?? 'Unknown';
        final material = data['material'] ?? 'Unknown';
        final level = data['level'] ?? '0';
        
        // Show notification directly without checking user type
        // (we're in background so we can't access Firestore easily)
        await NotificationService().showBinLevelUpdate(
          binName: binName,
          material: material,
          level: level,
        );
        break;
        
      case 'offer_accepted':
        final company = data['company'] ?? 'Unknown';
        final kilos = num.tryParse(data['kilos'] ?? '0') ?? 0;
        
        await NotificationService().showOfferAccepted(
          company: company,
          kilos: kilos,
        );
        break;
        
      default:
        // For unknown message types, show a generic notification
        if (message.notification != null) {
          final title = message.notification!.title ?? 'New Notification';
          final body = message.notification!.body ?? 'You have a new notification';
          
          // Use notification service to show the notification
          // This will handle notification channels properly
          print("Showing generic notification: $title - $body");
        }
    }
  } catch (e) {
    print("Error handling background message: $e");
  }
}