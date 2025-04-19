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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily:
        'Roboto', // Set the default font family here.  Make sure the font is added in the pubspec.yaml and the font file exists.
        textTheme: const TextTheme(
          // You can also define specific styles for different text elements here if needed.  This is optional.
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          displayLarge: TextStyle(fontFamily: 'Roboto'),
          displayMedium: TextStyle(fontFamily: 'Roboto'),
          displaySmall: TextStyle(fontFamily: 'Roboto'),
          headlineLarge: TextStyle(fontFamily: 'Roboto'),
          headlineMedium: TextStyle(fontFamily: 'Roboto'),
          headlineSmall: TextStyle(fontFamily: 'Roboto'),
          labelLarge: TextStyle(fontFamily: 'Roboto'),
          labelMedium: TextStyle(fontFamily: 'Roboto'),
          labelSmall: TextStyle(fontFamily: 'Roboto'),
          titleLarge: TextStyle(fontFamily: 'Roboto'),
          titleMedium: TextStyle(fontFamily: 'Roboto'),
          titleSmall: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily:
        'Roboto', // Set the default font family here.   Make sure the font is added in the pubspec.yaml and the font file exists.

        textTheme: const TextTheme(
          // You can also define specific styles for different text elements here if needed.   This is optional.
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          displayLarge: TextStyle(fontFamily: 'Roboto'),
          displayMedium: TextStyle(fontFamily: 'Roboto'),
          displaySmall: TextStyle(fontFamily: 'Roboto'),
          headlineLarge: TextStyle(fontFamily: 'Roboto'),
          headlineMedium: TextStyle(fontFamily: 'Roboto'),
          headlineSmall: TextStyle(fontFamily: 'Roboto'),
          labelLarge: TextStyle(fontFamily: 'Roboto'),
          labelMedium: TextStyle(fontFamily: 'Roboto'),
          labelSmall: TextStyle(fontFamily: 'Roboto'),
          titleLarge: TextStyle(fontFamily: 'Roboto'),
          titleMedium: TextStyle(fontFamily: 'Roboto'),
          titleSmall: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup_as': (context) => const SignupAsScreen(),
        '/bin_owner_signup': (context) => const BinOwnerSignupScreen(),
        '/recycling_company_signup': (context) =>
        const SignupScreen(), // reusing the signup screen
      },
    );
  }
}

