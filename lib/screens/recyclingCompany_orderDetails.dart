import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:binit/screens/waiting.dart'; // Import your Waiting screen
import 'package:firebase_auth/firebase_auth.dart';

class SellOfferDetailsScreen extends StatelessWidget {
  final String offerId;

  const SellOfferDetailsScreen({super.key, required this.offerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF03342F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('sell_offers').doc(offerId).get(),
        builder: (context, offerSnapshot) {
          if (offerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!offerSnapshot.hasData || !offerSnapshot.data!.exists) {
            return const Center(child: Text('Offer not found'));
          }
          final offer = offerSnapshot.data!.data() as Map<String, dynamic>;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(offer['userId']).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final ownerName = userData?['name'] ?? 'Unknown';

              // Format pickup date
              final rawDate = offer['pickupDate'];
              String formattedDate = 'N/A';
              if (rawDate != null) {
                if (rawDate is Timestamp) {
                  formattedDate = DateFormat('dd-MM-yyyy').format(rawDate.toDate());
                } else if (rawDate is String) {
                  try {
                    final parsed = DateTime.parse(rawDate);
                    formattedDate = DateFormat('dd-MM-yyyy').format(parsed);
                  } catch (_) {
                    formattedDate = rawDate;
                  }
                }
              }

              // Determine current status
              final status = offer['status'] as String? ?? 'pending';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF03342F), width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(icon: Icons.person, label: ownerName),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.location_city, label: 'City: ${offer['city']}'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.business, label: 'District: ${offer['district']}'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.scale, label: 'Amount in kg: ${offer['kilograms']} kg'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.attach_money, label: 'Price: \$${offer['price']}'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.location_on, label: 'Pickup address: ${offer['pickupAddress'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.calendar_today, label: 'Pick up date: $formattedDate'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.phone, label: 'Phone Number: ${offer['phoneNumber'] ?? 'N/A'}'),
                          const SizedBox(height: 8),
                          _DetailRow(icon: Icons.payment, label: 'Payment method: ${offer['paymentMethod'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Show Accept button only if pending
                    if (status == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF03342F),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            await FirebaseFirestore.instance
                                .collection('sell_offers')
                                .doc(offerId)
                                .update({
                              'status': 'accepted',
                              'companyId': currentUser?.uid,
                            });
                            // Navigate to Waiting screen after accepting
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Waiting(),
                              ),
                            );
                          },
                          child: const Text('Accept Offer'),
                        ),
                      )
                    else
                      Text(
                        status == 'accepted' ? 'Offer already accepted' : 'Offer $status',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF03342F)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
