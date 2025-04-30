import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class BinOwnerOrders extends StatefulWidget {
  final String userId; // Add userId as a parameter
  const BinOwnerOrders({super.key, required this.userId});

@override
_BinOwnerOrdersState createState() => _BinOwnerOrdersState();
}

class _BinOwnerOrdersState extends State<BinOwnerOrders> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of sell requests for the current user
  late Stream<QuerySnapshot> _sellRequestsStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream in initState to use the userId
    _sellRequestsStream = _firestore
        .collection('sell_offers')
        .where('userId', isEqualTo: widget.userId) // Filter by the user ID
        .snapshots();
  }

  // Function to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F), // Green app bar
        title: const Text('Sell Requests', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Go back
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sellRequestsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A524F),
              ), // Green loading indicator
            );
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No sell requests yet.', style: TextStyle(fontSize: 16)),
            );
          }

          // Convert the snapshot data into a list of documents
          List<DocumentSnapshot> documents = snapshot.data!.docs;

          // Sort the documents by date, newest first
          documents.sort((a, b) {
            // Assuming you have a 'date' field in your Firestore document
            Timestamp? dateA = a['date'] as Timestamp?;
            Timestamp? dateB = b['date'] as Timestamp?;

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA); // Newest first
          });

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var data = documents[index].data() as Map<String, dynamic>;
              // Format the date using intl package
              Timestamp? date = data['date'] as Timestamp?;
              String formattedDate = date != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(date.toDate())
                  : 'N/A'; // Handle null date

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item: ${data['itemName'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                              overflow: TextOverflow
                                  .ellipsis, // Handle long text
                            ),
                            const SizedBox(height: 5),
                            Text('Quantity: ${data['quantity'] ?? 'N/A'}'),
                            const SizedBox(height: 5),
                            Text('Date: $formattedDate'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status: ${data['status'] ?? 'N/A'}',
                            style: TextStyle(
                              color: _getStatusColor(
                                  data['status'] ??
                                      ''), // Get status color
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

