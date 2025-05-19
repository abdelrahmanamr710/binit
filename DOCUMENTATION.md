# Bin-It Technical Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Technical Stack](#technical-stack)
4. [Database Schema](#database-schema)
5. [API Documentation](#api-documentation)
6. [Authentication Flow](#authentication-flow)
7. [Notification System](#notification-system)
8. [Background Services](#background-services)
9. [State Management](#state-management)
10. [Security Measures](#security-measures)
11. [Testing Strategy](#testing-strategy)
12. [Deployment Guide](#deployment-guide)

## Introduction

Bin-It is a Flutter-based waste management application that facilitates the connection between bin owners and recycling companies. The application provides real-time bin level monitoring, automated notifications, and a marketplace for recyclable materials.

### Key Features
- Real-time bin level monitoring
- Push notifications for level changes
- Material selling marketplace
- Order management system
- User authentication and authorization
- Background service monitoring

## System Architecture

### Frontend Architecture
The application follows a clean architecture pattern with the following layers:

1. **Presentation Layer**
   - Screens (UI components)
   - Widgets (Reusable UI elements)
   - State management

2. **Business Logic Layer**
   - Services
   - Controllers
   - Use cases

3. **Data Layer**
   - Models
   - Repositories
   - Data sources

### Backend Architecture
- Firebase Authentication
- Firebase Realtime Database
- Firebase Cloud Functions
- Firebase Cloud Messaging
- Firebase Firestore

## Technical Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Local Storage**: Flutter Secure Storage
- **UI Components**: Material Design

### Backend
- **Authentication**: Firebase Auth
- **Database**: 
  - Firebase Realtime Database (Real-time data)
  - Firestore (User data, orders)
- **Cloud Functions**: Firebase Cloud Functions
- **Push Notifications**: Firebase Cloud Messaging

### Development Tools
- **IDE**: Android Studio / VS Code
- **Version Control**: Git
- **CI/CD**: GitHub Actions
- **Testing**: Flutter Test

## Database Schema

### Users Collection
```json
{
  "users": {
    "userId": {
      "email": "string",
      "userType": "string", // "binOwner" or "recyclingCompany"
      "name": "string",
      "phone": "string",
      "address": "string",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

### Bins Collection
```json
{
  "bins": {
    "binId": {
      "ownerId": "string",
      "name": "string",
      "material": "string",
      "currentLevel": "number",
      "capacity": "number",
      "location": {
        "latitude": "number",
        "longitude": "number"
      },
      "lastUpdated": "timestamp"
    }
  }
}
```

### Orders Collection
```json
{
  "orders": {
    "orderId": {
      "binOwnerId": "string",
      "companyId": "string",
      "material": "string",
      "quantity": "number",
      "price": "number",
      "status": "string", // "pending", "accepted", "completed", "cancelled"
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

## API Documentation

### Authentication Endpoints

#### Sign Up
```dart
Future<UserCredential> signUp({
  required String email,
  required String password,
  required String userType,
  required Map<String, dynamic> userData
})
```

#### Sign In
```dart
Future<UserCredential> signIn({
  required String email,
  required String password
})
```

#### Sign Out
```dart
Future<void> signOut()
```

### Bin Management Endpoints

#### Register Bin
```dart
Future<void> registerBin({
  required String binId,
  required Map<String, dynamic> binData
})
```

#### Update Bin Level
```dart
Future<void> updateBinLevel({
  required String binId,
  required double level
})
```

#### Get User Bins
```dart
Stream<List<BinModel>> getUserBins(String userId)
```

### Order Management Endpoints

#### Create Order
```dart
Future<void> createOrder({
  required Map<String, dynamic> orderData
})
```

#### Update Order Status
```dart
Future<void> updateOrderStatus({
  required String orderId,
  required String status
})
```

## Authentication Flow

1. **User Registration**
   - User selects account type (Bin Owner/Recycling Company)
   - Enters required information
   - System creates Firebase Auth account
   - Stores additional user data in Firestore

2. **User Login**
   - User enters credentials
   - System authenticates with Firebase Auth
   - Retrieves user data from Firestore
   - Initializes user session

3. **Session Management**
   - Secure token storage
   - Auto-login functionality
   - Session timeout handling

## Notification System

### Components
1. **Firebase Cloud Messaging (FCM)**
   - Push notification delivery
   - Background message handling
   - Notification channel management

2. **Local Notifications**
   - In-app notifications
   - Scheduled notifications
   - Custom notification sounds

3. **Background Service**
   - Continuous bin monitoring
   - Level change detection
   - Notification triggering

### Notification Types
1. **Bin Level Updates**
   - Level change notifications
   - Capacity warnings
   - Maintenance alerts

2. **Order Updates**
   - Order status changes
   - New order requests
   - Payment notifications

3. **System Notifications**
   - Account updates
   - Security alerts
   - Maintenance notifications

## Background Services

### Android Service
```kotlin
class DatabaseListenerService : Service() {
    // Service implementation
}
```

### Service Features
- Continuous database monitoring
- Battery-efficient operation
- Auto-restart capability
- Error handling and recovery

## State Management

### Provider Implementation
```dart
class BinProvider extends ChangeNotifier {
    // State management implementation
}
```

### State Categories
1. **User State**
   - Authentication state
   - User preferences
   - Session data

2. **Bin State**
   - Bin levels
   - Bin status
   - Location data

3. **Order State**
   - Order status
   - Transaction data
   - History

## Security Measures

### Data Security
1. **Encryption**
   - Data at rest
   - Data in transit
   - Secure storage

2. **Authentication**
   - Firebase Auth
   - Token management
   - Session control

3. **Authorization**
   - Role-based access
   - Resource permissions
   - API security

### Security Best Practices
1. **Input Validation**
   - Data sanitization
   - Type checking
   - Format validation

2. **Error Handling**
   - Secure error messages
   - Logging
   - Recovery procedures

## Testing Strategy

### Unit Tests
```dart
void main() {
  group('BinModel Tests', () {
    test('should create bin with valid data', () {
      // Test implementation
    });
  });
}
```

### Integration Tests
```dart
void main() {
  integrationTest('end-to-end test', (tester) async {
    // Test implementation
  });
}
```

### Test Categories
1. **Unit Tests**
   - Model tests
   - Service tests
   - Utility tests

2. **Widget Tests**
   - UI component tests
   - Navigation tests
   - State management tests

3. **Integration Tests**
   - Feature tests
   - API integration tests
   - Database tests

## Deployment Guide

### Android Deployment
1. **Build Configuration**
   ```gradle
   android {
       defaultConfig {
           // Configuration
       }
   }
   ```

2. **Release Process**
   - Generate keystore
   - Configure signing
   - Build release APK
   - Upload to Play Store

### iOS Deployment
1. **Build Configuration**
   ```xcode
   // Configuration in Xcode
   ```

2. **Release Process**
   - Configure certificates
   - Build archive
   - Upload to App Store

### Firebase Configuration
1. **Project Setup**
   - Create Firebase project
   - Configure services
   - Set up security rules

2. **Environment Configuration**
   - Development
   - Staging
   - Production

## Maintenance and Support

### Monitoring
1. **Performance Monitoring**
   - Firebase Performance
   - Crashlytics
   - Analytics

2. **Error Tracking**
   - Error logging
   - Crash reporting
   - User feedback

### Updates and Patches
1. **Version Management**
   - Semantic versioning
   - Changelog maintenance
   - Update distribution

2. **Hotfix Process**
   - Emergency fixes
   - Critical updates
   - Security patches

## References

1. [Flutter Documentation](https://flutter.dev/docs)
2. [Firebase Documentation](https://firebase.google.com/docs)
3. [Material Design Guidelines](https://material.io/design)
4. [Dart Documentation](https://dart.dev/guides)
5. [Firebase Security Rules](https://firebase.google.com/docs/rules) 