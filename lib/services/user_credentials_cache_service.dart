import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for caching user credentials to enable notifications
/// when the app is terminated
class UserCredentialsCacheService {
  // Singleton pattern
  static final UserCredentialsCacheService _instance = UserCredentialsCacheService._internal();
  factory UserCredentialsCacheService() => _instance;
  UserCredentialsCacheService._internal();
  
  // Keys for SharedPreferences
  static const String _userIdKey = 'cached_user_id';
  static const String _userTypeKey = 'cached_user_type';
  static const String _registeredBinsKey = 'cached_registered_bins';
  static const String _timestampKey = 'cached_timestamp';
  static const String _fcmTokenKey = 'cached_fcm_token';
  
  // Secure storage for sensitive data
  final _secureStorage = const FlutterSecureStorage();
  
  // Cache user credentials
  Future<void> cacheUserCredentials({
    required String userId,
    required String userType,
    required List<String> registeredBins,
    String? fcmToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store non-sensitive data in SharedPreferences
    await prefs.setString(_userTypeKey, userType);
    await prefs.setStringList(_registeredBinsKey, registeredBins);
    await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    
    // Store sensitive data in secure storage
    await _secureStorage.write(key: _userIdKey, value: userId);
    
    // Store FCM token if available
    if (fcmToken != null) {
      await _secureStorage.write(key: _fcmTokenKey, value: fcmToken);
    }
    
    print('UserCredentialsCacheService: Credentials cached for user $userId');
  }
  
  // Get cached user ID
  Future<String?> getCachedUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }
  
  // Get cached user type
  Future<String?> getCachedUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  // Get cached registered bins
  Future<List<String>> getCachedRegisteredBins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_registeredBinsKey) ?? [];
  }
  
  // Get cached FCM token
  Future<String?> getCachedFCMToken() async {
    return await _secureStorage.read(key: _fcmTokenKey);
  }
  
  // Check if user is bin owner based on cached data
  Future<bool> isCachedUserBinOwner() async {
    final userType = await getCachedUserType();
    return userType == 'binOwner';
  }
  
  // Check if a specific bin is registered to the cached user
  Future<bool> isBinRegisteredToCachedUser(String binId) async {
    final registeredBins = await getCachedRegisteredBins();
    return registeredBins.contains(binId);
  }
  
  // Check if cache is still valid (not older than 30 days)
  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_timestampKey);
    
    if (timestampStr == null) return false;
    
    try {
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      // Cache is valid for 30 days
      return difference.inDays < 30;
    } catch (e) {
      print('Error parsing cache timestamp: $e');
      return false;
    }
  }
  
  // Clear cached credentials
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_userTypeKey);
    await prefs.remove(_registeredBinsKey);
    await prefs.remove(_timestampKey);
    
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _fcmTokenKey);
    
    print('UserCredentialsCacheService: Cache cleared');
  }
  
  // Update registered bins in cache
  Future<void> updateCachedRegisteredBins(List<String> registeredBins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_registeredBinsKey, registeredBins);
    print('UserCredentialsCacheService: Updated cached registered bins');
  }
  
  // Update FCM token in cache
  Future<void> updateCachedFCMToken(String fcmToken) async {
    await _secureStorage.write(key: _fcmTokenKey, value: fcmToken);
    print('UserCredentialsCacheService: Updated cached FCM token');
  }
  
  // Get all cached data as a map (for debugging)
  Future<Map<String, dynamic>> getAllCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _secureStorage.read(key: _userIdKey);
    final fcmToken = await _secureStorage.read(key: _fcmTokenKey);
    
    return {
      'userId': userId,
      'userType': prefs.getString(_userTypeKey),
      'registeredBins': prefs.getStringList(_registeredBinsKey),
      'timestamp': prefs.getString(_timestampKey),
      'fcmToken': fcmToken,
      'isValid': await isCacheValid(),
    };
  }
} 