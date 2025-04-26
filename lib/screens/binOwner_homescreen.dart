import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel

class BinOwnerHomeScreen extends StatelessWidget {
  final String userName;
  final UserModel? user;
  final int currentIndex; // Add this parameter
  const BinOwnerHomeScreen({super.key, required this.userName, this.user, this.currentIndex = 1}); // Default to 1 (Home)

  @override
  Widget build(BuildContext context) {
    // Define the text style here
    const TextStyle welcomeTextStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Owner Home'),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 16.0,
            left: 16.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(25),
              ),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    const TextSpan(text: 'Welcome, ', style: welcomeTextStyle),
                    TextSpan(text: userName, style: welcomeTextStyle),
                  ],
                ),
              ),
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

