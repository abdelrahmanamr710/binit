import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;
  FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> init() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
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

      // Handle background messages when app is in background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle when user taps on notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
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

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      if (message.data['type'] == 'offer_accepted') {
        _notificationService.showOfferAccepted(
          company: message.data['companyName'] ?? 'A company',
          kilos: num.tryParse(message.data['kilos']?.toString() ?? '0') ?? 0,
        );
      } else if (message.data['type'] == 'bin_level_update') {
        _notificationService.showBinLevelUpdate(
          binName: message.data['binName'] ?? 'Unknown',
          material: message.data['material'] ?? 'Unknown',
          level: message.data['level']?.toString() ?? '0%',
        );
      }
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