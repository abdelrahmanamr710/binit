import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:binit/services/user_credentials_cache_service.dart';

class NotificationService {
  // Singleton
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  late SharedPreferences _prefs;
  
  // Cache for user type to avoid repeated Firestore queries
  bool? _isUserBinOwner;
  String? _cachedUserId;

  // Keys for SharedPreferences
  static const String _sentNotificationsKey = 'sent_notifications';
  static const String _userTypeKey = 'user_type_cache';
  static const String _allowBackgroundNotificationsKey = 'allow_background_notifications';
  static const String _lastNotificationTimeKey = 'last_notification_time';
  static const int _notificationCooldownMs = 5000; // 5 seconds cooldown

  // User credentials cache service
  final _userCredentialsCacheService = UserCredentialsCacheService();

  // Constants for notification channels
  static const String _binLevelChannelId = 'binit_level_channel';
  static const String _offerChannelId = 'binit_channel';
  static const String _highImportanceChannelId = 'high_importance_channel';
  static const String _databaseServiceChannelId = 'database_service_channel';

  Future<void> init() async {
    print("NotificationService: Initializing");
    // Initialize SharedPreferences first
    _prefs = await SharedPreferences.getInstance();
    
    // Load cached user type if available
    _loadCachedUserType();
    
    // Enable background notifications by default
    if (!_prefs.containsKey(_allowBackgroundNotificationsKey)) {
      await _prefs.setBool(_allowBackgroundNotificationsKey, true);
    }
    
    // Then initialize notifications with optimized channels
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      // Request permissions during initialization
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // Add notification categories for iOS
      notificationCategories: [
        DarwinNotificationCategory(
          'bin_updates',
          actions: [
            DarwinNotificationAction.plain('view', 'View Bin'),
            DarwinNotificationAction.plain(
              'dismiss',
              'Dismiss',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          'offers',
          actions: [
            DarwinNotificationAction.plain('view_offer', 'View Details'),
          ],
        ),
      ],
    );
    
    // Add Windows and Linux support
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    
    await _plugin.initialize(
      InitializationSettings(
        android: androidSettings, 
        iOS: iosSettings,
        macOS: iosSettings,
        linux: linuxSettings,
      ),
      // Handle notification taps
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        // Handle notification actions
        if (response.actionId != null) {
          print('Action selected: ${response.actionId}');
          _handleNotificationAction(response.actionId!, response.payload);
        }
      },
    );
    
    // Create notification channels with proper settings
    await _createNotificationChannels();
    
    print("NotificationService: Initialization complete");
  }
  
  // Handle notification actions
  void _handleNotificationAction(String actionId, String? payload) {
    switch (actionId) {
      case 'view':
        print('View bin action selected with payload: $payload');
        // Navigate to bin details screen
        break;
      case 'view_offer':
        print('View offer action selected with payload: $payload');
        // Navigate to offer details screen
        break;
      case 'dismiss':
        print('Dismiss action selected');
        break;
    }
  }
  
  // Create optimized notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Check if notifications are enabled
      final areNotificationsEnabled = await androidPlugin.areNotificationsEnabled();
      print("Notifications enabled: $areNotificationsEnabled");
      
      // Request notification permissions for Android 13+
      if (areNotificationsEnabled == false) {
        await androidPlugin.requestNotificationsPermission();
      }
      
      // Create bin level channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _binLevelChannelId,
          'Bin Level Updates',
          description: 'Real-time updates on your bin levels',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // Create offer channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _offerChannelId,
          'Binit Notifications',
          description: 'Updates on your sell offers',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // Create high importance channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _highImportanceChannelId,
          'High Importance Notifications',
          description: 'Critical notifications that should always be shown',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      
      // Create database service channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _databaseServiceChannelId,
          'Database Service Channel',
          description: 'Channel for database monitoring service',
          importance: Importance.low,
          enableVibration: false,
          playSound: false,
        ),
      );
    }
  }

  // Load cached user type
  void _loadCachedUserType() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _cachedUserId = userId;
      final userTypeData = _prefs.getString(_userTypeKey);
      if (userTypeData != null) {
        final userData = jsonDecode(userTypeData);
        if (userData['userId'] == userId) {
          _isUserBinOwner = userData['isBinOwner'];
        }
      }
    }
  }
  
  // Save user type to cache
  Future<void> _cacheUserType(bool isBinOwner) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _cachedUserId = userId;
      _isUserBinOwner = isBinOwner;
      await _prefs.setString(_userTypeKey, jsonEncode({
        'userId': userId,
        'isBinOwner': isBinOwner,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Check if notification was already sent
  Future<bool> wasNotificationSent(String notificationId) async {
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    final lastNotificationTime = _prefs.getInt(_lastNotificationTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Check if we're within the cooldown period
    if (currentTime - lastNotificationTime < _notificationCooldownMs) {
      print("Notification skipped: Within cooldown period");
      return true;
    }
    
    // Check if this exact notification was sent
    if (sentNotifications.contains(notificationId)) {
      print("Notification skipped: Already sent");
      return true;
    }
    
    return false;
  }

  // Mark notification as sent
  Future<void> markNotificationAsSent(String notificationId) async {
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    if (!sentNotifications.contains(notificationId)) {
      sentNotifications.add(notificationId);
      // Limit the cache size to prevent excessive storage use
      if (sentNotifications.length > 100) {
        sentNotifications.removeRange(0, 50);
      }
      await _prefs.setStringList(_sentNotificationsKey, sentNotifications);
      await _prefs.setInt(_lastNotificationTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // Check if user is bin owner (with caching)
  Future<bool> _isCurrentUserBinOwner() async {
    // Use cached value if available
    if (_isUserBinOwner != null && _cachedUserId == FirebaseAuth.instance.currentUser?.uid) {
      return _isUserBinOwner!;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If no user is logged in, check cached credentials
        return await _userCredentialsCacheService.isCachedUserBinOwner();
      }
      
      _cachedUserId = user.uid;
      
      // First check if we have a cached value in SharedPreferences
      final cachedType = _prefs.getString(_userTypeKey);
      if (cachedType != null) {
        _isUserBinOwner = cachedType == 'binOwner';
        return _isUserBinOwner!;
      }
      
      // If no cached value, query Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      if (userData == null) return false;
      
      final userType = userData['userType'] as String?;
      final isBinOwner = userType == 'binOwner';
      
      // Cache the result
      _isUserBinOwner = isBinOwner;
      await _prefs.setString(_userTypeKey, userType ?? 'unknown');
      
      // Also update the user credentials cache service
      if (isBinOwner) {
        // Get registered bins
        final registeredBins = await _getRegisteredBins(user.uid);
        
        // Cache user credentials
        await _userCredentialsCacheService.cacheUserCredentials(
          userId: user.uid,
          userType: 'binOwner',
          registeredBins: registeredBins,
        );
      }
      
      return isBinOwner;
    } catch (e) {
      print('Error checking user type: $e');
      return false;
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
  
  // Check if bin is registered to current user or cached user
  Future<bool> _isBinRegisteredToUser(String binId) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        final binDoc = await FirebaseFirestore.instance
            .collection('registered_bins')
            .doc(binId)
            .get();
        
        if (!binDoc.exists) return false;
        
        final data = binDoc.data();
        if (data == null) return false;
        
        final owners = List<String>.from(data['owners'] ?? []);
        return owners.contains(user.uid);
      } catch (e) {
        print('Error checking if bin is registered to user: $e');
      }
    }
    
    // Fall back to cached credentials
    return await _userCredentialsCacheService.isBinRegisteredToCachedUser(binId);
  }

  Future<void> showOfferAccepted({required String company, required num kilos}) async {
    // Check if this is a background notification
    bool isBackground = FirebaseAuth.instance.currentUser == null;
    
    // Only show notifications to binOwners or in background
    if (!isBackground && !await _isCurrentUserBinOwner()) {
      print("Not showing notification: User is not a bin owner");
      return;
    }
    
    // If in background, check cached credentials
    if (isBackground && !await _userCredentialsCacheService.isCachedUserBinOwner()) {
      print("Not showing background notification: Cached user is not a bin owner");
      return;
    }
    
    final notificationId = '${company}_${kilos}_offer';
    if (await wasNotificationSent(notificationId)) return;
    
    // Enhanced Android notification details
    const androidDetails = AndroidNotificationDetails(
      _offerChannelId, 'Binit Notifications',
      channelDescription: 'Updates on your sell offers',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'New offer accepted',
      category: AndroidNotificationCategory.social,
      actions: [
        AndroidNotificationAction('view_offer', 'View Details'),
      ],
    );
    
    // Enhanced iOS notification details
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'offers',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final title = 'Offer Accepted';
    final message = '$company accepted your $kilos kg offer.';
    
    await _plugin.show(
      company.hashCode ^ kilos.hashCode,  // unique ID
      title,
      message,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({'type': 'offer_accepted', 'company': company, 'kilos': kilos}),
    );
    
    // Store notification in sent list
    await markNotificationAsSent(notificationId);
  }

  Future<void> showBinLevelUpdate({
    required String binName,
    required String material,
    required String level,
    String? binId,
  }) async {
    // Check if this is a background notification
    bool isBackground = FirebaseAuth.instance.currentUser == null;
    
    // Only show notifications to binOwners
    if (!isBackground && !await _isCurrentUserBinOwner()) {
      print("Not showing notification: User is not a bin owner");
      return;
    }
    
    // If in background, check cached credentials
    if (isBackground && !await _userCredentialsCacheService.isCachedUserBinOwner()) {
      print("Not showing background notification: Cached user is not a bin owner");
      return;
    }
    
    // If binId is provided, check if bin is registered to user
    if (binId != null && binId.isNotEmpty) {
      final isRegistered = await _isBinRegisteredToUser(binId);
      if (!isRegistered) {
        print("Not showing notification: Bin is not registered to user");
        return;
      }
    }
    
    final notificationId = '${binName}_${material}_${level}_${DateTime.now().millisecondsSinceEpoch}';
    if (await wasNotificationSent(notificationId)) {
      print("Not showing notification: Already sent recently");
      return;
    }

    // Enhanced Android notification details
    final androidDetails = AndroidNotificationDetails(
      _binLevelChannelId,
      'Bin Level Updates',
      channelDescription: 'Real-time updates on your bin levels',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Bin level update',
      category: AndroidNotificationCategory.status,
      actions: [
        AndroidNotificationAction('view', 'View Bin'),
      ],
      styleInformation: BigTextStyleInformation(
        'Your $material bin ($binName) is now $level full.',
        contentTitle: 'Bin Level Update',
        summaryText: '$material bin: $level',
      ),
    );
    
    // Enhanced iOS notification details
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'bin_updates',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      binName.hashCode ^ material.hashCode ^ level.hashCode,
      'Bin Level Update',
      'Your $material bin ($binName) is now $level full.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({
        'type': 'bin_level', 
        'binName': binName, 
        'material': material, 
        'level': level,
        'binId': binId,
      }),
    );
    
    // Store notification in Firestore for tracking
    await _storeNotification(
      notificationId: notificationId,
      type: 'bin_level_update',
      title: 'Bin Level Update',
      message: 'Your $material bin ($binName) is now $level full.',
      data: {
        'binName': binName, 
        'material': material, 
        'level': level,
        'binId': binId,
      },
    );
    
    // Store notification in sent list
    await markNotificationAsSent(notificationId);
  }

  // Store notification in Firestore for tracking
  Future<void> _storeNotification({
    required String notificationId,
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    String? userId;
    
    if (user != null) {
      userId = user.uid;
    } else {
      // If no user is logged in, try to get the cached user ID
      userId = await _userCredentialsCacheService.getCachedUserId();
    }
    
    if (userId == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'type': type,
            'title': title,
            'message': message,
            'data': data,
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error storing notification: $e');
    }
  }
  
  // Get notification settings
  Future<bool> getBackgroundNotificationsEnabled() async {
    return _prefs.getBool(_allowBackgroundNotificationsKey) ?? true;
  }
  
  // Set notification settings
  Future<void> setBackgroundNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_allowBackgroundNotificationsKey, enabled);
  }
  
  // Check if notifications are enabled at the system level
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final result = await androidPlugin.areNotificationsEnabled();
      return result ?? false;
    }
    return true;
  }
  
  // Request notification permissions
  Future<void> requestNotificationsPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  // Get active notifications
  Future<List<ActiveNotification>> getActiveNotifications() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notifications = await androidPlugin.getActiveNotifications();
      return notifications ?? [];
    }
    return [];
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // Method to handle notifications from native Android
  Future<void> handleNativeNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    // Check if this is a background notification
    bool isBackground = FirebaseAuth.instance.currentUser == null;
    
    // Only show notifications to binOwners
    if (!isBackground && !await _isCurrentUserBinOwner()) {
      print("Not showing notification: User is not a bin owner");
      return;
    }
    
    // If in background, check cached credentials
    if (isBackground && !await _userCredentialsCacheService.isCachedUserBinOwner()) {
      print("Not showing background notification: Cached user is not a bin owner");
      return;
    }

    switch (type) {
      case 'bin_level_update':
        if (data != null) {
          await showBinLevelUpdate(
            binName: data['binName'] ?? 'Unknown',
            material: data['material'] ?? 'Unknown',
            level: data['level'] ?? '0',
            binId: data['binId'],
          );
        }
        break;
      case 'offer_accepted':
        if (data != null) {
          await showOfferAccepted(
            company: data['company'] ?? 'Unknown',
            kilos: num.tryParse(data['kilos']?.toString() ?? '0') ?? 0,
          );
        }
        break;
      default:
        // Show generic notification
        await _showGenericNotification(title, body);
    }
  }

  // Method to show generic notifications
  Future<void> _showGenericNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      _highImportanceChannelId,
      'High Importance Notifications',
      channelDescription: 'Channel for high importance notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}

// Extension to make the code more readable
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
