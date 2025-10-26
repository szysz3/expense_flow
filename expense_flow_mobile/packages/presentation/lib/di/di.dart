// External packages
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data layer
import 'package:data/repository/chat/chat_repository_config.dart';
import 'package:data/repository/chat/chat_repository_impl.dart';
import 'package:data/repository/notification/notification_repository_impl.dart';
import 'package:data/repository/receipt/receipt_repository_impl.dart';
import 'package:data/repository/settings_repository_impl.dart';
import 'package:data/repository/unprocessed_receipt/unprocessed_receipt_repository_impl.dart';

// Domain layer
import 'package:domain/repository/chat_repository.dart';
import 'package:domain/repository/notification_repository.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/repository/unprocessed_receipt_repository.dart';
import 'package:domain/use_case/calculate_total_savings_use_case.dart';
import 'package:domain/use_case/chat/chat_connect_use_case.dart';
import 'package:domain/use_case/chat/chat_create_user_message_use_case.dart';
import 'package:domain/use_case/chat/chat_disconnect_use_case.dart';
import 'package:domain/use_case/chat/chat_observe_messages_use_case.dart';
import 'package:domain/use_case/chat/chat_process_message_use_case.dart';
import 'package:domain/use_case/chat/chat_send_message_use_case.dart';
import 'package:domain/use_case/get_autocomplete_suggestions_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_daily_expenses_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:domain/use_case/notification/notification_register_device_use_case.dart';
import 'package:domain/use_case/notification/notification_unregister_device_use_case.dart';
import 'package:domain/use_case/receipt/receipt_analyze_use_case.dart';
import 'package:domain/use_case/receipt/receipt_create_use_case.dart';
import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:domain/use_case/receipt/receipt_filter_use_case.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:domain/use_case/settings/settings_get_month_savings_use_case.dart';
import 'package:domain/use_case/settings/settings_get_savings_use_case.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_delete_use_case.dart';
import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_update_use_case.dart';

// Presentation layer
import '../config/env_config.dart';
import '../core/service/camera/camera_service.dart';
import '../core/service/camera/camera_service_impl.dart';
import '../core/service/notification/notification_service.dart';
import '../core/service/notification/notification_service_impl.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  await _loadEnv();

  await _registerInfrastructure();
  _registerRepositories();
  _registerUseCases();
  _registerServices();
}

Future<void> _registerInfrastructure() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerLazySingleton<Logger>(
    () => Logger(printer: PrettyPrinter()),
  );

  getIt.registerLazySingleton<Connectivity>(
    () => Connectivity(),
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        headers: {
          'X-API-Key': EnvConfig.apiKey,
          'accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 600),
        receiveTimeout: const Duration(seconds: 600),
      ),
    );

    dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  });

  getIt.registerSingleton<LocalizationService>(
    LocalizationService.fromLocaleName("en"),
  );

  getIt.registerLazySingleton<FirebaseMessaging>(
    () => FirebaseMessaging.instance,
  );
}

void _registerRepositories() {
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      sharedPreferences: getIt<SharedPreferences>(),
      logger: getIt<Logger>(),
    ),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      config: ChatRepositoryConfig(
        webSocketUrl: EnvConfig.webSocketUrl,
        apiKey: EnvConfig.apiKey,
      ),
      logger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  getIt.registerLazySingleton<UnprocessedReceiptRepository>(
    () => UnprocessedReceiptRepositoryImpl(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );
}

void _registerUseCases() {
  // Receipt
  getIt.registerLazySingleton(
    () => ReceiptAnalyzeUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptCreateUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptGetUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptUpdateUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptDeleteUseCase(getIt<ReceiptRepository>()),
  );

  // Factory: new instance per call
  getIt.registerFactory<ReceiptFilterUseCase>(
    () => ReceiptFilterUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMonthsSummaryUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetDailyExpensesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAutocompleteSuggestionsUseCase(getIt<ReceiptRepository>()),
  );

  // Settings
  getIt.registerLazySingleton(
    () => SettingsGetSavingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => SettingsGetMonthSavingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => SettingsSaveSavingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => CalculateTotalSavingsUseCase(),
  );

  // Chat
  getIt.registerLazySingleton(
    () => ChatConnectUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatDisconnectUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatObserveMessagesUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatSendMessageUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatProcessMessageUseCase(),
  );

  getIt.registerLazySingleton(
    () => ChatCreateUserMessageUseCase(),
  );

  // Unprocessed Receipt
  getIt.registerLazySingleton(
    () =>
        UnprocessedReceiptDeleteUseCase(getIt<UnprocessedReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () =>
        UnprocessedReceiptUpdateUseCase(getIt<UnprocessedReceiptRepository>()),
  );

  // Notification
  getIt.registerLazySingleton(
    () => NotificationRegisterDeviceUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerLazySingleton(
    () => NotificationUnregisterDeviceUseCase(getIt<NotificationRepository>()),
  );
}

void _registerServices() {
  getIt.registerLazySingleton<CameraService>(
    () => CameraServiceImpl(),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(
      messaging: getIt<FirebaseMessaging>(),
      registerDeviceUseCase: getIt<NotificationRegisterDeviceUseCase>(),
      unregisterDeviceUseCase: getIt<NotificationUnregisterDeviceUseCase>(),
      logger: getIt<Logger>(),
    ),
  );
}

Future<void> _loadEnv() async {
  await EnvConfig.load();
  EnvConfig.validate();
}
