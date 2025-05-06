import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:binit/screens/recyclingCompany_orderDetails.dart';
import 'package:binit/screens/recyclingCompany_profile.dart';
import 'package:binit/screens/recyclingCompany_previousOrders.dart';

class RecyclingCompanyHomeScreen extends StatefulWidget {
  const RecyclingCompanyHomeScreen({super.key});

  @override
  State<RecyclingCompanyHomeScreen> createState() =>
      _RecyclingCompanyHomeScreenState();
}

class _RecyclingCompanyHomeScreenState
    extends State<RecyclingCompanyHomeScreen> {
  int _selectedIndex = 1; // Initially select the Home screen

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RecyclingCompanyOrdersScreen(),
          ),
        );
        break;
      case 1:
      // Current screen, no navigation needed
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RecyclingCompanyProfileScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not signed in')),
      );
    }
    final uid = user.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Failed to load user data')),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? userData['email'] ?? 'Company';

        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF03342F),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _buildNavBarItem(
                      icon: Icons.receipt,
                      label: 'Previous Orders',
                      isSelected: _selectedIndex == 0,
                      onTap: () => _onItemTapped(0),
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onItemTapped(1),
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      icon: Icons.person,
                      label: 'Profile',
                      isSelected: _selectedIndex == 2,
                      onTap: () => _onItemTapped(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF03342F),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: 'Welcome, ',
                              style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w400),
                              children: [
                                TextSpan(
                                  text: userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.tealAccent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: Color(0xFF03342F),
                              size: 40.0,
                            ),
                            onPressed: () {
                              // TODO: Implement notification functionality
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('sell_offers')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final offers = snapshot.data?.docs ?? [];
                        if (offers.isEmpty) {
                          return const Center(child: Text("No pending sell offers."));
                        }

                        return ListView.builder(
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final doc = offers[index];
                            final offer = doc.data() as Map<String, dynamic>;
                            final offerId = doc.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF5F4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${offer['kilograms']} KG", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        Text("EGP ${offer['price']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03342F)))
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text("${offer['city']}, ${offer['district']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF03342F),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SellOfferDetailsScreen(offerId: offerId),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "View Details",
                                          style: TextStyle(color: Colors.white), // Changed text color to white
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color color = isSelected ? Colors.white : Colors.white54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
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
