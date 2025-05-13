import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_stock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:binit/services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';

class BinOwnerHomeScreen extends StatefulWidget {
  final int currentIndex;
  const BinOwnerHomeScreen({super.key, this.currentIndex = 1});

  @override
  _BinOwnerHomeScreenState createState() => _BinOwnerHomeScreenState();
}

class _BinOwnerHomeScreenState extends State<BinOwnerHomeScreen> {
  // Realtime Database references
  final DatabaseReference _plasticRef = FirebaseDatabase.instance.ref('/BIN/plastic/level');
  final DatabaseReference _metalRef = FirebaseDatabase.instance.ref('/BIN/metal/level');
  final DatabaseReference _plastic2Ref = FirebaseDatabase.instance.ref('/BIN/plastic2/level');
  final DatabaseReference _metal2Ref = FirebaseDatabase.instance.ref('/BIN/metal2/level');
  
  // Track seen offers
  final Set<String> _seenOffers = {};
  
  // Track last bin levels to avoid duplicate notifications
  String _lastPlasticLevel = '';
  String _lastMetalLevel = '';
  String _lastPlastic2Level = '';
  String _lastMetal2Level = '';
  
  // Helper function to handle bin level updates
  void _handleBinLevelUpdate(String newLevel, String lastLevel, String binName, String material) {
    if (newLevel != lastLevel && lastLevel.isNotEmpty) {
      NotificationService().showBinLevelUpdate(
        binName: binName,
        material: material,
        level: newLevel,
      );
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
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAcceptedOfferListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.black),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerProfile(user: user!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _sortBy = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Bin 1 Row
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: _plasticRef.onValue,
                          builder: (context, snapshot) {
                            String level = '...';
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              final val = snapshot.data!.snapshot.value;
                              final rawStr = val.toString().replaceAll('%', '');
                              final num lvl = num.tryParse(rawStr) ?? 0;
                              level = '$lvl%';
                              
                              // Only send notification if level has changed
                              if (level != _lastPlasticLevel && _lastPlasticLevel.isNotEmpty) {
                                NotificationService().showBinLevelUpdate(
                                  binName: 'Bin 1',
                                  material: 'Plastic',
                                  level: level,
                                );
                              }
                              // Update last known level
                              _lastPlasticLevel = level;
                            }
                            return _buildBinWithSingleButton(
                              'Bin 1 Plastic',
                              'assets/png/bin1.png',
                              'Plastic -  $level',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: _metalRef.onValue,
                          builder: (context, snapshot) {
                            String level = '...';
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              final val = snapshot.data!.snapshot.value;
                              final rawStr = val.toString().replaceAll('%', '');
                              final num lvl = num.tryParse(rawStr) ?? 0;
                              level = '$lvl%';
                              
                              _handleBinLevelUpdate(level, _lastMetalLevel, 'Bin 1', 'Metal');
                              _lastMetalLevel = level;
                            }
                            return _buildBinWithSingleButton(
                              'Bin 1 Metal',
                              'assets/png/bin2.png',
                              'Metal - $level',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bin 2 Row
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: _plastic2Ref.onValue,
                          builder: (context, snapshot) {
                            String level = '...';
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              final val = snapshot.data!.snapshot.value;
                              final rawStr = val.toString().replaceAll('%', '');
                              final num lvl = num.tryParse(rawStr) ?? 0;
                              level = '$lvl%';
                              
                              _handleBinLevelUpdate(level, _lastPlastic2Level, 'Bin 2', 'Plastic');
                              _lastPlastic2Level = level;
                            }
                            return _buildBinWithSingleButton(
                              'Bin 2 Plastic',
                              'assets/png/bin1.png',
                              'Plastic - $level',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StreamBuilder<DatabaseEvent>(
                          stream: _metal2Ref.onValue,
                          builder: (context, snapshot) {
                            String level = '...';
                            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                              final val = snapshot.data!.snapshot.value;
                              final rawStr = val.toString().replaceAll('%', '');
                              final num lvl = num.tryParse(rawStr) ?? 0;
                              level = '$lvl%';
                              
                              _handleBinLevelUpdate(level, _lastMetal2Level, 'Bin 2', 'Metal');
                              _lastMetal2Level = level;
                            }
                            return _buildBinWithSingleButton(
                              'Bin 2 Metal',
                              'assets/png/bin2.png',
                              'Metal - $level',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
