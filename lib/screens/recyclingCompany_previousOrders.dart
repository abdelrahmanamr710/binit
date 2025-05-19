import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:binit/screens/recyclingCompany_homescreen.dart';
import 'package:binit/screens/recyclingCompany_profile.dart';
import 'package:binit/screens/recyclingCompany_orderDetails.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecyclingCompanyOrdersScreen extends StatefulWidget {
  const RecyclingCompanyOrdersScreen({super.key});

  @override
  State<RecyclingCompanyOrdersScreen> createState() =>
      _RecyclingCompanyOrdersScreenState();
}

class _RecyclingCompanyOrdersScreenState
    extends State<RecyclingCompanyOrdersScreen> {
  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        _navigateWithFadeThrough(const RecyclingCompanyHomeScreen());
        break;
      case 2:
        _navigateWithFadeThrough(const RecyclingCompanyProfileScreen());
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF03342F),
        title: const Text(
          'Previous Orders',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF03342F),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth / 15,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sell_offers')
                .where('companyId', isEqualTo: uid)
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading orders: ${snapshot.error}'));
              }

              final orders = snapshot.data?.docs ?? [];
              if (orders.isEmpty) {
                return const Center(child: Text('No previous orders.'));
              }

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId = doc.id;

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
                              Text(
                                "${data['kilograms']} KG",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "EGP ${data['price']}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF03342F)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${data['city']}, ${data['district']}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF03342F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SellOfferDetailsScreen(
                                        offerId: orderId),
                                  ),
                                );
                              },
                              child: const Text(
                                "View Details",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fade(duration: 400.ms, delay: (index * 80).ms)
                    .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (index * 80).ms);
                },
              );
            },
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
    final Color color = isSelected ? Colors.white : Colors.white54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}