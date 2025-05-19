import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_stock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:binit/services/notification_service.dart';
import 'package:binit/services/fcm_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BinOwnerHomeScreen extends StatefulWidget {
  final int currentIndex;
  const BinOwnerHomeScreen({super.key, this.currentIndex = 1});

  @override
  _BinOwnerHomeScreenState createState() => _BinOwnerHomeScreenState();
}

// Helper class for bin refs
class _BinWithLevels {
  final String binId;
  final DatabaseReference plasticRef;
  final DatabaseReference metalRef;
  _BinWithLevels({required this.binId, required this.plasticRef, required this.metalRef});
}

// Helper class for bin with levels
class _BinWithLevelsWithLevel {
  final String binId;
  final double plasticLevel;
  final double metalLevel;
  _BinWithLevelsWithLevel({required this.binId, required this.plasticLevel, required this.metalLevel});
}

class _BinOwnerHomeScreenState extends State<BinOwnerHomeScreen> {
  // Firestore reference for registered bins
  final CollectionReference _registeredBinsRef =
      FirebaseFirestore.instance.collection('registered_bins');

  // Map to store database references for registered bins
  final Map<String, Map<String, DatabaseReference>> _binRefs = <String, Map<String, DatabaseReference>>{};
  
  // Store stream subscriptions to properly dispose them
  final List<StreamSubscription<DatabaseEvent>> _levelSubscriptions = [];
  final List<StreamSubscription<QuerySnapshot>> _firestoreSubscriptions = [];

  // Track seen offers
  final Set<String> _seenOffers = {};

  // Track last bin levels to avoid duplicate notifications
  final Map<String, Map<String, String>> _lastLevels = {};

  // Helper function to handle bin level update with debouncing
  void _handleBinLevelUpdate(
      String newLevel, String binId, String material) async {
    // Initialize levels map for this bin if not exists
    _lastLevels[binId] ??= {
      'plastic': '',
      'metal': ''
    };

    // Get the current level for this material
    final currentLevel = _lastLevels[binId]![material.toLowerCase()];

    // Only notify if level has changed
    if (newLevel != currentLevel) {
      // Create a unique notification ID that includes the bin ID, material, and level
      final notificationId = 'bin_${binId}_${material.toLowerCase()}_${newLevel.replaceAll('%', '')}';
      
      // Check if this notification was already sent
      final wasSent = await NotificationService().wasNotificationSent(notificationId);
      
      if (!wasSent) {
        await NotificationService().showBinLevelUpdate(
          binName: 'Bin $binId',
          material: material,
          level: newLevel,
          binId: binId,
        );
        
        // Mark this notification as sent
        await NotificationService().markNotificationAsSent(notificationId);
      }
      
      // Update the stored level without triggering setState
      _lastLevels[binId]![material.toLowerCase()] = newLevel;
    }
  }

  String userName = '';
  UserModel? user;
  bool _isLoading = true;
  String _sortBy = 'Fullness: Ascendingly';

  @override
  void initState() {
    super.initState();
    _startAcceptedOfferListener();
    _fetchUserData();
    _setupRegisteredBins();
  }
  
  @override
  void dispose() {
    // Cancel all subscriptions to prevent memory leaks
    for (var subscription in _levelSubscriptions) {
      subscription.cancel();
    }
    for (var subscription in _firestoreSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _setupRegisteredBins() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Listen to registered bins for this user
      final subscription = _registeredBinsRef
          .where('owners', arrayContains: uid)
          .snapshots()
          .listen((snapshot) {
        if (!mounted) return;
        
        // Cancel existing subscriptions before creating new ones
        for (var subscription in _levelSubscriptions) {
          subscription.cancel();
        }
        _levelSubscriptions.clear();
        
        final Map<String, Map<String, DatabaseReference>> newBinRefs = {};
        
        for (var doc in snapshot.docs) {
          final binId = doc.id;
          final data = doc.data() as Map<String, dynamic>;
          final binPath = data['bin_path'] ?? '/BIN/$binId';
          
          // Create database reference for this bin
          final plasticRef = FirebaseDatabase.instance.ref('$binPath/plastic/level');
          final metalRef = FirebaseDatabase.instance.ref('$binPath/metal/level');

          // Set up real-time listeners for level changes with optimized approach
          final plasticSubscription = plasticRef.onValue.listen((event) {
            if (!mounted) return;
            final newLevel = event.snapshot.value?.toString() ?? '0%';
            _handleBinLevelUpdate(newLevel, binId, 'Plastic');
          });
          _levelSubscriptions.add(plasticSubscription);

          final metalSubscription = metalRef.onValue.listen((event) {
            if (!mounted) return;
            final newLevel = event.snapshot.value?.toString() ?? '0%';
            _handleBinLevelUpdate(newLevel, binId, 'Metal');
          });
          _levelSubscriptions.add(metalSubscription);

          newBinRefs[binId] = <String, DatabaseReference>{
            'plastic': plasticRef,
            'metal': metalRef
          };
        }
        
        setState(() {
          _binRefs.clear();
          _binRefs.addAll(newBinRefs);
          _isLoading = false;
        });
      });
      
      _firestoreSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error setting up registered bins: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Use cache-first approach for better performance
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(GetOptions(source: Source.cache))
            .catchError((_) => 
              // Fallback to server if cache fails
              FirebaseFirestore.instance.collection('users').doc(uid).get()
            );
            
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          user = UserModel.fromJson(data);
          userName = data['name'] ?? '';
        } else {
          userName = 'User Not Found';
        }
      } else {
        userName = 'Not Logged In';
      }
    } catch (_) {
      userName = 'Error';
    }
  }

  void _startAcceptedOfferListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final subscription = FirebaseFirestore.instance
        .collection('sell_offers')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        if (!_seenOffers.add(doc.id)) continue;
        final data = doc.data() as Map<String, dynamic>;
        NotificationService().showOfferAccepted(
          company: data['companyName'] as String? ?? 'Company',
          kilos: data['kilograms'] as num? ?? 0,
        );
      }
    });
    
    _firestoreSubscriptions.add(subscription);
  }

  // Test notifications function
  Future<void> _testNotifications() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending test notification...')),
      );
      
      await FCMService().sendTestNotification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleEmptyBin(String binId, String materialType) async {
    // Get correct path for the bin level
    final levelPath = materialType == 'plastic'
        ? 'plastic/level'
        : 'metal/level';
    final binRef = FirebaseDatabase.instance.ref('BIN/$binId/$levelPath');
    final snapshot = await binRef.get();
    if (!snapshot.exists) return;
    
    final currentLevel = (snapshot.value is int)
        ? snapshot.value as int
        : int.tryParse(snapshot.value.toString()) ?? 0;
    
    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Bin'),
        content: Text('Current bin level is $currentLevel%. Are you sure you want to empty this bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Empty'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current bin capacity
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final binDoc = await FirebaseFirestore.instance
          .collection('registered_bins')
          .doc(binId)
          .get();

      if (!binDoc.exists) return;
      
      final binData = binDoc.data()!;
      final maxCapacity = materialType == 'plastic' 
          ? (binData['plastic_max_capacity'] as num?)?.toDouble() ?? 50.0
          : (binData['metals_max_capacity'] as num?)?.toDouble() ?? 30.0;

      // Calculate weight based on current level
      final weight = (currentLevel / 100) * maxCapacity;

      // Store previous Firestore values for undo (all relevant fields for the material)
      Map<String, dynamic> prevMaterialFields = {};
      if (materialType == 'plastic') {
        for (final key in binData.keys) {
          if (key.startsWith('plastic_')) {
            prevMaterialFields[key] = binData[key];
          }
        }
      } else {
        for (final key in binData.keys) {
          if (key.startsWith('metal_')) {
            prevMaterialFields[key] = binData[key];
          }
        }
      }

      // Update Firestore
      await binDoc.reference.update({
        '${materialType == 'plastic' ? 'plastic_total_weight' : 'metal_total_weight'}': FieldValue.increment(weight),
        '${materialType == 'plastic' ? 'plastic_emptied_count' : 'metal_emptied_count'}': FieldValue.increment(1),
        '${materialType == 'plastic' ? 'plastic_last_emptied' : 'metal_last_emptied'}': FieldValue.serverTimestamp(),
      });

      // Reset bin level to 0 at the correct path
      await binRef.set(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bin emptied successfully')),
        );
      }

      // --- Undo logic: listen for 5 seconds ---
      bool undone = false;
      StreamSubscription<DatabaseEvent>? sub;
      sub = binRef.onValue.listen((event) async {
        final value = event.snapshot.value;
        int newLevel = (value is int)
            ? value
            : int.tryParse(value.toString().replaceAll('%', '')) ?? 0;
        if (!undone && newLevel == currentLevel && newLevel != 0) {
          undone = true;
          // Undo Firestore changes: restore all previous fields for the material
          await binDoc.reference.update(prevMaterialFields);
          // Restore bin level
          await binRef.set(currentLevel);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The bin wasn\'t emptied and the levels returned to previous state')),
            );
          }
          await sub?.cancel();
        }
      });
      await Future.delayed(const Duration(seconds: 5));
      await sub?.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error emptying bin: $e')),
        );
      }
    }
  }

  Widget _buildBinCard(String binId, String materialType) {
    String imagePath = materialType == 'plastic'
        ? 'assets/png/bin1.png'
        : 'assets/png/bin2.png';
    final levelPath = materialType == 'plastic'
        ? 'plastic/level'
        : 'metal/level';
    final binRef = FirebaseDatabase.instance.ref('BIN/$binId/$levelPath');
    return StreamBuilder<DatabaseEvent>(
      stream: binRef.onValue,
      builder: (context, snapshot) {
        int level = 0;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final rawValue = snapshot.data!.snapshot.value;
          level = (rawValue is int)
              ? rawValue
              : int.tryParse(rawValue.toString().replaceAll('%', '')) ?? 0;
        }
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Material type (title)
              Center(
                child: Text(
                  materialType == 'plastic' ? 'Plastic Bin' : 'Metal Bin',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8.0),
              // 2. Bin PNG
              SizedBox(
                width: double.infinity,
                height: 110,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8.0),
              // 3. Percentage
              Center(
                child: Text(
                  'Level: $level%',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: level > 75 ? Colors.red : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8.0),
              // 4. Fill bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: LinearProgressIndicator(
                  value: level / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    level > 75 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Center(
                child: ElevatedButton(
                  onPressed: () => _handleEmptyBin(binId, materialType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: const Text('Empty'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const SizedBox.shrink(),
        actions: [
          // Removed IconButton widgets for add_circle_outline, notification_add, notifications, and person
        ],
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: List.generate(2, (i) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A524F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Welcome, $userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Notification Button on the same line as Welcome
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.black),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, color: Colors.grey),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox.shrink(),
                    items: [
                      'Fullness: Ascendingly',
                      'Fullness: Descendingly',
                    ]
                        .map((e) => DropdownMenuItem(
                        value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _sortBy = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _registeredBinsRef
                  .where('owners', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No registered bins found.\nUse the + button to register a bin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: _getSortedBins(snapshot.data!.docs),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A524F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(
              icon: Icons.dashboard,
              label: 'Stock',
              isSelected: widget.currentIndex == 0,
              onTap: () {
                if (widget.currentIndex != 0) {
                  _navigateWithFadeThrough(BinOwnerStockScreen(
                    userName: userName,
                    user: user,
                    currentIndex: 0,
                  ));
                }
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: widget.currentIndex == 1,
              onTap: () {
                if (widget.currentIndex != 1) {
                  _navigateWithFadeThrough(BinOwnerHomeScreen(currentIndex: 1));
                }
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: widget.currentIndex == 2,
              onTap: () {
                if (widget.currentIndex != 2 && user != null) {
                  _navigateWithFadeThrough(BinOwnerProfile(user: user!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? Colors.white : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // Add this method to sort and build bins
  List<Widget> _getSortedBins(List<QueryDocumentSnapshot> docs) {
    // Gather bin fullness data
    List<_BinWithLevels> bins = [];
    for (var doc in docs) {
      final binId = doc.id;
      final binRefs = _binRefs[binId] as Map<String, DatabaseReference>?;
      if (binRefs == null) continue;
      bins.add(_BinWithLevels(
        binId: binId,
        plasticRef: binRefs['plastic']!,
        metalRef: binRefs['metal']!,
      ));
    }
    return [
      FutureBuilder<List<_BinWithLevelsWithLevel>>(
        future: _fetchLevelsForBins(bins),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          var binList = snapshot.data!;
          // Sort by average fullness
          binList.sort((a, b) {
            final aAvg = (a.plasticLevel + a.metalLevel) / 2;
            final bAvg = (b.plasticLevel + b.metalLevel) / 2;
            if (_sortBy == 'Fullness: Ascendingly') {
              return aAvg.compareTo(bAvg);
            } else {
              return bAvg.compareTo(aAvg);
            }
          });
          return Column(
            children: binList.asMap().entries.map((entry) {
              final i = entry.key;
              final bin = entry.value;
              // Determine order of sub-bins
              final isPlasticFirst = (_sortBy == 'Fullness: Ascendingly' && bin.plasticLevel <= bin.metalLevel) ||
                  (_sortBy == 'Fullness: Descendingly' && bin.plasticLevel > bin.metalLevel);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bin ID: ${bin.binId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: isPlasticFirst
                          ? [
                              Expanded(
                                child: _buildBinCard(bin.binId, 'plastic'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBinCard(bin.binId, 'metal'),
                              ),
                            ]
                          : [
                              Expanded(
                                child: _buildBinCard(bin.binId, 'metal'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBinCard(bin.binId, 'plastic'),
                              ),
                            ],
                    ),
                  ],
                ),
              ).animate()
                .fade(duration: 400.ms, delay: (i * 80).ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (i * 80).ms);
            }).toList(),
          );
        },
      ),
    ];
  }

  // Fetch levels for all bins
  Future<List<_BinWithLevelsWithLevel>> _fetchLevelsForBins(List<_BinWithLevels> bins) async {
    List<_BinWithLevelsWithLevel> result = [];
    for (var bin in bins) {
      final plasticSnap = await bin.plasticRef.get();
      final metalSnap = await bin.metalRef.get();
      double plasticLevel = 0;
      double metalLevel = 0;
      if (plasticSnap.value != null) {
        plasticLevel = double.tryParse(plasticSnap.value.toString().replaceAll('%', '')) ?? 0;
      }
      if (metalSnap.value != null) {
        metalLevel = double.tryParse(metalSnap.value.toString().replaceAll('%', '')) ?? 0;
      }
      result.add(_BinWithLevelsWithLevel(
        binId: bin.binId,
        plasticLevel: plasticLevel,
        metalLevel: metalLevel,
      ));
    }
    return result;
  }

  void _navigateWithFadeThrough(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: page,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

