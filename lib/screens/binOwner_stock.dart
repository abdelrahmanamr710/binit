import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel
import 'package:binit/screens/binOwner_homescreen.dart'; // Import the HomeScreen
import 'package:binit/screens/binOwner_sell.dart'; // Import the SellScreen

class BinOwnerStockScreen extends StatelessWidget {
  final String userName;
  final UserModel? user; // Add the user parameter
  final int currentIndex;
  const BinOwnerStockScreen(
      {super.key, required this.userName, this.user, this.currentIndex = 0});

  Widget _buildStockItem(
      {required String type,
        required String weight,
        required int emptiedTimes,
        required String lastEmptiedDate,
        required BuildContext context}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Adding the icon based on the type
              Row(
                children: [
                  Icon(
                    type == 'Plastic' ? Icons.local_drink : Icons.build, // Plastic icon for "Plastic", Metal icon for "Metals"
                    color: Colors.green, // You can change the color as per your preference
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 25.0, // Adjust font size
                      fontWeight: FontWeight.w600, // Font weight
                      fontFamily: 'Roboto', // Font family
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Weight text added above "Emptied"
          Text(
            'kg: $weight',
            style: const TextStyle(
              fontSize: 23.0, // Adjust font size
              color: Colors.black,
              fontFamily: 'Roboto', // Font family
            ),
          ),
          const SizedBox(height: 8.0),
          // Emptied text
          Text(
            'Emptied : $emptiedTimes times',
            style: const TextStyle(
              fontSize: 23.0, // Adjust font size
              color: Colors.black87,
              fontFamily: 'Roboto', // Font family
            ),
          ),
          Text(
            'Last Emptied: $lastEmptiedDate',
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
              fontFamily: 'Roboto', // Font family
            ),
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        BinOwnerSell(userName: userName, user: user),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Sell'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color of the page
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A524F), // Teal-like background color
        elevation: 0, // Remove shadow
        automaticallyImplyLeading: false, // Disable back button
        title: const Text(
          'Current Stock', // Title of the page
          style: TextStyle(
            color: Colors.white, // Title color
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true, // Align title to the center
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Add padding to the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildStockItem(
              type: 'Plastic',
              weight: '50',
              emptiedTimes: 4,
              lastEmptiedDate: '12-12-2024',
              context: context,
            ),
            _buildStockItem(
              type: 'Metals',
              weight: '20',
              emptiedTimes: 2,
              lastEmptiedDate: '12-12-2024',
              context: context,
            ),
            // Add more stock items here as needed
          ],
        ),
      ),
      // Bottom Navigation Bar
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
              isSelected: currentIndex == 0,
              onTap: () {
                // No need to navigate if already on Stock screen
              },
            ),
            _buildNavBarItem(
              icon: Icons.home,
              label: 'Home',
              isSelected: currentIndex == 1,
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
              isSelected: currentIndex == 2,
              onTap: () {
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BinOwnerProfile(user: user!),
                    ),
                  );
                }
              },
            ),
          ],
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
