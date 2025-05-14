import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  // Singleton
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;

  // Keys for SharedPreferences
  static const String _sentNotificationsKey = 'sent_notifications';

  Future<void> init() async {
    // Initialize SharedPreferences first
    _prefs = await SharedPreferences.getInstance();
    
    // Then initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // Check if notification was already sent
  Future<bool> _wasNotificationSent(String notificationId) async {
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    return sentNotifications.contains(notificationId);
  }

  // Mark notification as sent
  Future<void> _markNotificationAsSent(String notificationId) async {
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    if (!sentNotifications.contains(notificationId)) {
      sentNotifications.add(notificationId);
      await _prefs.setStringList(_sentNotificationsKey, sentNotifications);
    }
  }

  Future<void> showOfferAccepted({required String company, required num kilos}) async {
    final notificationId = '${company}_${kilos}_offer';
    if (await _wasNotificationSent(notificationId)) return;
    const androidDetails = AndroidNotificationDetails(
      'binit_channel', 'Binit Notifications',
      channelDescription: 'Updates on your sell offers',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      company.hashCode ^ kilos.hashCode,  // unique ID
      'Offer Accepted',
      '$company accepted your $kilos kg offer.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    
    await _markNotificationAsSent(notificationId);
  }

  Future<void> showBinLevelUpdate({required String binName, required String material, required String level}) async {
    final notificationId = '${binName}_${material}_${level}_level';
    if (await _wasNotificationSent(notificationId)) return;
    const androidDetails = AndroidNotificationDetails(
      'binit_level_channel', 'Bin Level Notifications',
      channelDescription: 'Updates on bin fill levels',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      binName.hashCode ^ material.hashCode,  // unique ID
      'Bin Level Update',
      '$binName $material bin is now $level full.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    
    await _markNotificationAsSent(notificationId);
  }
}
