import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Check if current user is a binOwner
  Future<bool> _isCurrentUserBinOwner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      return userData != null && userData['userType'] == 'binOwner';
    } catch (e) {
      print('Error checking user type: $e');
      return false;
    }
  }

  Future<void> showOfferAccepted({required String company, required num kilos}) async {
    // Only show notifications to binOwners
    if (!await _isCurrentUserBinOwner()) return;
    
    final notificationId = '${company}_${kilos}_offer';
    if (await _wasNotificationSent(notificationId)) return;
    const androidDetails = AndroidNotificationDetails(
      'binit_channel', 'Binit Notifications',
      channelDescription: 'Updates on your sell offers',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    final title = 'Offer Accepted';
    final message = '$company accepted your $kilos kg offer.';
    
    await _plugin.show(
      company.hashCode ^ kilos.hashCode,  // unique ID
      title,
      message,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    
    // Store notification in Firestore for tracking
    await _storeNotification(
      notificationId: notificationId,
      type: 'offer_accepted',
      title: title,
      message: message,
      data: {'company': company, 'kilos': kilos},
    );
    
    await _markNotificationAsSent(notificationId);
  }

  Future<void> showBinLevelUpdate({required String binName, required String material, required String level}) async {
    // Only show notifications to binOwners
    if (!await _isCurrentUserBinOwner()) return;
    
    final notificationId = '${binName}_${material}_${level}_level';
    if (await _wasNotificationSent(notificationId)) return;
    const androidDetails = AndroidNotificationDetails(
      'binit_level_channel', 'Bin Level Notifications',
      channelDescription: 'Updates on bin fill levels',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    final title = 'Bin Level Update';
    final message = '$binName bin for $material is now $level full.';
    
    await _plugin.show(
      binName.hashCode ^ material.hashCode ^ level.hashCode,  // unique ID
      title,
      message,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    
    // Store notification in Firestore for tracking
    await _storeNotification(
      notificationId: notificationId,
      type: 'bin_level_update',
      title: title,
      message: message,
      data: {'binName': binName, 'material': material, 'level': level},
    );
    
    await _markNotificationAsSent(notificationId);
  }
  
  // Store notification in Firestore for tracking
  Future<void> _storeNotification({
    required String notificationId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).set({
        'userId': user.uid,
        'type': type,
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'data': data ?? {},
      });
    } catch (e) {
      print('Error storing notification: $e');
    }
  }
}
