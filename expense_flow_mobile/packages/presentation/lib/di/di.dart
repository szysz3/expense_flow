import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:data/repository/chat_repository_impl.dart';
import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:data/repository/receipt/receipt_repository_impl.dart';
import 'package:data/repository/settings_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:domain/use_case/delete_use_case.dart';
import 'package:domain/use_case/get_autocomplete_suggestions_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_daily_expenses_use_case.dart';
import 'package:domain/use_case/get_messages_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:domain/use_case/get_receipts_use_case.dart';
import 'package:domain/use_case/send_message_use_case.dart';
import 'package:domain/use_case/settings/get_month_savings_settings_use_case.dart';
import 'package:domain/use_case/settings/get_savings_settings_use_case.dart';
import 'package:domain/use_case/settings/save_savings_settings_use_case.dart';
import 'package:domain/use_case/update_receipts_use_case.dart';
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
      dio: _getDio(),
      errorLogger: getIt<Logger>(),
      connectivity: getIt<Connectivity>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMonthsSummaryUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => AnalyzeReceiptUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => CreateReceiptUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetSavingsSettingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMonthSavingsSettingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => SaveSavingsSettingsUseCase(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetDailyExpensesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetReceiptsUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteReceiptUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerSingleton<LocalizationService>(
    LocalizationService.fromLocaleName("en"),
  );

  getIt.registerLazySingleton(
    () => UpdateReceiptUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAutocompleteSuggestionsUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMessagesUseCase(getIt<ChatRepository>()),
  );

  getIt.registerLazySingleton(
    () => SendMessageUseCase(getIt<ChatRepository>()),
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
      dotenv.env['BASE_URL'] ?? 'http://localhost:8000/';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  static Future<void> load() async {
    await dotenv.load();
  }

  static bool validate() {
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw Exception('Missing required environment variables');
    }
    return true;
  }
}
