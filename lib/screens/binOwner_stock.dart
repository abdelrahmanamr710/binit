import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel
import 'package:binit/screens/binOwner_homescreen.dart'; // Import the HomeScreen
import 'package:binit/screens/binOwner_sell.dart'; // Import the SellScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:binit/models/bin_model.dart';

class BinOwnerStockScreen extends StatefulWidget {
  final String userName;
  final UserModel? user;
  final int currentIndex;
  const BinOwnerStockScreen({
    super.key, 
    required this.userName, 
    this.user, 
    this.currentIndex = 0
  });

  @override
  State<BinOwnerStockScreen> createState() => _BinOwnerStockScreenState();
}

class _BinOwnerStockScreenState extends State<BinOwnerStockScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _showCapacityDialog(String materialType, double currentCapacity, String binId) async {
    final TextEditingController controller = TextEditingController(
      text: currentCapacity.toStringAsFixed(1)
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change ${materialType} Bin Capacity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Capacity (kg)',
                hintText: 'Enter new capacity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newCapacity = double.tryParse(controller.text);
                if (newCapacity == null || newCapacity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid capacity')),
                  );
                  return;
                }

                // Update capacity in Firestore
                final userId = _auth.currentUser?.uid;
                if (userId == null) return;

                // Get all bins for this user
                final bins = await _firestore.collection('registered_bins')
                  .where('owners', arrayContains: userId)
                  .get();
                for (var bin in bins.docs) {
                  await bin.reference.update({
                    materialType == 'Plastic'
                      ? 'plastic_max_capacity'
                      : 'metals_max_capacity': newCapacity,
                  });
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Capacity updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating capacity: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem({
    required String type,
    required String weight,
    required int emptiedTimes,
    required String lastEmptiedDate,
    required BuildContext context,
    required double currentCapacity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    type == 'Plastic' ? Icons.local_drink : Icons.build,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'change_capacity') {
                    _showCapacityDialog(type, currentCapacity, '');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_capacity',
                    child: Text('Change Bin Capacity'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'kg: $weight',
            style: const TextStyle(
              fontSize: 23.0,
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Emptied: $emptiedTimes times',
            style: const TextStyle(
              fontSize: 23.0,
              color: Colors.black87,
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            'Last Emptied: $lastEmptiedDate',
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        BinOwnerSell(userName: widget.userName, user: widget.user, initialMaterial: type == 'Plastic' ? 'Plastic' : 'Metal'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Sell'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Current Stock',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('registered_bins')
            .where('owners', arrayContains: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No registered bins found.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Calculate totals
          double totalPlasticWeight = 0;
          double totalMetalWeight = 0;
          int plasticEmptiedCount = 0;
          int metalEmptiedCount = 0;
          DateTime? lastPlasticEmptied;
          DateTime? lastMetalEmptied;
          double plasticCapacity = 50.0; // Default
          double metalCapacity = 30.0;   // Default

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Get capacities
            plasticCapacity = (data['plastic_max_capacity'] as num?)?.toDouble() ?? 50.0;
            metalCapacity = (data['metals_max_capacity'] as num?)?.toDouble() ?? 30.0;
            
            // Add weights
            totalPlasticWeight += (data['plastic_total_weight'] as num?)?.toDouble() ?? 0.0;
            totalMetalWeight += (data['metal_total_weight'] as num?)?.toDouble() ?? 0.0;
            
            // Add emptied counts
            plasticEmptiedCount += (data['plastic_emptied_count'] as int?) ?? 0;
            metalEmptiedCount += (data['metal_emptied_count'] as int?) ?? 0;
            
            // Update last emptied dates
            final plasticLastEmptied = (data['plastic_last_emptied'] as Timestamp?)?.toDate();
            final metalLastEmptied = (data['metal_last_emptied'] as Timestamp?)?.toDate();
            
            if (plasticLastEmptied != null && (lastPlasticEmptied == null || plasticLastEmptied.isAfter(lastPlasticEmptied))) {
              lastPlasticEmptied = plasticLastEmptied;
            }
            if (metalLastEmptied != null && (lastMetalEmptied == null || metalLastEmptied.isAfter(lastMetalEmptied))) {
              lastMetalEmptied = metalLastEmptied;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildStockItem(
                  type: 'Plastic',
                  weight: '${totalPlasticWeight.toStringAsFixed(1)} kg',
                  emptiedTimes: plasticEmptiedCount,
                  lastEmptiedDate: lastPlasticEmptied?.toString().split(' ')[0] ?? 'Never',
                  context: context,
                  currentCapacity: plasticCapacity,
                ),
                _buildStockItem(
                  type: 'Metals',
                  weight: '${totalMetalWeight.toStringAsFixed(1)} kg',
                  emptiedTimes: metalEmptiedCount,
                  lastEmptiedDate: lastMetalEmptied?.toString().split(' ')[0] ?? 'Never',
                  context: context,
                  currentCapacity: metalCapacity,
                ),
              ],
            ),
          );
        },
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
                // No need to navigate if already on Stock screen
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: widget.currentIndex == 1,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinOwnerHomeScreen(currentIndex: 1),
                  ),
                );
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: widget.currentIndex == 2,
              onTap: () {
                if (widget.user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerProfile(user: widget.user!),
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
