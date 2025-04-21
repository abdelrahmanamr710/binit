// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen
//import 'screens/welcome_screen.dart'; // Remove WelcomeScreen import
import 'screens/login_screen.dart'; // Import LoginScreen - Ensure this import is correct
import 'models/user_model.dart'; //Import user model
import 'services/auth_service.dart';
import 'screens/home_screen.dart'; // Import the new HomeScreen
import 'screens/signup_as_screen.dart';
import 'screens/bin_owner_signup_screen.dart';
import 'screens/signup_screen.dart'; // Ensure this import is correct
import 'src/pigeon.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BinItApp());
}

class BinItApp extends StatelessWidget {
  const BinItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bin-It',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(), // Use SplashScreen as the initial screen.  This is the change.
      routes: { // Define routes for navigation
        '/login': (context) => const LoginScreen(),
        '/signup_as': (context) => const SignUpAs(),
        '/bin_owner_signup': (context) => const BinOwnerSignupScreen(),
        '/recycling_company_signup': (context) => const RecyclingCompanySignupScreen(), // reusing the signup screen
      },
    );
  }
}