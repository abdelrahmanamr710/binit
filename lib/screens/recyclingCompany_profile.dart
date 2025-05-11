import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:binit/screens/recyclingCompany_homescreen.dart';
import 'package:binit/screens/recyclingCompany_previousOrders.dart';

class RecyclingCompanyProfileScreen extends StatelessWidget {
  const RecyclingCompanyProfileScreen({super.key});

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
        backgroundColor: const Color(0xFF1A524F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RecyclingCompanyHomeScreen()),
            );
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 120.0, left: 20.0, right: 20.0, bottom: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120.0,
                    height: 120.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const CircleAvatar(
                      radius: 60.0,
                      backgroundImage: AssetImage('assets/png/profile.png'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30.0),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Failed to load profile'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = data['name'] ?? '';
                final email = data['email'] ?? '';
                final phone = data['phone']?.toString() ?? '';
                final taxId = data['taxId']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      initialValue: name,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Phone',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      initialValue: phone,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Tax ID',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      initialValue: taxId,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A524F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
                        ),
                        child: const Text('Sign Out', style: TextStyle(fontSize: 16.0)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
                      isSelected: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecyclingCompanyOrdersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecyclingCompanyHomeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      icon: Icons.person,
                      label: 'Profile',
                      isSelected: true,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
