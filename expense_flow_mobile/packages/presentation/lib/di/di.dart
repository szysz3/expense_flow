import 'package:data/repository/receipt_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

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
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      dio: Dio(),
      baseUrl: EnvConfig.baseUrl,
      apiKey: EnvConfig.apiKey,
    ),
  );

  getIt.registerLazySingleton(
    () => GetCategoriesUseCase(getIt<ReceiptRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetMonthsSummaryUseCase(getIt<ReceiptRepository>()),
  );
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
