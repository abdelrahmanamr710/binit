import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:binit/services/notification_service.dart';
import 'dart:async';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<StreamSubscription<DatabaseEvent>> _levelSubscriptions = [];
  final Map<String, Map<String, String>> _lastLevels = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Check if user is a bin owner
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!userDoc.exists || userDoc.data()?['userType'] != 'binOwner') {
        return;
      }

      // Listen to registered bins for this user
      final registeredBinsRef = FirebaseFirestore.instance.collection('registered_bins');
      final snapshot = await registeredBinsRef
          .where('owners', arrayContains: uid)
          .get();

      for (var doc in snapshot.docs) {
        final binId = doc.id;
        final data = doc.data();
        final binPath = data['bin_path'] ?? '/BIN/$binId';
        
        // Set up real-time listeners for level changes
        await _setupBinListener(binId, binPath);
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing NotificationManager: $e');
    }
  }

  Future<void> _setupBinListener(String binId, String binPath) async {
    // Initialize levels map for this bin
    _lastLevels[binId] = {
      'plastic': '',
      'metal': ''
    };

    // Create database references
    final plasticRef = FirebaseDatabase.instance.ref('$binPath/plastic/level');
    final metalRef = FirebaseDatabase.instance.ref('$binPath/metal/level');

    // Set up plastic level listener
    final plasticSubscription = plasticRef.onValue.listen((event) {
      final newLevel = event.snapshot.value?.toString() ?? '0%';
      _handleBinLevelUpdate(newLevel, binId, 'Plastic');
    });
    _levelSubscriptions.add(plasticSubscription);

    // Set up metal level listener
    final metalSubscription = metalRef.onValue.listen((event) {
      final newLevel = event.snapshot.value?.toString() ?? '0%';
      _handleBinLevelUpdate(newLevel, binId, 'Metal');
    });
    _levelSubscriptions.add(metalSubscription);
  }

  void _handleBinLevelUpdate(String newLevel, String binId, String material) async {
    // Get the current level for this material
    final currentLevel = _lastLevels[binId]?[material.toLowerCase()];

    // Only notify if level has changed
    if (newLevel != currentLevel) {
      final notificationId = 'bin_${binId}_${material.toLowerCase()}_${newLevel.replaceAll('%', '')}';
      
      final wasSent = await NotificationService().wasNotificationSent(notificationId);
      
      if (!wasSent) {
        await NotificationService().showBinLevelUpdate(
          binName: 'Bin $binId',
          material: material,
          level: newLevel,
          binId: binId,
        );
        
        await NotificationService().markNotificationAsSent(notificationId);
      }
      
      // Update the stored level
      if (_lastLevels[binId] != null) {
        _lastLevels[binId]![material.toLowerCase()] = newLevel;
      }
    }
  }

  void dispose() {
    for (var subscription in _levelSubscriptions) {
      subscription.cancel();
    }
    _levelSubscriptions.clear();
    _lastLevels.clear();
    _isInitialized = false;
  }
} 