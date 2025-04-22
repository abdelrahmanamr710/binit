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
    // Delay navigation by 6 seconds
    Timer(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFFFF), // White background
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/png/leftcornergreen.png',
                width: 550, // Adjust width and height if needed
                height: 450,
                fit: BoxFit.contain, // Make sure it doesn't crop
                alignment: Alignment.topLeft,
              ),
            ),

            // Bottom Right Image
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/png/bottomright.png',
                width: 550, // adjust size as needed
                height: 450,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Hi,',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Roboto Flex',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Recyclers',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Roboto Flex',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
