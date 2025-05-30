import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BinOwnerNotificationsScreen extends StatefulWidget {
  const BinOwnerNotificationsScreen({Key? key}) : super(key: key);

  @override
  _BinOwnerNotificationsScreenState createState() => _BinOwnerNotificationsScreenState();
}

class _BinOwnerNotificationsScreenState extends State<BinOwnerNotificationsScreen> with WidgetsBindingObserver {
  String getNotificationMessage(String companyName, dynamic amount, String status) {
    switch (status) {
      case 'accepted':
        return '$companyName accepted your offer for $amount kg. Please wait.';
      case 'pending':
        return 'Your offer for $amount kg is pending with $companyName.';
      case 'rejected':
        return '$companyName declined your offer for $amount kg.';
      case 'completed':
        return 'Transaction completed with $companyName for $amount kg.';
      default:
        return 'Offer status updated for $amount kg with $companyName.';
    }
  }
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _notifications = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  String getFormattedTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else if (timestamp is String) {
      try {
        final DateTime date = DateTime.parse(timestamp.replaceAll(' UTC+3', ''));
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return timestamp.toString();
      }
    }
    
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }

    // Classify and sort notifications
    List<Map<String, dynamic>> sellOfferNotifications = _notifications
        .where((n) => [
              'offer_accepted',
              'offer_pending',
              'offer_rejected',
              'offer_completed',
              'offer_status',
              'offer_updated',
              'offer_created',
              'offer_cancelled',
            ].contains(n['type']))
        .toList();
    List<Map<String, dynamic>> binLevelNotifications = _notifications
        .where((n) => n['type'] == 'bin_level_update')
        .toList();

    int getTimestamp(Map<String, dynamic> n) {
      final ts = n['timestamp'];
      if (ts == null) return 0;
      if (ts is Timestamp) return ts.millisecondsSinceEpoch;
      if (ts is String) {
        try {
          return DateTime.parse(ts.replaceAll(' UTC+3', '')).millisecondsSinceEpoch;
        } catch (_) {}
      }
      return 0;
    }
    sellOfferNotifications.sort((a, b) => getTimestamp(b).compareTo(getTimestamp(a)));
    binLevelNotifications.sort((a, b) => getTimestamp(b).compareTo(getTimestamp(a)));

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Notifications',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF1A524F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView(
                children: [
                  if (sellOfferNotifications.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Sell Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...sellOfferNotifications.map((notification) => _buildNotificationTile(notification)).toList(),
                  ],
                  if (binLevelNotifications.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Bin Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...binLevelNotifications.map((notification) => _buildNotificationTile(notification)).toList(),
                  ],
                  if (sellOfferNotifications.isEmpty && binLevelNotifications.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Text(
                          'No notifications',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNotifications,
        backgroundColor: const Color(0xFF1A524F),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final notificationId = notification['id'];
    final notificationType = notification['type'];
    final isRead = notification['read'] ?? false;

    IconData iconData;
    switch (notificationType) {
      case 'offer_accepted':
        iconData = Icons.check_circle;
        break;
      case 'bin_level_update':
        iconData = Icons.delete;
        break;
      default:
        iconData = Icons.notifications;
    }

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notificationId),
      child: GestureDetector(
        onTap: () => _markAsRead(notificationId),
        child: Container(
          color: isRead ? Colors.transparent : Colors.green.withOpacity(0.2),
          child: ListTile(
            leading: Icon(
              iconData,
              color: Colors.black87,
            ),
            title: Text(
              notification['title'] ?? 'Notification',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['message'] ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  getFormattedTimestamp(notification['timestamp']),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: !isRead
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
