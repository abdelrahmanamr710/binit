import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:binit/screens/recyclingCompany_homescreen.dart'; // Import RecyclingCompanyHomeScreen

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
        backgroundColor: const Color(0xFF03342F),
        title: const Text('Profile'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Profile index
        onTap: (index) {
          switch (index) {
            case 0:

              
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecyclingCompanyHomeScreen(),
                ),
              );
              break;
            case 2:
            // Already on Profile
              break;
          }
        },
        backgroundColor: const Color(0xFF03342F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Previous Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Failed to load profile'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'N/A';
          final email = data['email'] ?? 'N/A';
          final phone = data['phone'] ?? 'N/A';
          final taxId = data['taxId'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFEFF5F4),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(fontSize: 36, color: Color(0xFF03342F)),
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileField(label: 'Name', value: name),
                const SizedBox(height: 16),
                _ProfileField(label: 'Email', value: email),
                const SizedBox(height: 16),
                _ProfileField(label: 'Phone', value: phone.toString()),
                const SizedBox(height: 16),
                // Tax ID is read-only
                TextFormField(
                  initialValue: taxId.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Tax ID',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03342F),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF03342F),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
