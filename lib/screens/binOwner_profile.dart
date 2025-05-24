import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService.  Make sure this path is correct.
import 'package:binit/models/user_model.dart'; // Import UserModel.  Make sure this path is correct.
import 'package:binit/screens/binOwner_homescreen.dart'; // Import BinOwnerHomeScreen. Make sure this path is correct.
import 'package:binit/screens/binOwner_stock.dart';
import 'package:binit/screens/account_screen.dart';
import 'package:binit/screens/feedback_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:binit/screens/binOwner_orders.dart';
import 'package:binit/services/notification_service.dart';

class BinOwnerProfile extends StatefulWidget {
  final UserModel user;
  const BinOwnerProfile({super.key, required this.user});

  @override
  _BinOwnerProfileState createState() => _BinOwnerProfileState();
}

class _BinOwnerProfileState extends State<BinOwnerProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isEditing = false; // Track editing state
  String _errorMessage = '';
  int _currentIndex = 2; // Initialize the current index
  File? _imageFile;
  String? _selectedCategory;
  String? _selectedPriority;
  bool _isSubmitting = false;

  // Notification preferences
  bool _binLevelUpdates = true;
  bool _offerNotifications = true;
  bool _systemNotifications = true;

  final List<String> _feedbackCategories = [
    'Technical Issue',
    'Feature Request',
    'Bug Report',
    'General Feedback'
  ];

  final List<String> _priorityLevels = [
    'Low',
    'Medium',
    'High',
    'Critical'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with the user's current values.
    _nameController.text = widget.user.name ?? '';
    _descriptionController.text = '';
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        // Update user data.
        UserModel updatedUser = UserModel(
          uid: widget.user.uid, // Keep the original UID
          email: widget.user.email, //DO NOT CHANGE EMAIL
          name: _nameController.text.trim(),
          userType: widget.user.userType, // Keep the user type
        );

        await _authService.updateUserProfile(updatedUser); //  updateUserProfile method in AuthService

        // Provide feedback to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        _toggleEditing(); // Exit editing mode after successful update.

      } catch (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $_errorMessage')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isLoading = false;

  Future<void> _loadUserPreferences() async {
    try {
      final prefsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('preferences')
          .doc('notificationSettings')
          .get();

      if (prefsDoc.exists) {
        final data = prefsDoc.data()!;
        setState(() {
          _binLevelUpdates = data['binLevelUpdates'] ?? true;
          _offerNotifications = data['offerNotifications'] ?? true;
          _systemNotifications = data['systemNotifications'] ?? true;
        });
      } else {
        // Create default preferences if they don't exist
        await _updateNotificationPreferences();
      }
    } catch (e) {
      print('Error loading preferences: $e');
      // Set default values if there's an error
      setState(() {
        _binLevelUpdates = true;
        _offerNotifications = true;
        _systemNotifications = true;
      });
    }
  }

  Future<void> _updateNotificationPreferences() async {
    try {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('preferences')
          .doc('notificationSettings')
          .set({
        'binLevelUpdates': _binLevelUpdates,
        'offerNotifications': _offerNotifications,
        'systemNotifications': _systemNotifications,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local notification settings
      final notificationService = NotificationService();
      await notificationService.setBackgroundNotificationsEnabled(_systemNotifications);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification preferences updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('feedback_images')
          .child('${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and priority')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imageUrl = await _uploadImage();
      
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': widget.user.uid,
        'userName': widget.user.name,
        'userEmail': widget.user.email,
        'imageUrl': imageUrl,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _imageFile = null;
        _descriptionController.clear();
        _selectedCategory = null;
        _selectedPriority = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              try {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to sign out: $error')),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Account Section
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, color: Color(0xFF1A524F), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A524F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit, color: Color(0xFF1A524F), size: 22),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Orders Section
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1A524F), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A524F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, color: Color(0xFF1A524F), size: 22),
                      title: const Text('View Orders Status'),
                      trailing: const Icon(Icons.chevron_right, size: 22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BinOwnerOrders(userId: widget.user.uid ?? ""),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Notification Preferences Section
            _buildSection(
              title: 'Notification Preferences',
              icon: Icons.notifications,
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Bin Level Updates',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Get notified when your bins are getting full',
                          style: TextStyle(fontSize: 14,color: Colors.grey),


                        ),
                        value: _binLevelUpdates,
                        onChanged: (value) {
                          setState(() => _binLevelUpdates = value);
                          _updateNotificationPreferences();
                        },
                        activeColor: const Color(0xFF1A524F),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Offer Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Receive updates about recycling offers',
                          style: TextStyle(fontSize: 14,color: Colors.grey),
                        ),
                        value: _offerNotifications,
                        onChanged: (value) {
                          setState(() => _offerNotifications = value);
                          _updateNotificationPreferences();
                        },
                        activeColor: const Color(0xFF1A524F),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'System Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Important updates and announcements',
                          style: TextStyle(fontSize: 14,color: Colors.grey),
                        ),
                        value: _systemNotifications,
                        onChanged: (value) {
                          setState(() => _systemNotifications = value);
                          _updateNotificationPreferences();
                        },
                        activeColor: const Color(0xFF1A524F),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Support Section
            _buildSection(
              title: 'Support',
              icon: Icons.support_agent,
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Color(0xFF1A524F), size: 22),
                      title: const Text('Frequently Asked Questions'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pushNamed(context, '/faq'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent, color: Color(0xFF1A524F), size: 22),
                      title: const Text('Contact Support'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pushNamed(context, '/contact_support'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback, color: Color(0xFF1A524F), size: 22),
                      title: const Text('Submit Feedback'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A524F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(
              icon: Icons.dashboard,
              label: 'Stock',
              isSelected: _currentIndex == 0,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinOwnerStockScreen(
                      userName: widget.user.name ?? '',
                      user: widget.user,
                      currentIndex: 0,
                    ),
                  ),
                );
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: _currentIndex == 1,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinOwnerHomeScreen(currentIndex: 1),
                  ),
                );
              },
            ),
            _buildNavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: _currentIndex == 2,
              onTap: () {
                // No need to navigate if already on Profile screen
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1A524F)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A524F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (child != null)
          child
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: onTap,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              title: Text('View $title'),
            ),
          ),
      ],
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? Colors.white : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}