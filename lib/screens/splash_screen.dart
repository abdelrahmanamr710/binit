import 'package:flutter/material.dart';
import 'dart:async'; // Import the async library
import 'package:binit/services/auth_service.dart';
import 'package:binit/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure Firebase is initialized
    Future.delayed(const Duration(seconds: 2), () {
      _checkCurrentUser();
    });
  }
  
  Future<void> _checkCurrentUser() async {
    try {
      print('SplashScreen: Starting user authentication check');
      final AuthService authService = AuthService();
      final UserModel? currentUser = await authService.getCurrentUser();
      
      if (!mounted) return; // Check if widget is still mounted
      
      if (currentUser != null) {
        print('SplashScreen: User found with type: ${currentUser.userType}');
        // User is already signed in, navigate to appropriate home screen
        if (currentUser.userType == 'binOwner') {
          print('SplashScreen: Navigating to bin owner home');
          Navigator.of(context).pushReplacementNamed('/bin_owner_home');
        } else if (currentUser.userType == 'recyclingCompany') {
          print('SplashScreen: Navigating to recycling company home');
          Navigator.of(context).pushReplacementNamed('/recycling_company_home');
        } else {
          print('SplashScreen: Unknown user type, redirecting to login');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        print('SplashScreen: No user found, redirecting to login');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (error) {
      print('SplashScreen Error: $error');
      print('Stack trace: ${StackTrace.current}');
      
      if (!mounted) return;
      
      // Navigate to login on error
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
                width: 550,
                height: 450,
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/png/bottomright.png',
                width: 550,
                height: 450,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Hi,',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Roboto Flex',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Recyclers',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'Roboto Flex',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
