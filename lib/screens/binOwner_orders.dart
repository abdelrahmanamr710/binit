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

  void _sortDocuments() {
    if (mounted) {
      setState(() { // Keep the setState here
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
    switch (status) {
      case 'pending':
        return 1;
      case 'approved':
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
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              itemBuilder: (context, index) {
                var data =
                _documents[index].data() as Map<String, dynamic>;
                Timestamp? date = data['date'] as Timestamp?;
                String formattedDate = date != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(date.toDate())
                    : 'N/A';

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item: ${data['itemName'] ?? 'N/A'}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                  'Quantity: ${data['quantity'] ?? 'N/A'}'),
                              const SizedBox(height: 5),
                              Text('Date: $formattedDate'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Status: ${data['status'] ?? 'N/A'}',
                              style: TextStyle(
                                color: _getStatusColor(
                                    data['status'] ?? ''),
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
            ),
          ),
        ],
      ),
    );
  }
}

