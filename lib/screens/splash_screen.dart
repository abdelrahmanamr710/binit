import 'package:flutter/material.dart';
import 'dart:async'; // Import the async library

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use Timer to delay navigation
    Timer(const Duration(seconds: 1), () {
      // Navigate to the LoginScreen after 1 second
      Navigator.of(context).pushReplacementNamed('/login'); // Use named route
    });
  }

  @override
  Widget build(BuildContext context) {
    //  the design of your splash screen ("Hi, Recyclers")
    return Scaffold(
      backgroundColor:
      const Color(0xFF85CB33), // Set the background color.  Change this to match your design.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add your logo or text here
            Text(
              'Hi, Recyclers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // You can add an image here if you have a logo
          ],
        ),
      ),
    );
  }
}