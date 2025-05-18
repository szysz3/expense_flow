import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data/repository/chat/chat_repository_config.dart';
import 'package:data/repository/chat/chat_repository_impl.dart';
import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:data/repository/receipt/receipt_repository_impl.dart';
import 'package:data/repository/settings_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/repository/settings_repository.dart';
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
import 'package:domain/use_case/receipt/receipt_analyze_use_case.dart';
import 'package:domain/use_case/receipt/receipt_create_use_case.dart';
import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:domain/use_case/settings/settings_get_month_savings_use_case.dart';
import 'package:domain/use_case/settings/settings_get_savings_use_case.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './di.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await _loadEnv();

  getIt.init();

  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  final logger = Logger(printer: PrettyPrinter());
  getIt.registerLazySingleton(() => logger);

  getIt.registerLazySingleton(() => Connectivity());

  getIt.registerSingleton<LocalizationService>(
    LocalizationService.fromLocaleName("en"),
  );

  _registerRepositories();

  _registerUseCases();
}

_registerRepositories() {
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      dio: _getDio(),
      config: RepositoryConfig(
        baseUrl: EnvConfig.baseUrl,
        apiKey: EnvConfig.apiKey,
      ),
      errorLogger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      sharedPreferences: getIt<SharedPreferences>(),
      errorLogger: getIt<Logger>(),
    ),
  );

  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
        logger: getIt<Logger>(),
        connectivity: getIt<Connectivity>(),
        config: ChatRepositoryConfig(
            webSocketUrl: EnvConfig.webSocketUrl, apiKey: EnvConfig.apiKey)),
  );
}

_registerUseCases() {
  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMonthsSummaryUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptAnalyzeUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptCreateUseCase(getIt<ReceiptRepository>()),
  );

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
    () => GetDailyExpensesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptGetUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptDeleteUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ReceiptUpdateUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAutocompleteSuggestionsUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatConnectUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatObserveMessagesUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatSendMessageUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatDisconnectUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => ChatProcessMessageUseCase(),
  );

  getIt.registerLazySingleton(
    () => ChatCreateUserMessageUseCase(),
  );
}

Future<void> _loadEnv() async {
  await EnvConfig.load();
  EnvConfig.validate();
}

Dio _getDio() {
  final dio = Dio();
  dio.interceptors.add(PrettyDioLogger(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  return dio;
}

class EnvConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  static String get webSocketUrl =>
      dotenv.env['CHAT_WEBSOCKET_URL'] ?? 'ws://localhost:8000/api/chat';

  static Future<void> load() async {
    await dotenv.load();
  }

  static bool validate() {
    if (baseUrl.isEmpty || apiKey.isEmpty || webSocketUrl.isEmpty) {
      throw Exception('Missing required environment variables');
    }
    return true;
  }
}
