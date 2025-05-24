import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BinOwnerOrders extends StatefulWidget {
  final String userId;
  const BinOwnerOrders({super.key, required this.userId});

@override
_BinOwnerOrdersState createState() => _BinOwnerOrdersState();
}

class _BinOwnerOrdersState extends State<BinOwnerOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _sellRequestsStream;
  String _sortOption = 'time';
  List<DocumentSnapshot> _documents = [];
  bool _isAscending = false;
  bool _isLoading = true; // Track loading state
  final List<StreamSubscription<QuerySnapshot>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _sellRequestsStream = _firestore
        .collection('sell_offers')
        .where('userId', isEqualTo: widget.userId)
        .snapshots();
    _subscribeToStream();
  }

  void _subscribeToStream() {
    final subscription = _sellRequestsStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Data has been loaded
          _documents = snapshot.docs;
          _sortDocuments();
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print("Stream error: $error");
        // Show error message to the user.  Use a SnackBar or Dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching data: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
    _subscriptions.add(subscription);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA726);  // Orange color
      case 'accepted':
        return const Color(0xFF66BB6A);  // Green color
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _sortDocuments() {
    if (mounted) {
      setState(() {
        if (_sortOption == 'time') {
          _documents.sort((a, b) {
            Timestamp? dateA = a['date'] as Timestamp?;
            Timestamp? dateB = b['date'] as Timestamp?;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          });
        } else if (_sortOption == 'status') {
          _documents.sort((a, b) {
            String statusA = a['status'] ?? '';
            String statusB = b['status'] ?? '';
            int orderA = _getStatusOrder(statusA);
            int orderB = _getStatusOrder(statusB);
            return _isAscending ? orderA.compareTo(orderB) : orderB.compareTo(orderA);
          });
        }
      });
    }
  }

  int _getStatusOrder(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 1;
      case 'accepted':
        return 2;
      case 'rejected':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F),
        centerTitle: true,
        title: const Text('Sell Requests', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A524F),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DropdownButton<String>(
                        value: _sortOption,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortOption = newValue;
                            });
                            _sortDocuments();
                          }
                        },
                        items: <String>['time', 'status']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(_isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward),
                        onPressed: () {
                          setState(() {
                            _isAscending = !_isAscending;
                          });
                          _sortDocuments();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _documents.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final timestamp = data['date'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format(timestamp.toDate())
                          : 'No date';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              data['material']?.toString().toLowerCase() == 'plastic' 
                                                ? Icons.local_drink 
                                                : Icons.build,
                                              color: const Color(0xFF1A524F),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${data['material'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Quantity: ${data['kilograms']?.toStringAsFixed(1) ?? 'N/A'} kg',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Price: ${data['price']?.toStringAsFixed(2) ?? 'N/A'} EGP/kg',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Date: $formattedDate',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            data['status'] ?? '',
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getStatusColor(
                                              data['status'] ?? '',
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${data['status']?.toString().toUpperCase() ?? 'N/A'}',
                                          style: TextStyle(
                                            color: _getStatusColor(
                                              data['status'] ?? '',
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Total: ${((data['kilograms'] ?? 0.0) * (data['price'] ?? 0.0)).toStringAsFixed(2)} EGP',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

