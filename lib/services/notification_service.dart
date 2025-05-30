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
    // First check local cache for recent notifications
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    final lastNotificationTime = _prefs.getInt(_lastNotificationTimeKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Check if we're within the cooldown period
    if (currentTime - lastNotificationTime < _notificationCooldownMs) {
      print("Notification skipped: Within cooldown period");
      return true;
    }
    
    // Check if this exact notification was sent in local cache
    if (sentNotifications.contains(notificationId)) {
      print("Notification skipped: Found in local cache");
      return true;
    }

    // Check Firestore for existing notification
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existingDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .get();

        if (existingDoc.exists) {
          print("Notification skipped: Found in Firestore");
          return true;
        }
      } else {
        // If no user is logged in, check cached user
        final cachedUserId = await _userCredentialsCacheService.getCachedUserId();
        if (cachedUserId != null) {
          final existingDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(cachedUserId)
              .collection('notifications')
              .doc(notificationId)
              .get();

          if (existingDoc.exists) {
            print("Notification skipped: Found in Firestore for cached user");
            return true;
          }
        }
      }
    } catch (e) {
      print('Error checking Firestore for existing notification: $e');
      // If we can't check Firestore, fall back to local cache result
      return false;
    }
    
    return false;
  }

  // Mark notification as sent
  Future<void> markNotificationAsSent(String notificationId) async {
    final sentNotifications = _prefs.getStringList(_sentNotificationsKey) ?? [];
    if (!sentNotifications.contains(notificationId)) {
      sentNotifications.add(notificationId);
      // Keep only the last 100 notifications in local cache
      if (sentNotifications.length > 100) {
        sentNotifications.removeRange(0, 50);
      }
      await _prefs.setStringList(_sentNotificationsKey, sentNotifications);
      await _prefs.setInt(_lastNotificationTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // Generate a unique notification ID that includes timestamp
  String _generateNotificationId(String baseId) {
    return '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
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
      
      // Query Firestore for user type
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
      await _cacheUserType(isBinOwner);
      
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

  // Check if notifications are enabled for specific type
  Future<bool> areNotificationsEnabledForType(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final prefsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('notificationSettings')
          .get();

      if (!prefsDoc.exists) return true; // Default to enabled if no preferences set

      final data = prefsDoc.data()!;
      switch (type) {
        case 'bin_level':
          return data['binLevelUpdates'] ?? true;
        case 'offer':
          return data['offerNotifications'] ?? true;
        case 'system':
          return data['systemNotifications'] ?? true;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking notification preferences: $e');
      return true; // Default to enabled on error
    }
  }

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
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  Future<void> showOfferAccepted({
    required String company,
    required num kilos
  }) async {
    // Check if offer notifications are enabled
    if (!await areNotificationsEnabledForType('offer')) {
      print("Offer notifications are disabled");
      return;
    }

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
    
    // Generate a unique notification ID without timestamp (for deduplication)
    final baseNotificationId = '${company}_${kilos}_offer';
    // Check if a similar notification was sent recently
    if (await wasNotificationSent(baseNotificationId)) {
      print("Offer notification skipped: Similar notification exists");
      return;
    }
    
    // If not sent, generate unique ID with timestamp for storage
    final notificationId = _generateNotificationId(baseNotificationId);
    
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
    
    // Store notification in Firestore
    await _storeNotification(
      notificationId: notificationId,
      type: 'offer_accepted',
      title: title,
      message: message,
      data: {'company': company, 'kilos': kilos},
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
    // Check if bin level notifications are enabled
    if (!await areNotificationsEnabledForType('bin_level')) {
      print("Bin level notifications are disabled");
      return;
    }

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
    
    // Generate a unique notification ID without timestamp (for deduplication)
    final baseNotificationId = '${binName}_${material}_${level}';
    // Check if a similar notification was sent recently
    if (await wasNotificationSent(baseNotificationId)) {
      print("Bin level notification skipped: Similar notification exists");
      return;
    }
    
    // If not sent, generate unique ID with timestamp for storage
    final notificationId = _generateNotificationId(baseNotificationId);
    
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

    final title = 'Bin Level Update';
    final message = 'Your $material bin ($binName) is now $level full.';

    await _plugin.show(
      binName.hashCode ^ material.hashCode ^ level.hashCode,
      title,
      message,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({
        'type': 'bin_level', 
        'binName': binName, 
        'material': material, 
        'level': level,
        'binId': binId,
      }),
    );
    
    // Store notification in Firestore
    await _storeNotification(
      notificationId: notificationId,
      type: 'bin_level_update',
      title: title,
      message: message,
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

  Future<void> showSystemNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    // Check if system notifications are enabled
    if (!await areNotificationsEnabledForType('system')) {
      print("System notifications are disabled");
      return;
    }

    // Rest of your existing system notification code...
  }
}

// Extension to make the code more readable
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
