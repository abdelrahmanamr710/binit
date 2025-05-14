import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BinOwnerNotificationsScreen extends StatelessWidget {
  const BinOwnerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Center( //Wrap the Text Widget with a Center Widget
          child: Text(
            'Notifications',
            style: TextStyle(color: Colors.white), // Set the color to white
          ),
        ),
        backgroundColor: const Color(0xFF1A524F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Set the color to white
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white), // Set the color to white
            tooltip: 'Clear all notifications',
            onPressed: () async {
              final query = await FirebaseFirestore.instance
                  .collection('sell_offers')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'accepted')
                  .get();
              for (var doc in query.docs) {
                await doc.reference.delete();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sell_offers')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docRef = docs[index];
              final offerData = docRef.data() as Map<String, dynamic>;
              final amount = offerData['kilograms'] ?? offerData['price'];
              final companyId = offerData['companyId'] as String?;
              return Dismissible(
                key: Key(docRef.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white), // Set the color to white
                ),
                onDismissed: (direction) async {
                  await docRef.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification cleared')),
                  );
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(companyId)
                      .get(),
                  builder: (context, userSnap) {
                    String companyName = 'Company';
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      companyName = 'Loading...';
                    } else if (userSnap.hasData && userSnap.data!.exists) {
                      final data = userSnap.data!.data() as Map<String, dynamic>;
                      companyName = data['name'] ?? data['email'] ?? companyName;
                    }
                    return ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: Colors.white, //Set the color to white
                      ),
                      title: Text(
                        '$companyName accepted your offer for $amount kg. Please wait.',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white), // Set the color to white
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
