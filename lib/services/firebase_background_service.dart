import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'dart:async';

class FirebaseBackgroundService {
  // Singleton pattern
  static final FirebaseBackgroundService _instance = FirebaseBackgroundService._internal();
  factory FirebaseBackgroundService() => _instance;
  FirebaseBackgroundService._internal();
  
  // Keep track of active database listeners
  final Map<String, StreamSubscription<DatabaseEvent>> _activeListeners = {};
  
  Future<void> initialize() async {
    print("Initializing Firebase Background Service");
    
    // Ensure Firebase Database persistence is enabled for offline support
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (e) {
      print("Persistence already enabled or could not be enabled: $e");
    }
    
    // Set up listeners for the current user's bins
    await setupBinListeners();
  }
  
  Future<void> setupBinListeners() async {
    // Clean up any existing listeners first
    await stopAllListeners();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in, not setting up bin listeners");
      return;
    }
    
    print("Setting up bin listeners for user: ${user.uid}");
    
    // Listen for changes to the user's registered bins
    final userBinsRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('registeredBins');
    
    // Add listener for changes to the registered bins list
    final binsListListener = userBinsRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        print("No registered bins found for user");
        return;
      }
      
      final Map<dynamic, dynamic> bins = event.snapshot.value as Map;
      print("Found ${bins.length} registered bins, setting up listeners");
      
      // Set up listeners for each bin
      for (var binId in bins.keys) {
        _setupBinLevelListeners(binId.toString());
      }
    });
    
    _activeListeners['user_bins_list'] = binsListListener;
  }
  
  void _setupBinLevelListeners(String binId) {
    // Skip if we already have listeners for this bin
    if (_activeListeners.containsKey('bin_$binId')) {
      return;
    }
    
    print("Setting up listeners for bin: $binId");
    
    // Set up listener for plastic level
    final plasticRef = FirebaseDatabase.instance
        .ref()
        .child('BIN')
        .child(binId)
        .child('plastic')
        .child('level');
    
    final plasticListener = plasticRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final level = event.snapshot.value?.toString() ?? "0";
        print("Plastic level update for bin $binId: $level");
        
        NotificationService().showBinLevelUpdate(
          binName: 'Bin $binId',
          material: 'Plastic',
          level: level,
        );
      }
    });
    
    _activeListeners['bin_${binId}_plastic'] = plasticListener;
    
    // Set up listener for metal level
    final metalRef = FirebaseDatabase.instance
        .ref()
        .child('BIN')
        .child(binId)
        .child('metal')
        .child('level');
    
    final metalListener = metalRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final level = event.snapshot.value?.toString() ?? "0";
        print("Metal level update for bin $binId: $level");
        
        NotificationService().showBinLevelUpdate(
          binName: 'Bin $binId',
          material: 'Metal',
          level: level,
        );
      }
    });
    
    _activeListeners['bin_${binId}_metal'] = metalListener;
  }
  
  Future<void> stopAllListeners() async {
    print("Stopping all database listeners");
    
    for (final subscription in _activeListeners.values) {
      try {
        await subscription.cancel();
      } catch (e) {
        print("Error cancelling subscription: $e");
      }
    }
    
    _activeListeners.clear();
  }
  
  // Call this when user logs out
  Future<void> cleanUp() async {
    await stopAllListeners();
  }
}

// Extension to make the code more readable
extension StreamSubscriptionExtension on StreamSubscription {
  Future<void> cancel() async {
    try {
      await this.cancel();
    } catch (e) {
      print("Error cancelling subscription: $e");
    }
  }
} 