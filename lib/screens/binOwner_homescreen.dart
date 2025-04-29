import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart';
import 'package:binit/screens/binOwner_stock.dart';

class BinOwnerHomeScreen extends StatelessWidget {
  final String userName;
  final UserModel? user;
  final int currentIndex;
  const BinOwnerHomeScreen(
      {super.key, required this.userName, this.user, this.currentIndex = 1});

  Widget _buildBinWithSingleButton(
      String binLabel, String binImage, String binType) {
    return Column(
      children: [
        Text(
          '$binType:',
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Container(
          width: 150.0,
          height: 170.0,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(binImage),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          // Use SizedBox to control the width and center the button
          width: 100.0, // Match the width of the bin container
          child: ElevatedButton(
            onPressed: () {
              // Handle Empty button press
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2F7), // Light blue-grey
              foregroundColor: const Color(0xFF26A69A), // Teal
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: const Text('Empty'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color of the page
      appBar: AppBar(
        backgroundColor: Colors.white, // Ensure no background color from AppBar
        elevation: 0, // Remove shadow
        title: const Text(
          'HomePage / Company', // Title as in the image
          style: TextStyle(
            color: Colors.black, // Title color
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false, // Align title to the left if needed
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A524F), // Darker teal container color
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Welcome, $userName', // Dynamic company name
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // List of Metal Items
            Expanded(
              child: ListView(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 70.0), // Space between welcome and images
                      // Bin 1 Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bin 1:',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBinWithSingleButton('Bin 1 Plastic',
                                  'assets/png/bin1.png', 'Plastic'),
                              const SizedBox(width: 5), // Minimal space between bins
                              _buildBinWithSingleButton('Bin 1 Metal',
                                  'assets/png/bin2.png', 'Metal'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 60.0), // Space between rows
                      // Bin 2 Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bin 2:',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBinWithSingleButton('Bin 2 Plastic',
                                  'assets/png/bin1.png', 'Plastic'),
                              const SizedBox(width: 5), // Minimal space between bins
                              _buildBinWithSingleButton('Bin 2 Metal',
                                  'assets/png/bin2.png', 'Metal'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
                        builder: (context) => BinOwnerStockScreen(
                            userName: userName,
                            user: user,
                            currentIndex: 0),
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
                        builder: (context) => BinOwnerHomeScreen(
                            userName: userName,
                            user: user,
                            currentIndex: 1),
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
                        builder: (context) =>
                            BinOwnerProfile(user: user!),
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 1),
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

