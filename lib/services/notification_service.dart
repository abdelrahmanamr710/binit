import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> showOfferAccepted({required String company, required num kilos}) async {
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
  }

// Add more helper methods here for other notification types…

  Future<void> showBinLevelUpdate({required String binName, required String material, required String level}) async {
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
  }
}
