# Firebase Push Notifications Setup Guide

This guide explains how to configure Firebase Cloud Messaging (FCM) for push notifications in the ExpenseFlow mobile app.

## Overview

The mobile app has been fully integrated with push notifications:
- ✅ Firebase dependencies added
- ✅ Domain, Data, and Presentation layers implemented
- ✅ Notification service with permission handling
- ✅ Device registration with backend
- ✅ Foreground, background, and terminated state handlers
- ✅ Navigation to receipts when notification is tapped
- ✅ Token refresh handling

**What's needed**: Firebase project configuration files for Android and iOS.

## Prerequisites

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Have access to your Google Cloud Console for FCM setup

## Android Configuration

### Step 1: Register Android App in Firebase

1. Go to Firebase Console → Project Settings
2. Click "Add app" → Select Android
3. Enter package name: `com.expenseflow.mobile` (or your actual package name)
4. Download `google-services.json`

### Step 2: Add google-services.json

Place the downloaded `google-services.json` file in:
```
expense_flow_mobile/android/app/google-services.json
```

### Step 3: Update Android Build Files

**android/build.gradle** (project level):
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle** (app level):
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        // Add these lines
        multiDexEnabled true
    }
}

dependencies {
    // Firebase dependencies (should be auto-added by flutterfire)
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**android/app/src/main/AndroidManifest.xml**:
```xml
<manifest>
    <application>
        <!-- Add this for notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- Add this for notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

## iOS Configuration

### Step 1: Register iOS App in Firebase

1. Go to Firebase Console → Project Settings
2. Click "Add app" → Select iOS
3. Enter bundle ID: `com.expenseflow.mobile` (or your actual bundle ID)
4. Download `GoogleService-Info.plist`

### Step 2: Add GoogleService-Info.plist

1. Open `expense_flow_mobile/ios/Runner.xcworkspace` in Xcode
2. Drag `GoogleService-Info.plist` into the `Runner` folder
3. Ensure "Copy items if needed" is checked
4. Make sure it's added to the `Runner` target

### Step 3: Enable Push Notifications Capability

In Xcode:
1. Select the `Runner` project
2. Select the `Runner` target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and check:
   - Remote notifications
   - Background fetch

### Step 4: Update Info.plist

Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

### Step 5: APNs Certificate Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to Certificates, Identifiers & Profiles
3. Create an APNs certificate for your app's bundle ID
4. Upload the certificate to Firebase Console:
   - Firebase Console → Project Settings → Cloud Messaging
   - Under "Apple app configuration" → Upload your APNs certificate

## Backend Configuration

The backend is already configured to send notifications. You need to add Firebase credentials:

### Option 1: Service Account JSON File

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Set environment variable:
```bash
export FIREBASE_CREDENTIALS_PATH=/path/to/service-account.json
```

### Option 2: JSON Environment Variable

Alternatively, set the JSON content directly:
```bash
export FIREBASE_CREDENTIALS_JSON='{"type":"service_account","project_id":"...","private_key":"..."}'
```

## Testing

### Test Backend Configuration

1. Start the backend with Firebase credentials configured
2. Upload a receipt image
3. Check backend logs for notification dispatch

### Test Mobile App

1. Install app on a physical device (push notifications don't work on simulators/emulators)
2. Grant notification permission when prompted
3. Check logs for FCM token registration
4. Upload a receipt and wait for processing
5. You should receive a push notification

### Debug Commands

**Check if device is registered:**
```bash
curl -X GET http://your-backend-url/api/notifications/devices \
  -H "X-API-Key: your-api-key"
```

**Manually send test notification (from backend):**
```python
from expense_flow.services.notification_service import NotificationService
service = NotificationService(config=config, repository=repository)
await service.send_receipt_processed_notification(
    receipt_id="test-id",
    merchant_name="Test Store",
    total="99.99"
)
```

## Notification Flow

1. **Receipt Upload**: User scans/uploads receipt
2. **Processing**: Backend processes receipt with OCR
3. **Storage**: Receipt is saved to database
4. **Notification**: Backend sends FCM notification to all registered devices
5. **Delivery**:
   - **Foreground**: In-app snackbar with "View" button
   - **Background**: System notification in notification tray
   - **Terminated**: System notification, app opens to receipt when tapped

## Notification Payload

Backend sends:
```json
{
  "notification": {
    "title": "Receipt processed",
    "body": "We finished processing Whole Foods totaling 45.99."
  },
  "data": {
    "receipt_id": "uuid-here",
    "merchant_name": "Whole Foods",
    "total": "45.99"
  }
}
```

## Troubleshooting

### Android Issues

**Problem**: Not receiving notifications
- Check `google-services.json` is in correct location
- Verify package name matches Firebase configuration
- Check Android logs: `adb logcat | grep FCM`
- Ensure backend has valid Firebase credentials

**Problem**: Build fails
- Run `flutter clean && flutter pub get`
- Sync Gradle files in Android Studio
- Check google-services plugin is applied

### iOS Issues

**Problem**: Not receiving notifications
- Verify `GoogleService-Info.plist` is added to Xcode project
- Check bundle ID matches Firebase configuration
- Ensure APNs certificate is uploaded to Firebase
- Test on physical device (not simulator)
- Check Xcode console for Firebase logs

**Problem**: Permission not requested
- Ensure capabilities are enabled in Xcode
- Check Info.plist has UIBackgroundModes

### Backend Issues

**Problem**: Notifications not sent
- Verify Firebase credentials are loaded
- Check backend logs for errors
- Ensure at least one device is registered
- Test with curl to verify device registration endpoint

## Architecture Summary

### Domain Layer (`packages/domain/lib`)
- **Models**: `DevicePlatform`, `NotificationDeviceRegistration`
- **Repository**: `NotificationRepository` interface
- **Use Cases**:
  - `NotificationRegisterDeviceUseCase`
  - `NotificationUnregisterDeviceUseCase`

### Data Layer (`packages/data/lib`)
- **Repository**: `NotificationRepositoryImpl`
- **API Endpoints**:
  - `POST /api/notifications/devices` (register)
  - `DELETE /api/notifications/devices` (unregister)

### Presentation Layer (`packages/presentation/lib`)
- **Service**: `NotificationService` + `NotificationServiceImpl`
  - Initialize Firebase Messaging
  - Request permissions
  - Register/unregister device
  - Handle foreground/background/terminated notifications
  - Auto token refresh

### App Initialization (`lib/main.dart`)
- Initialize Firebase
- Set background message handler
- Initialize notification service
- Register device on startup

### Main Screen
- Setup notification handlers
- Handle notification taps
- Navigate to receipt browse screen
- Show in-app snackbar for foreground messages

## Files Created/Modified

### New Files
```
packages/domain/lib/model/device_platform.dart
packages/domain/lib/model/notification_device_registration.dart
packages/domain/lib/repository/notification_repository.dart
packages/domain/lib/use_case/notification/notification_register_device_use_case.dart
packages/domain/lib/use_case/notification/notification_unregister_device_use_case.dart
packages/data/lib/repository/notification/notification_repository_impl.dart
packages/presentation/lib/core/service/notification/notification_service.dart
packages/presentation/lib/core/service/notification/notification_service_impl.dart
lib/notification_handler.dart
```

### Modified Files
```
pubspec.yaml (firebase_core)
packages/presentation/pubspec.yaml (firebase_core, firebase_messaging)
packages/data/lib/consts/api_constants.dart
packages/data/lib/remote/api_endpoints.dart
packages/presentation/lib/di/di.dart
packages/presentation/lib/screen/main/main_screen.dart
lib/main.dart
```

## Next Steps

1. ✅ Add Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`)
2. ✅ Configure Firebase credentials on backend
3. ✅ Test on physical devices (iOS and Android)
4. Optional: Customize notification icons and sounds
5. Optional: Add notification settings screen for users to enable/disable
6. Optional: Add notification history/inbox feature

## Support

For issues or questions:
- Check Firebase Console for project configuration
- Review backend logs for notification dispatch
- Check mobile app logs for FCM token and registration
- Verify API endpoints are accessible and authenticated
