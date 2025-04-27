import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel

class BinOwnerHomeScreen extends StatelessWidget {
  final String userName;
  final UserModel? user; // Add the user parameter
  final int currentIndex;
  const BinOwnerHomeScreen({super.key, required this.userName, this.user, this.currentIndex=1});

  @override
  Widget build(BuildContext context) {
    // Define the text style here
    const TextStyle welcomeTextStyle = TextStyle(
      fontSize: 21.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none,
    );

    // Directly set the width and height values
    double binWidth = 125.0;  // Change this number to adjust width
    double binHeight = 130.0; // Change this number to adjust height

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A524F), // Match the dark green color
                borderRadius: BorderRadius.circular(25),
              ),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    const TextSpan(text: 'Welcome, ', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white)),
                    TextSpan(text: userName, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8.0), // Add some space
            const Icon(Icons.notifications_none, color: Color(0xFF1A524F), size: 30),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 70.0, // Adjust top position after the app bar
            left: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.filter_list, color: Colors.grey),
                      SizedBox(width: 8.0),
                      Text(
                        'Sort By Fullness: Ascendingly',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80.0), // Space between welcome and images
                Column(
                  children: [
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
                          mainAxisAlignment: MainAxisAlignment.center, // Centering the bins
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Plastic:',  // Label for the bin on the left
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  width: 150.0, // Dynamic width for bin
                                  height: 170.0, // Dynamic height for bin
                                  child: Image.asset(
                                    'assets/png/bin1.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5), // Minimal space between bins
                            Column(
                              children: [
                                Text(
                                  'Metal:',  // Label for the second bin on the left
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  width: 150.0, // Dynamic width for bin
                                  height: 170.0, // Dynamic height for bin
                                  child: Image.asset(
                                    'assets/png/bin2.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 120.0), // Space between rows
                    // Row for Metal
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
                          mainAxisAlignment: MainAxisAlignment.center, // Centering the bins
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Plastic:',  // Label for the bin on the left
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  width: 150.0, // Dynamic width for bin
                                  height: 170.0, // Dynamic height for bin
                                  child: Image.asset(
                                    'assets/png/bin1.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5), // Minimal space between bins
                            Column(
                              children: [
                                Text(
                                  'Metal:',  // Label for the second bin on the left
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                Container(
                                  width: 150.0, // Dynamic width for bin
                                  height: 170.0, // Dynamic height for bin
                                  child: Image.asset(
                                    'assets/png/bin2.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex, // Use the currentIndex here
        onTap: (int index) {
          if (index == 2 && user != null) {
            Navigator.of(context).pushReplacement( // Use pushReplacement
              MaterialPageRoute(
                builder: (context) => BinOwnerProfile(user: user!),
              ),
            );
          } else if (index == 0) { // added else if
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BinOwnerHomeScreen(userName: userName, user: user, currentIndex: 0),
              ),
            );
          }
          else if (index == 1) {
            Navigator.of(context).pushReplacement( //use pushReplacement
              MaterialPageRoute(
                builder: (context) => BinOwnerHomeScreen(userName: userName, user: user, currentIndex: 1),
              ),
            );
          }
        },
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        elevation: 8.0,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
