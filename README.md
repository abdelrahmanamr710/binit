# binit

Graduation Project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Bin-It App

Bin-It is a Flutter application that monitors bin levels and sends notifications to users when levels change.

## Background Notification System

The app uses a multi-layered approach to ensure reliable background notifications:

### 1. Firebase Realtime Database Listeners

The primary mechanism for real-time bin level monitoring is Firebase Realtime Database listeners. These listeners are set up in the `FirebaseBackgroundService` class and will trigger notifications whenever bin levels change in the database.

Key features:
- Real-time updates (no polling delay)
- Works when the app is in the foreground
- Persists data for offline use
- Automatically reconnects after network interruptions

### 2. Firebase Cloud Messaging (FCM)

As a backup mechanism, the app also uses Firebase Cloud Messaging to receive push notifications from the server. This works even when the app is completely closed.

Key features:
- Server-initiated notifications
- Works when the app is closed
- Low battery consumption

### 3. Native Android Background Service

For additional reliability on Android, the app includes a native Kotlin background service (`DatabaseListenerService.kt`) that runs independently of the Flutter app. This service:
- Monitors bin levels in the background
- Starts automatically on device boot
- Uses Android's foreground service capabilities for reliable operation

## How It Works

1. When the app starts, it initializes the `FirebaseBackgroundService` which sets up real-time database listeners
2. The service listens for changes to the user's registered bins
3. When a bin level changes, a notification is displayed to the user
4. The native Android service provides an additional layer of monitoring

## Implementation Details

The background notification system is implemented across several files:

- `lib/services/firebase_background_service.dart`: Main Flutter implementation of database listeners
- `lib/services/notification_service.dart`: Handles displaying notifications to the user
- `lib/services/fcm_service.dart`: Configures Firebase Cloud Messaging
- `android/app/src/main/kotlin/.../DatabaseListenerService.kt`: Native Android background service
- `android/app/src/main/kotlin/.../BootReceiver.kt`: Restarts services after device reboot

## Troubleshooting

If notifications aren't working:

1. Ensure Firebase is properly configured
2. Check that notification permissions are granted
3. Verify the app has proper background permissions
4. Make sure the device isn't in battery optimization mode
