import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen
//import 'screens/welcome_screen.dart'; // Remove WelcomeScreen import
import 'screens/login_screen.dart'; // Import LoginScreen - Ensure this import is correct
import 'models/user_model.dart'; //Import user model
import 'services/auth_service.dart';
import 'screens/signup_as_screen.dart';
import 'screens/bin_owner_signup_screen.dart';
import 'screens/recyclingCompany_signup_screen.dart'; // Ensure this import is correct
import 'src/pigeon.g.dart';
import 'screens/binOwner_homescreen.dart';
import 'screens/recyclingCompany_homescreen.dart';
import 'screens/binOwner_profile.dart';

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
      routes: <String, WidgetBuilder>{ // Define routes for navigation
        '/login': (context) => const LoginScreen(),
        '/signup_as': (context) => const SignUpAs(),
        '/bin_owner_signup': (context) => const BinOwnerSignupScreen(),
        '/recycling_company_signup': (context) => const RecyclingCompanySignupScreen(),
        '/bin_owner_home': (context) => const BinOwnerHomeScreen(userName: "Owner"), // Add this route.
        '/recycling_company_home': (context) => const RecyclingCompanyHomeScreen(userName: "Company"), // Add this route.'
        '/bin_owner_profile': (context) => BinOwnerProfile(user: ModalRoute.of(context)!.settings.arguments as UserModel), // corrected route
      },
    );
  }
}

