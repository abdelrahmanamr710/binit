import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/signup_as_screen.dart';
import 'screens/bin_owner_signup_screen.dart';
import 'screens/recyclingCompany_signup_screen.dart';
import 'src/pigeon.g.dart';
import 'screens/binOwner_homescreen.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/recyclingCompany_homescreen.dart';
import 'screens/binOwner_profile.dart';
import 'screens/binOwner_notifications.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Wait for Firebase to be ready
  await Future.delayed(const Duration(seconds: 1));
  
  // Initialize services
  await NotificationService().init();
  await FCMService().init();
  
  runApp(const BinItApp());
}

class BinItApp extends StatefulWidget {
  const BinItApp({super.key});

  @override
  _BinItAppState createState() => _BinItAppState();
}

class _BinItAppState extends State<BinItApp> {
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    try {
      print('Checking initial route...');
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      print('Current user check result: ${currentUser?.userType}');
      
      setState(() {
        if (currentUser != null) {
          _initialRoute = currentUser.userType == 'bin_owner'
              ? '/bin_owner_home'
              : '/recycling_company_home';
          print('Setting initial route to: $_initialRoute');
        } else {
          _initialRoute = '/';
          print('No user found, setting initial route to: /');
        }
      });
    } catch (error) {
      print('Error in _checkInitialRoute: $error');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _initialRoute = '/';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bin-It',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: _initialRoute ?? '/',
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{ // Define routes for navigation
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup_as': (context) => const SignUpAs(),
        '/bin_owner_signup': (context) => const BinOwnerSignupScreen(),
        '/recycling_company_signup': (context) => const RecyclingCompanySignupScreen(),
        '/bin_owner_home': (context) => const BinOwnerHomeScreen(), // Add this route.
        '/recycling_company_home': (context) => const RecyclingCompanyHomeScreen(), // Add this route.'
        '/bin_owner_profile': (context) => BinOwnerProfile(user: ModalRoute.of(context)!.settings.arguments as UserModel), // corrected route
        '/notifications': (context) => const BinOwnerNotificationsScreen(),
      },
    );
  }
}

