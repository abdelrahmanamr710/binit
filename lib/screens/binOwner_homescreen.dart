import 'package:flutter/material.dart';
import 'package:binit/screens/binOwner_profile.dart';
import 'package:binit/models/user_model.dart'; // Import the UserModel


class BinOwnerHomeScreen extends StatelessWidget {
  final String userName;
  final UserModel? user; // Add the user parameter
  const BinOwnerHomeScreen({super.key, required this.userName, this.user});

  @override
  Widget build(BuildContext context) {
    // Define the text style here
    const TextStyle welcomeTextStyle = TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none, // Add this line to remove underline
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Owner Home'),
      ),
      body: Stack( // Changed to Stack to allow positioning
        children: [
          Positioned( // Added Positioned widget
            top: 16.0,  // Added top padding
            left: 16.0, // Added left padding
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color:Colors.green,
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
        onTap: (int index) {
          if (index == 2 && user != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BinOwnerProfile(user: user!),
              ),
            );
          }
        },
        //selectedItemColor: const Color(0xFFF79E1B),
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

