import 'package:flutter/material.dart';
import 'package:binit/services/auth_service.dart'; // Import AuthService.  Make sure this path is correct.
import 'package:binit/models/user_model.dart'; // Import UserModel.  Make sure this path is correct.
import 'package:binit/screens/binOwner_homescreen.dart'; // Import BinOwnerHomeScreen. Make sure this path is correct.
import 'package:binit/screens/binOwner_stock.dart';
import 'package:binit/screens/binOwner_orders.dart';

class BinOwnerProfile extends StatefulWidget {
  final UserModel user;
  const BinOwnerProfile({super.key, required this.user});

  @override
  _BinOwnerProfileState createState() => _BinOwnerProfileState();
}

class _BinOwnerProfileState extends State<BinOwnerProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isEditing = false; // Track editing state
  String _errorMessage = '';
  int _currentIndex = 2; // Initialize the current index

  @override
  void initState() {
    super.initState();
    // Initialize the text controllers with the user's current values.
    _nameController.text = widget.user.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F), // Dark green background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
        padding: const EdgeInsets.all(20.0),
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
                      backgroundImage: AssetImage('assets/png/profile.png'), // Use the profile.png asset
                    ),
                  ),
                  if (_isEditing)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.camera_alt, size: 20.0, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30.0),
            Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Password',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              readOnly: true, // Password is not directly editable here
              onTap: () {

                ;
              },
            ),
            const SizedBox(height: 20.0),
            Text(
              'Date of Birth',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '28/01/2004', // Placeholder for date of birth
                    style: TextStyle(color: Colors.black87),
                  ),
                  if (_isEditing)
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                  if (!_isEditing)
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Country/Region',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Egypt', // Placeholder for country/region
                    style: TextStyle(color: Colors.black87),
                  ),
                  if (_isEditing)
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  if (!_isEditing)
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BinOwnerOrders(userId: widget.user.uid ?? ""),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A524F), // Dark green save button
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: const Text('Go to Bin Owner Orders', style: TextStyle(fontSize: 16.0)),
            ),
            const SizedBox(height: 30.0),
            if (_isEditing)
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A524F), // Dark green save button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Save changes', style: TextStyle(fontSize: 16.0)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A524F), // Background color of the nav bar
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Add some margin
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(
                icon: Icons.dashboard_rounded,
                label: 'Stock',
                isSelected: _currentIndex == 0,
                onTap: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BinOwnerStockScreen(userName: widget.user.name ?? '', user: widget.user, currentIndex: 0),
                    ),
                  );
                },
              ),
              _buildNavBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: _currentIndex == 1,
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => BinOwnerHomeScreen(currentIndex: 1),
                    ),
                  );
                },
              ),
              _buildNavBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _currentIndex == 2,
                onTap: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                  // Do nothing, remain on the same page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color color = isSelected ? Colors.white : Colors.grey[300]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}