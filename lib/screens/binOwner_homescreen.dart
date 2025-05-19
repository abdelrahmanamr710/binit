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

class BinOwnerHomeScreen extends StatefulWidget {
  final int currentIndex;
  const BinOwnerHomeScreen({super.key, this.currentIndex = 1});

  @override
  _BinOwnerHomeScreenState createState() => _BinOwnerHomeScreenState();
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
      String newLevel, String binId, String material) {
    // Initialize levels map for this bin if not exists
    _lastLevels[binId] ??= {
      'plastic': '',
      'metal': ''
    };

    // Get the current level for this material
    final currentLevel = _lastLevels[binId]![material.toLowerCase()];

    // Only notify if level has changed
    if (newLevel != currentLevel) {
      NotificationService().showBinLevelUpdate(
        binName: 'Bin $binId',
        material: material,
        level: newLevel,
      );
      
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

  Widget _buildBinWithSingleButton(
      String title,
      String asset,
      String subtitle,
      ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE0F2F7),
            foregroundColor: const Color(0xFF26A69A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Empty'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          // Add Bin Registration Button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A524F)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  final codeController = TextEditingController();
                  return AlertDialog(
                    title: const Text('Register New Bin',
                        style: TextStyle(color: Color(0xFF1A524F))),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Bin Code',
                            hintText: 'e.g., ABC123',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Note: Each bin can be registered by up to 3 owners',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A524F),
                        ),
                        child: const Text('Register'),
                        onPressed: () async {
                          final code = codeController.text.trim();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a bin code')),
                            );
                            return;
                          }
                          
                          try {
                            // First check if bin exists in Realtime Database
                            final binRef = FirebaseDatabase.instance.ref('/BIN/$code');
                            final binSnapshot = await binRef.get();
                            
                            if (!binSnapshot.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('The bin doesn\'t exist')),
                              );
                              return;
                            }

                            final registeredBinsRef = FirebaseFirestore.instance.collection('registered_bins').doc(code);
                            final doc = await registeredBinsRef.get();
                            
                            if (!doc.exists) {
                              // Create new bin registration
                              await registeredBinsRef.set({
                                'owners': [FirebaseAuth.instance.currentUser?.uid],
                                'created_at': FieldValue.serverTimestamp(),
                                'bin_path': '/BIN/$code',
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bin registered successfully')),
                              );
                            } else {
                              final data = doc.data() as Map<String, dynamic>;
                              final owners = List<String>.from(data['owners'] ?? []);
                              
                              if (owners.contains(FirebaseAuth.instance.currentUser?.uid)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('You have already registered this bin')),
                                );
                                return;
                              }
                              
                              if (owners.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('This bin has reached the maximum number of owners')),
                                );
                                return;
                              }
                              
                              owners.add(FirebaseAuth.instance.currentUser?.uid ?? '');
                              await registeredBinsRef.update({'owners': owners});
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bin registered successfully')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error registering bin: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notification_add),
            tooltip: 'Test Notification',
            onPressed: _testNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/bin_owner_profile',
                arguments: user,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud, color: Colors.white),
            onPressed: () async {
              // Test the Cloud Function
              await FCMService().sendTestNotificationViaCloudFunction();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent via Cloud Function'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Test Cloud Function',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  children: snapshot.data!.docs.map((doc) {
                    final binId = doc.id;
                    final binRefs = _binRefs[binId] as Map<String, DatabaseReference>?;

                    if (binRefs == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bin ID: $binId',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<DatabaseEvent>(
                                  stream: binRefs['plastic']!.onValue,
                                  builder: (context, snapshot) {
                                    String level = '...';
                                    if (snapshot.hasData &&
                                        snapshot.data!.snapshot.value != null) {
                                      final val = snapshot.data!.snapshot.value;
                                      final rawStr = val.toString().replaceAll('%', '');
                                      final num lvl = num.tryParse(rawStr) ?? 0;
                                      level = '$lvl%';
                                    }
                                    return _buildBinWithSingleButton(
                                      'Plastic Bin',
                                      'assets/png/bin1.png',
                                      'Current Level: $level',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<DatabaseEvent>(
                                  stream: binRefs['metal']!.onValue,
                                  builder: (context, snapshot) {
                                    String level = '...';
                                    if (snapshot.hasData &&
                                        snapshot.data!.snapshot.value != null) {
                                      final val = snapshot.data!.snapshot.value;
                                      final rawStr = val.toString().replaceAll('%', '');
                                      final num lvl = num.tryParse(rawStr) ?? 0;
                                      level = '$lvl%';
                                    }
                                    return _buildBinWithSingleButton(
                                      'Metal Bin',
                                      'assets/png/bin2.png',
                                      'Current Level: $level',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerStockScreen(
                        userName: userName,
                        user: user,
                        currentIndex: 0,
                      ),
                    ),
                  );
                }
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: widget.currentIndex == 1,
              onTap: () {
                if (widget.currentIndex != 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerHomeScreen(currentIndex: 1),
                    ),
                  );
                }
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: widget.currentIndex == 2,
              onTap: () {
                if (widget.currentIndex != 2 && user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerProfile(user: user!),
                    ),
                  );
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
}

