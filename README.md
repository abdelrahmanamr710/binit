# Bin-It

A Flutter application for monitoring bin levels and managing recycling operations between bin owners and recycling companies.

## Overview

Bin-It is a comprehensive waste management solution that connects bin owners with recycling companies. The app provides real-time bin level monitoring, automated notifications, and a marketplace for selling recyclable materials.

## Architecture

The app follows a clean architecture pattern with the following main components:

### 1. Screens

#### Authentication Screens
- `splash_screen.dart`: Initial loading screen
- `login_screen.dart`: User authentication
- `signup_as_screen.dart`: User type selection (Bin Owner/Recycling Company)
- `bin_owner_signup_screen.dart`: Bin owner registration
- `recyclingCompany_signup_screen.dart`: Recycling company registration

#### Bin Owner Screens
- `binOwner_homescreen.dart`: Main dashboard for bin owners
- `binOwner_profile.dart`: User profile management
- `binOwner_notifications.dart`: Notification center
- `binOwner_stock.dart`: Stock management
- `binOwner_sell.dart`: Material selling interface
- `binOwner_orders.dart`: Order history and management

#### Recycling Company Screens
- `recyclingCompany_homescreen.dart`: Main dashboard for recycling companies
- `recyclingCompany_profile.dart`: Company profile management
- `recyclingCompany_orderDetails.dart`: Detailed order view
- `recyclingCompany_previousOrders.dart`: Order history

### 2. Services

#### Core Services
- `auth_service.dart`: Handles user authentication and session management
- `notification_service.dart`: Manages local and push notifications
- `fcm_service.dart`: Firebase Cloud Messaging integration
- `firebase_background_service.dart`: Background data synchronization
- `user_credentials_cache_service.dart`: Local user data caching
- `firebase_helper.dart`: Firebase utility functions

### 3. Models
- `user_model.dart`: User data structure
- `bin_model.dart`: Bin data structure

## Features

### Real-time Bin Monitoring
- Firebase Realtime Database integration for instant updates
- Background service for continuous monitoring
- Push notifications for level changes

### Authentication System
- Email/password authentication
- User type-specific registration flows
- Secure session management

### Notification System
- Multi-layered notification approach:
  1. Firebase Realtime Database listeners
  2. Firebase Cloud Messaging (FCM)
  3. Native Android background service

### Data Management
- Offline data persistence
- Real-time synchronization
- Secure data caching

## Technical Implementation

### Firebase Integration
- Authentication
- Realtime Database
- Cloud Functions
- Cloud Messaging
- Firestore

### Background Processing
- Native Android service for reliable background monitoring
- Automatic service restart on device boot
- Battery-efficient background operations

### State Management
- Provider pattern for state management
- Local storage for offline data
- Real-time data synchronization

## Getting Started

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
4. Run the app:
   ```bash
   flutter run
   ```

## Dependencies

Key dependencies include:
- `firebase_core`: Firebase integration
- `firebase_auth`: Authentication
- `firebase_database`: Realtime Database
- `firebase_messaging`: Push notifications
- `flutter_local_notifications`: Local notifications
- `cloud_functions`: Firebase Cloud Functions
- `flutter_secure_storage`: Secure data storage

## Troubleshooting

### Common Issues

1. Notification Issues
   - Check Firebase configuration
   - Verify notification permissions
   - Ensure background service is running

2. Authentication Problems
   - Verify Firebase configuration
   - Check internet connectivity
   - Clear app cache if needed

3. Background Service Issues
   - Check battery optimization settings
   - Verify service permissions
   - Restart the app

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
