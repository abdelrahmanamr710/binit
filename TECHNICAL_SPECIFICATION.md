# Bin-It Technical Specification

## Services

### 1. Authentication Service (`auth_service.dart`)
The authentication service handles all user authentication and session management.

#### Key Components:
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
}
```

#### Functionality:
1. **User Registration**
   - Validates user input
   - Creates Firebase Auth account
   - Stores additional user data in Firestore
   - Handles email verification
   - Manages user type (bin owner/recycling company)

2. **User Login**
   - Email/password authentication
   - Session token management
   - User data retrieval
   - Error handling and recovery

3. **Session Management**
   - Token refresh
   - Auto-login functionality
   - Session timeout handling
   - Secure storage of credentials

### 2. Notification Service (`notification_service.dart`)
Handles all notification-related functionality across the app.

#### Key Components:
```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;
}
```

#### Functionality:
1. **Local Notifications**
   - In-app notification display
   - Custom notification channels
   - Notification scheduling
   - Sound and vibration control

2. **Push Notifications**
   - FCM token management
   - Background message handling
   - Notification payload processing
   - Deep linking support

3. **Notification Categories**
   - Bin level updates
   - Order status changes
   - System notifications
   - Maintenance alerts

### 3. Firebase Background Service (`firebase_background_service.dart`)
Manages real-time database monitoring and background operations.

#### Key Components:
```dart
class FirebaseBackgroundService {
  final FirebaseDatabase _database;
  final NotificationService _notificationService;
}
```

#### Functionality:
1. **Database Monitoring**
   - Real-time bin level tracking
   - Data synchronization
   - Offline data persistence
   - Connection state management

2. **Background Operations**
   - Battery-efficient monitoring
   - Auto-reconnection
   - Error recovery
   - Data caching

### 4. FCM Service (`fcm_service.dart`)
Manages Firebase Cloud Messaging integration.

#### Key Components:
```dart
class FCMService {
  final FirebaseMessaging _messaging;
  final NotificationService _notificationService;
}
```

#### Functionality:
1. **Message Handling**
   - Background message processing
   - Foreground message handling
   - Notification channel setup
   - Message routing

2. **Token Management**
   - FCM token generation
   - Token refresh
   - Server registration
   - Device management

### 5. User Credentials Cache Service (`user_credentials_cache_service.dart`)
Manages local storage of user credentials and preferences.

#### Key Components:
```dart
class UserCredentialsCacheService {
  final FlutterSecureStorage _storage;
}
```

#### Functionality:
1. **Credential Storage**
   - Secure token storage
   - User preferences
   - Session data
   - Cache invalidation

2. **Data Management**
   - Cache updates
   - Data synchronization
   - Storage cleanup
   - Error handling

## Screens

### 1. Authentication Screens

#### Splash Screen (`splash_screen.dart`)
- Initial loading screen
- App initialization
- Authentication state check
- Navigation routing

#### Login Screen (`login_screen.dart`)
- User authentication form
- Input validation
- Error handling
- Navigation to registration
- Password recovery

#### Sign Up Screens
1. **Sign Up As Screen** (`signup_as_screen.dart`)
   - User type selection
   - Navigation to specific registration
   - Type-specific validation

2. **Bin Owner Signup** (`bin_owner_signup_screen.dart`)
   - Bin owner registration form
   - Location selection
   - Bin capacity setup
   - Initial bin registration

3. **Recycling Company Signup** (`recyclingCompany_signup_screen.dart`)
   - Company registration form
   - Business details
   - Service area setup
   - Payment information

### 2. Bin Owner Screens

#### Home Screen (`binOwner_homescreen.dart`)
- Dashboard overview
- Bin level monitoring
- Quick actions
- Navigation menu
- Real-time updates

#### Profile Screen (`binOwner_profile.dart`)
- User information management
- Account settings
- Bin management
- Notification preferences
- Security settings

#### Notifications Screen (`binOwner_notifications.dart`)
- Notification history
- Filtering options
- Action handling
- Read/unread status
- Notification preferences

#### Stock Screen (`binOwner_stock.dart`)
- Material inventory
- Stock levels
- Material types
- Quantity tracking
- Stock alerts

#### Sell Screen (`binOwner_sell.dart`)
- Material listing
- Price setting
- Quantity management
- Order creation
- Transaction history

#### Orders Screen (`binOwner_orders.dart`)
- Order management
- Status tracking
- Payment handling
- Order history
- Filtering and search

### 3. Recycling Company Screens

#### Home Screen (`recyclingCompany_homescreen.dart`)
- Company dashboard
- Order management
- Material tracking
- Performance metrics
- Quick actions

#### Profile Screen (`recyclingCompany_profile.dart`)
- Company information
- Service area
- Payment details
- Account settings
- Business hours

#### Order Details Screen (`recyclingCompany_orderDetails.dart`)
- Order information
- Material details
- Payment status
- Delivery tracking
- Communication

#### Previous Orders Screen (`recyclingCompany_previousOrders.dart`)
- Order history
- Performance analytics
- Filtering options
- Export functionality
- Search capabilities

## Screen-Service Integration

### 1. Authentication Flow
```dart
// Example of authentication flow
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  Future<void> _handleLogin() async {
    try {
      final user = await _authService.signIn(email, password);
      await _notificationService.initializeForUser(user);
      // Navigate to appropriate home screen
    } catch (e) {
      // Handle error
    }
  }
}
```

### 2. Bin Monitoring Flow
```dart
// Example of bin monitoring integration
class BinOwnerHomeScreen extends StatefulWidget {
  @override
  _BinOwnerHomeScreenState createState() => _BinOwnerHomeScreenState();
}

class _BinOwnerHomeScreenState extends State<BinOwnerHomeScreen> {
  final FirebaseBackgroundService _backgroundService = FirebaseBackgroundService();
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    _initializeBinMonitoring();
  }
  
  Future<void> _initializeBinMonitoring() async {
    await _backgroundService.initialize();
    _backgroundService.startMonitoring();
  }
}
```

### 3. Order Management Flow
```dart
// Example of order management integration
class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserCredentialsCacheService _cacheService = UserCredentialsCacheService();
  
  Future<void> _handleOrderUpdate() async {
    await _notificationService.showOrderUpdate();
    await _cacheService.updateOrderCache();
  }
}
```

## Error Handling and Recovery

### 1. Network Errors
- Automatic retry mechanism
- Offline data persistence
- Connection state monitoring
- User feedback

### 2. Authentication Errors
- Session recovery
- Token refresh
- Re-authentication flow
- Error messaging

### 3. Database Errors
- Data synchronization
- Conflict resolution
- Cache management
- Error logging

## Performance Optimization

### 1. Image Optimization
- Lazy loading
- Caching
- Compression
- Format optimization

### 2. State Management
- Efficient provider usage
- State persistence
- Memory management
- Widget rebuilding optimization

### 3. Network Optimization
- Request batching
- Data pagination
- Cache strategies
- Connection monitoring

## Security Implementation

### 1. Data Protection
- Encryption at rest
- Secure transmission
- Token management
- Access control

### 2. Input Validation
- Data sanitization
- Type checking
- Format validation
- Security rules

### 3. Authentication Security
- Password policies
- Session management
- Token refresh
- Access control 