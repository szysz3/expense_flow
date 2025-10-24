import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationService {
  /// Initialize Firebase Messaging and register device
  Future<void> initialize();

  /// Request notification permissions from user
  Future<bool> requestPermission();

  /// Get the FCM token
  Future<String?> getToken();

  /// Register device with backend
  Future<void> registerDevice();

  /// Unregister device from backend
  Future<void> unregisterDevice();

  /// Set up notification handlers
  void setupNotificationHandlers({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpenedApp,
  });

  /// Dispose resources
  void dispose();
}
