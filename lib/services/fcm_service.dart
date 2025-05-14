import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    // Configure background messaging handler first
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission for notifications with provisional permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
      criticalAlert: true,
    );
    
    // Configure FCM for background operation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        // Save token to Firestore
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set background notification handling
      await _messaging.setAutoInitEnabled(true);
      
      // Handle initial message when app is terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
      
      // Handle when user taps on notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Start the background database listener service
      await _startDatabaseListenerService();
    }
  }

  Future<void> _startDatabaseListenerService() async {
    const platform = MethodChannel('com.sams.binit/background_service');
    try {
      await platform.invokeMethod('startDatabaseListenerService');
    } catch (e) {
      print('Failed to start database listener service: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
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
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle notification tap when app is in background
    // You can add navigation logic here if needed
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  
  // Initialize notification service
  await NotificationService().init();

  // Show notification based on message type
  if (message.data['type'] == 'offer_accepted') {
    await NotificationService().showOfferAccepted(
      company: message.data['companyName'] ?? 'A company',
      kilos: num.tryParse(message.data['kilos']?.toString() ?? '0') ?? 0,
    );
  } else if (message.data['type'] == 'bin_level_update') {
    await NotificationService().showBinLevelUpdate(
      binName: message.data['binName'] ?? 'Unknown',
      material: message.data['material'] ?? 'Unknown',
      level: message.data['level']?.toString() ?? '0%',
    );
  }
}