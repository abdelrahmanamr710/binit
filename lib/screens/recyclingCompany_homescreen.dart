import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:binit/screens/recyclingCompany_orderDetails.dart';
import 'package:binit/screens/recyclingCompany_profile.dart';
import 'package:binit/screens/recyclingCompany_previousOrders.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class RecyclingCompanyHomeScreen extends StatefulWidget {
  const RecyclingCompanyHomeScreen({super.key});

  @override
  State<RecyclingCompanyHomeScreen> createState() =>
      _RecyclingCompanyHomeScreenState();
}

class _RecyclingCompanyHomeScreenState
    extends State<RecyclingCompanyHomeScreen> {
  int _selectedIndex = 1;

  // Track offers to be dismissed
  Set<String> _dismissedOfferIds = {};
  Set<String> _pendingDismissIds = {};

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
        _navigateWithFadeThrough(const RecyclingCompanyOrdersScreen());
        break;
      case 1:
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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF03342F),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const SizedBox.shrink(),
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Color(0xFF03342F),
                statusBarIconBrightness: Brightness.light,
              ),
            ),
            body: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 32,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 24),
                    ),
                    Expanded(
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
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            !userSnapshot.data!.exists) {
          return Scaffold(

            body: Center(child: Text('Failed to load user data')),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? userData['email'] ?? 'Company';

        return Scaffold(
          appBar: AppBar(

            backgroundColor: const Color(0xFF03342F),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const SizedBox.shrink(),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF03342F),
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          backgroundColor: Colors.white,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF03342F),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  // You can add your specific content here below the header
 Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('sell_offers')
                          .where('status', isEqualTo: 'pending')
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

                        final offers = snapshot.data?.docs ?? [];
                        if (offers.isEmpty) {
                          return const Center(child: Text("No pending sell offers."));
                        }

                        return StatefulBuilder(
                          builder: (context, setStateSB) {
                            return ListView.builder(
                              itemCount: offers.length,
                              itemBuilder: (context, index) {
                                final doc = offers[index];
                                final offer = doc.data() as Map<String, dynamic>;
                                final offerId = doc.id;
                                if (_dismissedOfferIds.contains(offerId)) {
                                  return const SizedBox.shrink();
                                }
                                if (_pendingDismissIds.contains(offerId)) {
                                  // Trigger dismiss after build
                                  Future.delayed(Duration(milliseconds: 100), () {
  setStateSB(() {
    _dismissedOfferIds.add(offerId);
    _pendingDismissIds.remove(offerId);
  });
});
                                }
                                return Dismissible(
                                  key: Key(offerId + (_pendingDismissIds.contains(offerId) ? '_pending' : '')),
                                  direction: DismissDirection.startToEnd,
                                  onDismissed: (_) {
                                    setStateSB(() {
                                      _dismissedOfferIds.add(offerId);
                                      _pendingDismissIds.remove(offerId);
                                    });
                                  },
                                  child: _buildOfferCard(offer, offerId, context, setStateSB),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
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

  // Helper to build the offer card
  Widget _buildOfferCard(Map<String, dynamic> offer, String offerId, BuildContext context, void Function(void Function()) setStateSB) {
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
                onPressed: () async {
                  final dismissedOfferId = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellOfferDetailsScreen(offerId: offerId),
                    ),
                  );
                  if (dismissedOfferId != null && dismissedOfferId == offerId) {
                    setStateSB(() {
                      _pendingDismissIds.add(offerId);
                    });
                  }
                },
                child: const Text(
                  "View Details",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    ).animate()
      .fade(duration: 400.ms, delay: 0.ms)
      .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: 0.ms);
  }
}
