import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel
import 'package:binit/screens/binOwner_homescreen.dart'; // Import the HomeScreen
import 'package:binit/screens/binOwner_sell.dart'; // Import the SellScreen

class BinOwnerStockScreen extends StatelessWidget {
  final String userName;
  final UserModel? user; // Add the user parameter
  final int currentIndex;
  const BinOwnerStockScreen({super.key, required this.userName, this.user, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color of the page
      appBar: AppBar(
        backgroundColor: Colors.white, // Ensure no background color from AppBar
        elevation: 0, // Remove shadow
        title: const Text(
          'Stock', // Title of the page
          style: TextStyle(
            color: Colors.black, // Title color
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false, // Align title to the left if needed
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding to the content
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                'Stock Screen Content', // Placeholder for the main content
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 20), // Space between text and button
            ElevatedButton(
              onPressed: () {
                // Navigate to the same screen (for demonstration)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BinOwnerSell(userName: userName, user: user,),
                  ),
                );
              },
              child: const Text(
                'Sell',
                style: TextStyle(
                  color: Colors.green, // Changed text color to green
                  fontWeight: FontWeight.bold, // Optional: Make the text bold
                  fontSize: 50
                ),
              ),

            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
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
            children: <Widget>[
              _buildNavBarItem(
                icon: Icons.dashboard_rounded,
                label: 'Stock',
                isSelected: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BinOwnerHomeScreen(currentIndex: 0),
                      ),
                    );
                  }
                },
              ),
              _buildNavBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BinOwnerHomeScreen(currentIndex: 1),
                      ),
                    );
                  }
                },
              ),
              _buildNavBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2 && user != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => BinOwnerProfile(user: user!),
                      ),
                    );
                  }
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

