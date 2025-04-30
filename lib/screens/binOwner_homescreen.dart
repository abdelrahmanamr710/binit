import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_stock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BinOwnerHomeScreen extends StatefulWidget {
  final int currentIndex;
  const BinOwnerHomeScreen({super.key, this.currentIndex = 1});

  @override
  _BinOwnerHomeScreenState createState() => _BinOwnerHomeScreenState();
}

class _BinOwnerHomeScreenState extends State<BinOwnerHomeScreen> {
  String userName = "";
  UserModel? user;
  bool _isLoading = true;
  String _sortBy = 'Fullness: Ascendingly'; // Default sorting option

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
          user = UserModel.fromJson(userData);
          userName = user!.name ?? "";
        } else {
          print('User data not found for ID: $userId');
          userName = "User Not Found";
        }
      } else {
        print('User not logged in.');
        userName = "Not Logged In";
      }
    } catch (e) {
      print("Error fetching user data: $e");
      userName = "Error";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildBinWithSingleButton(
      String binLabel, String binImage, String binType) {
    return Column(
      children: [
        Text(
          '$binType:',
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Container(
          width: 150.0,
          height: 170.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(binImage),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: 100.0,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2F7),
              foregroundColor: const Color(0xFF26A69A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: const Text('Empty'),
          ),
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
        title: const Text(''), // Empty title to allow custom layout
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding:
        const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A524F),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Text(
                      'Welcome, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.black),
                    onPressed: () {
                      // TODO: Implement notification functionality
                      print('Notifications pressed');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[200],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, color: Colors.grey),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.grey),
                    iconSize: 20,
                    elevation: 16,
                    style: const TextStyle(color: Colors.black87),
                    underline: Container(height: 0),
                    onChanged: (String? newValue) {
                      setState(() {
                        _sortBy = newValue!;
                        // TODO: Implement sorting logic based on _sortBy
                        print('Sorting by: $_sortBy');
                      });
                    },
                    items: <String>[
                      'Fullness: Ascendingly',
                      'Fullness: Descendingly',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 25.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bin 1:',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              _buildBinWithSingleButton(
                                  'Bin 1 Plastic',
                                  'assets/png/bin1.png',
                                  'Plastic'),
                              const SizedBox(width: 5),
                              _buildBinWithSingleButton(
                                  'Bin 1 Metal',
                                  'assets/png/bin2.png',
                                  'Metal'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bin 2:',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                            children: [
                              _buildBinWithSingleButton(
                                  'Bin 2 Plastic',
                                  'assets/png/bin1.png',
                                  'Plastic'),
                              const SizedBox(width: 5),
                              _buildBinWithSingleButton(
                                  'Bin 2 Metal',
                                  'assets/png/bin2.png',
                                  'Metal'),
                            ],
                          ),
                        ],
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
        decoration: BoxDecoration(
          color: const Color(0xFF1A524F),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavBarItem(
                icon: Icons.dashboard_rounded,
                label: 'Stock',
                isSelected: widget.currentIndex == 0,
                onTap: () {
                  if (widget.currentIndex != 0) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BinOwnerStockScreen(
                            userName: userName,
                            user: user,
                            currentIndex: 0),
                      ),
                    );
                  }
                },
              ),
              _buildNavBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: widget.currentIndex == 1,
                onTap: () {
                  if (widget.currentIndex != 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            BinOwnerHomeScreen(currentIndex: 1),
                      ),
                    );
                  }
                },
              ),
              _buildNavBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: widget.currentIndex == 2,
                onTap: () {
                  if (widget.currentIndex != 2 && user != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BinOwnerProfile(user: user!),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
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
    final Color color = isSelected ? Colors.white : Colors.grey[300]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}