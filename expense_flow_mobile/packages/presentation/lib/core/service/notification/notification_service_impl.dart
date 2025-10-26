import 'dart:async';
import 'dart:io';

import 'package:domain/model/device_platform.dart';
import 'package:domain/use_case/notification/notification_register_device_use_case.dart';
import 'package:domain/use_case/notification/notification_unregister_device_use_case.dart';
import 'package:firebase_core/firebase_core.dart';
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

  String? _lastRegisteredToken;
  Future<void>? _registrationInProgress;

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

      await _messaging.setAutoInitEnabled(true);

      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          _logger.i('APNS token obtained: $apnsToken');
        } else {
          _logger.i(
              'APNS token not yet available; waiting for FirebaseMessaging callback');
        }
      }

      _setupTokenRefreshListener();
      await _fetchAndRegisterToken();

      _isInitialized = true;
      if (_currentToken != null) {
        _logger.i('Notification service initialized successfully');
      } else {
        _logger.i(
          'Notification service initialized; awaiting APNS/FCM token assignment',
        );
      }
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

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      _logger
          .i('Notification permission status: ${settings.authorizationStatus}');
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
      if (_currentToken != null) {
        return _currentToken;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
      }
      return token;
    } on FirebaseException catch (e, stackTrace) {
      if (e.code == 'apns-token-not-set') {
        _logger.w(
          'APNS token not available yet when requesting FCM token',
        );
        return null;
      }

      _logger.e(
        'Firebase error while getting FCM token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
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
    if (_registrationInProgress != null) {
      _logger
          .i('Device registration already in progress, waiting for completion');
      await _registrationInProgress;
      return;
    }

    // Get current token
    final token = _currentToken ?? await getToken();
    if (token == null) {
      _logger.w('Cannot register device: no FCM token available');
      return;
    }

    if (token == _lastRegisteredToken) {
      _logger.i('Device already registered with current token, skipping');
      return;
    }

    _logger.i(
        'Starting device registration for token: ${token.substring(0, 20)}...');
    _registrationInProgress = _performRegistration(token);

    try {
      await _registrationInProgress;
      _lastRegisteredToken = token;
    } finally {
      _registrationInProgress = null;
    }
  }

  Future<void> _performRegistration(String token) async {
    final platform =
        Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;
    final params = NotificationRegisterDeviceParams(
      token: token,
      platform: platform,
    );

    final result = await _registerDeviceUseCase(params);
    result.fold(
      (failure) {
        _logger.e('Failed to register device: ${failure.message}');
        throw Exception('Registration failed: ${failure.message}');
      },
      (_) => _logger.i('Device registered successfully'),
    );
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
          _lastRegisteredToken = null;
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
        _logger
            .i('Notification tapped (app in background): ${message.messageId}');
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

    _lastRegisteredToken = null;
    _registrationInProgress = null;

    _isInitialized = false;
  }

  void _setupTokenRefreshListener() {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
      (newToken) async {
        _logger.i('FCM token refreshed: $newToken');
        _currentToken = newToken;
        await registerDevice();
      },
      onError: (error) {
        _logger.e('Token refresh error', error: error);
      },
    );
  }

  Future<void> _fetchAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _logger.w(
            'FCM token not yet available; waiting for onTokenRefresh callback');
        return;
      }

      _currentToken = token;
      _logger.i('FCM token obtained: $token');
      await registerDevice();
    } on FirebaseException catch (e, stackTrace) {
      if (e.code == 'apns-token-not-set') {
        _logger.w(
          'Firebase did not provide an FCM token yet because APNS token is missing; waiting for token refresh',
        );
        return;
      }

      _logger.e(
        'Firebase error while fetching FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error while fetching FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
