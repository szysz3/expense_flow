import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:data/repository/receipt/receipt_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/analyze_receipt_use_case.dart';
import 'package:domain/use_case/create_receipt_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import './di.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await EnvConfig.load();
  EnvConfig.validate();

  getIt.init();

  final dio = Dio();
  dio.interceptors.add(PrettyDioLogger(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
        dio: dio,
        config: RepositoryConfig(
          baseUrl: EnvConfig.baseUrl,
          apiKey: EnvConfig.apiKey,
        )),
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

  getIt.registerLazySingleton(() => Logger(printer: PrettyPrinter()));
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
