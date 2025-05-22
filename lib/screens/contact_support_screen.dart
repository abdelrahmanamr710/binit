import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/permission_service.dart';

class ContactSupportScreen extends StatelessWidget {
  final PermissionService _permissionService = PermissionService();

  ContactSupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final hasPermission = await _permissionService.requestPhonePermission();
    if (!hasPermission) {
      // Show dialog to open settings
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Binit Support Request',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: const Color(0xFF1A524F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A524F),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A524F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFF1A524F)),
                      title: const Text('Call Support'),
                      subtitle: const Text('+2010301984'),
                      onTap: () => _makePhoneCall('+15551234567'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email, color: Color(0xFF1A524F)),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@binit.com'),
                      onTap: () => _sendEmail('support@binit.com'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Hours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A524F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.access_time, color: Color(0xFF1A524F)),
                      title: Text('Saturday-Thursday'),
                      subtitle: Text('9:00 AM - 9:00 PM'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.access_time, color: Color(0xFF1A524F)),
                      title: Text('Friday'),
                      subtitle: Text('1:00 PM - 8:00 PM'),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 