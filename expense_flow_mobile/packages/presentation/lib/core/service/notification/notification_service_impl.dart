import 'dart:async';
import 'dart:io';

import 'package:domain/model/device_platform.dart';
import 'package:domain/use_case/notification/notification_register_device_use_case.dart';
import 'package:domain/use_case/notification/notification_unregister_device_use_case.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

import 'notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _messaging;
  final NotificationRegisterDeviceUseCase _registerDeviceUseCase;
  final NotificationUnregisterDeviceUseCase _unregisterDeviceUseCase;
  final Logger _logger;

  String? _currentToken;
  bool _isInitialized = false;

  // Stream subscriptions to be canceled on dispose
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundOpenedSubscription;

  NotificationServiceImpl({
    required FirebaseMessaging messaging,
    required NotificationRegisterDeviceUseCase registerDeviceUseCase,
    required NotificationUnregisterDeviceUseCase unregisterDeviceUseCase,
    required Logger logger,
  })  : _messaging = messaging,
        _registerDeviceUseCase = registerDeviceUseCase,
        _unregisterDeviceUseCase = unregisterDeviceUseCase,
        _logger = logger;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.i('Notification service already initialized');
      return;
    }

    try {
      _logger.i('Initializing notification service...');

      // Request permissions
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        _logger.w('Notification permission not granted');
        return;
      }

      // Get and store the token
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        _logger.i('FCM Token obtained: ${_currentToken!.substring(0, 20)}...');
      } else {
        _logger.w('Failed to obtain FCM token');
        return;
      }

      // Register device with backend
      await registerDevice();

      // Set up token refresh handler
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        (newToken) async {
          _logger.i('FCM Token refreshed');
          _currentToken = newToken;
          await registerDevice();
        },
        onError: (error) {
          _logger.e('Token refresh error', error: error);
        },
      );

      _isInitialized = true;
      _logger.i('Notification service initialized successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize notification service',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      _logger.i('Notification permission status: ${settings.authorizationStatus}');
      return granted;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to request notification permission',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return _currentToken ?? await _messaging.getToken();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> registerDevice() async {
    final token = _currentToken ?? await getToken();
    if (token == null) {
      _logger.w('Cannot register device: no FCM token available');
      return;
    }

    try {
      final platform = Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
      final params = NotificationRegisterDeviceParams(
        token: token,
        platform: platform,
      );

      final result = await _registerDeviceUseCase(params);
      result.fold(
        (failure) {
          _logger.e('Failed to register device: ${failure.message}');
        },
        (_) {
          _logger.i('Device registered successfully');
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error registering device',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> unregisterDevice() async {
    final token = _currentToken;
    if (token == null) {
      _logger.w('Cannot unregister device: no FCM token available');
      return;
    }

    try {
      final result = await _unregisterDeviceUseCase(token);
      result.fold(
        (failure) {
          _logger.e('Failed to unregister device: ${failure.message}');
        },
        (_) {
          _logger.i('Device unregistered successfully');
          _currentToken = null;
        },
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error unregistering device',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void setupNotificationHandlers({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) {
    // Cancel existing subscriptions to prevent duplicates
    _foregroundSubscription?.cancel();
    _backgroundOpenedSubscription?.cancel();

    // Handle foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        _logger.i('Received foreground message: ${message.messageId}');
        _logMessageDetails(message);
        onMessageReceived(message);
      },
      onError: (error) {
        _logger.e('Foreground message error', error: error);
      },
    );

    // Handle notification taps (when app is in background)
    _backgroundOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _logger.i('Notification tapped (app in background): ${message.messageId}');
        _logMessageDetails(message);
        onMessageOpenedApp(message);
      },
      onError: (error) {
        _logger.e('Background opened message error', error: error);
      },
    );
  }

  void _logMessageDetails(RemoteMessage message) {
    _logger.d('Message data: ${message.data}');
    if (message.notification != null) {
      _logger.d('Notification title: ${message.notification!.title}');
      _logger.d('Notification body: ${message.notification!.body}');
    }
  }

  @override
  void dispose() {
    _logger.i('Disposing notification service');

    // Cancel all stream subscriptions to prevent memory leaks
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _backgroundOpenedSubscription?.cancel();

    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _backgroundOpenedSubscription = null;

    _isInitialized = false;
  }
}
