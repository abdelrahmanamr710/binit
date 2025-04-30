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
  const BinOwnerStockScreen(
      {super.key, required this.userName, this.user, this.currentIndex = 0});

  Widget _buildStockItem(
      {required String type,
        required int fullnessPercentage,
        required String weight,
        required int emptiedTimes,
        required String lastEmptiedDate,
        required BuildContext context}) {
    Color progressColor;
    if (fullnessPercentage <= 50) {
      progressColor = Colors.green;
    } else if (fullnessPercentage <= 80) {
      progressColor = Colors.yellow;
    } else {
      progressColor = Colors.red;
    }

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
              Text(
                type,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$weight',
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Stack(
            children: [
              Container(
                height: 20.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Container(
                height: 20.0,
                width: (MediaQuery.of(context).size.width - 32) *
                    (fullnessPercentage / 100),
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '$fullnessPercentage%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Emptied : $emptiedTimes times',
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
          Text(
            'Last Emptied: $lastEmptiedDate',
            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
              fullnessPercentage: 70,
              weight: '50kg',
              emptiedTimes: 4,
              lastEmptiedDate: '12-12-2024',
              context: context,
            ),
            _buildStockItem(
              type: 'Metals',
              fullnessPercentage: 45,
              weight: '20kg',
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
                  // No need to navigate if already on the Stock screen
                },
              ),
              _buildNavBarItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentIndex == 1,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) =>
                          BinOwnerHomeScreen(currentIndex: 1),
                    ),
                  );
                },
              ),
              _buildNavBarItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentIndex == 2,
                onTap: () {
                  if (user != null) {
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