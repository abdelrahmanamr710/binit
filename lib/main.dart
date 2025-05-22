import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
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
import 'services/notification_manager.dart';
import 'services/user_credentials_cache_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/recyclingCompany_homescreen.dart';
import 'screens/binOwner_profile.dart';
import 'screens/binOwner_notifications.dart';
import 'screens/faq_screen.dart';
import 'screens/contact_support_screen.dart';
import 'screens/feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';

// Top-level function for handling Firebase messages in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  
  // Initialize notification service
  await NotificationService().init();
  await NotificationManager().initialize();  // Initialize NotificationManager in background

  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  
  // Extract data from the message
  final data = message.data;
  final messageType = data['type'] ?? '';
  
  try {
    // Initialize the user credentials cache service
    final userCredentialsCacheService = UserCredentialsCacheService();
    
    // Check if the cache is valid
    final isCacheValid = await userCredentialsCacheService.isCacheValid();
    if (!isCacheValid) {
      print("User credentials cache is not valid, skipping notification");
      return;
    }
    
    // Check if the user is a bin owner
    final isBinOwner = await userCredentialsCacheService.isCachedUserBinOwner();
    
    // Handle different message types
    switch (messageType) {
      case 'bin_level_update':
        final binName = data['binName'] ?? 'Unknown';
        final material = data['material'] ?? 'Unknown';
        final level = data['level'] ?? '0';
        final binId = data['binId'] ?? '';
        
        // Only show bin level updates to bin owners who own this bin
        if (isBinOwner) {
          if (binId.isNotEmpty) {
            // Check if this bin is registered to the cached user
            final isBinRegistered = await userCredentialsCacheService.isBinRegisteredToCachedUser(binId);
            if (!isBinRegistered) {
              print("Bin $binId is not registered to the cached user, skipping notification");
              return;
            }
          }
          
          await NotificationService().showBinLevelUpdate(
            binName: binName,
            material: material,
            level: level,
          );
        }
        break;
        
      case 'offer_accepted':
        final company = data['company'] ?? 'Unknown';
        final kilos = num.tryParse(data['kilos'] ?? '0') ?? 0;
        
        // Only show offer accepted notifications to bin owners
        if (isBinOwner) {
          await NotificationService().showOfferAccepted(
            company: company,
            kilos: kilos,
          );
        }
        break;
        
      default:
        // For unknown message types, show a generic notification
        if (message.notification != null) {
          final title = message.notification!.title ?? 'New Notification';
          final body = message.notification!.body ?? 'You have a new notification';
          
          // Use notification service to show the notification
          print("Showing generic notification: $title - $body");
          await NotificationService().showBinLevelUpdate(
            binName: 'Bin-It',
            material: 'System',
            level: 'notification received',
          );
        }
    }
  } catch (e) {
    print("Error handling background message: $e");
  }
}

class BinItApp extends StatefulWidget {
  const BinItApp({super.key});

  @override
  _BinItAppState createState() => _BinItAppState();
}

class _BinItAppState extends State<BinItApp> {
  String? _initialRoute;
  late final Stream<RemoteMessage> _onMessageStream;
  late final StreamSubscription<RemoteMessage> _onMessageSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
    _initializeServices();

    // Set up a global notification listener for foreground messages
    _onMessageStream = FirebaseMessaging.onMessage;
    _onMessageSubscription = _onMessageStream.listen((RemoteMessage message) async {
      print('Global FCM listener triggered: ${message.data}');
      final data = message.data;
      final type = data['type'];
      if (type == 'bin_level_update') {
        await NotificationService().showBinLevelUpdate(
          binName: data['binName'] ?? 'Unknown',
          material: data['material'] ?? 'Unknown',
          level: data['level'] ?? '0',
        );
      } else if (type == 'offer_accepted') {
        await NotificationService().showOfferAccepted(
          company: data['company'] ?? 'Unknown',
          kilos: num.tryParse(data['kilos'] ?? '0') ?? 0,
        );
      }
    });
  }

  Future<void> _initializeServices() async {
    await NotificationService().init();
    await NotificationManager().initialize();
  }

  @override
  void dispose() {
    _onMessageSubscription.cancel();
    NotificationManager().dispose();  // Clean up NotificationManager
    super.dispose();
  }

  Future<void> _checkInitialRoute() async {
    try {
      print('Checking initial route...');
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      print('Current user check result: ${currentUser?.userType}');
      
      setState(() {
        if (currentUser != null) {
          _initialRoute = currentUser.userType == 'binOwner'
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
      routes: <String, WidgetBuilder>{
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup_as': (context) => const SignUpAs(),
        '/bin_owner_signup': (context) => const BinOwnerSignupScreen(),
        '/recycling_company_signup': (context) => const RecyclingCompanySignupScreen(),
        '/bin_owner_home': (context) => const BinOwnerHomeScreen(),
        '/recycling_company_home': (context) => const RecyclingCompanyHomeScreen(),
        '/bin_owner_profile': (context) => BinOwnerProfile(user: ModalRoute.of(context)!.settings.arguments as UserModel),
        '/notifications': (context) => const BinOwnerNotificationsScreen(),
        '/faq': (context) => const FAQScreen(),
        '/contact_support': (context) => ContactSupportScreen(),
        '/feedback': (context) {
          final user = Provider.of<UserModel>(context, listen: false);
          return FeedbackScreen(user: user);
        },
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize notification service
  await NotificationService().init();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle notifications from native Android
  const platform = MethodChannel('com.sams.binit/notification');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'handleNotification') {
      final type = call.arguments['type'] as String;
      final data = call.arguments['data'] as Map<String, dynamic>;
      
      await NotificationService().handleNativeNotification(
        title: data['title'] ?? 'Notification',
        body: data['body'] ?? 'You have a new notification',
        type: type,
        data: data,
      );
    }
  });
  
  // Optimize Firestore settings for better performance and offline support
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Enable offline persistence for Realtime Database
  try {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10000000); // 10MB cache
  } catch (e) {
    print('Persistence already enabled or could not be enabled: $e');
  }
  
  // Initialize services
  await NotificationService().init();
  await FCMService().init();
  
  // Start the database listener service through the method channel
  try {
    const methodChannel = MethodChannel('com.sams.binit/background_service');
    await methodChannel.invokeMethod('startDatabaseListenerService');
    print("Database listener service started successfully from main");
  } catch (e) {
    print('Failed to start database listener service: $e');
  }
  
  // For development only: Use Firebase Functions emulator if running locally
  // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  
  runApp(const BinItApp());
}

