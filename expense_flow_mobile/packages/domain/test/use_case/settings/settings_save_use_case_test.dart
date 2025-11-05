import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/settings/settings_save_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_save_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsSaveUseCase useCase;
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SettingsSaveUseCase(repository);
  });

  test('returns repository response on success', () async {
    final settings = TestDataFactory.createSettings();

    when(repository.saveSettings(settings)).thenAnswer(
      (_) async => Right(settings),
    );

    final result = await useCase(settings);

    expect(result.isRight(), true);
    verify(repository.saveSettings(settings)).called(1);
  });

  test('propagates repository failure', () async {
    final settings = TestDataFactory.createSettings();
    const failure = ServerFailure('save failed');

    when(repository.saveSettings(settings)).thenAnswer(
      (_) async => const Left(failure),
    );

    final result = await useCase(settings);

    expect(result.isLeft(), true);
    expect(result.swap().getOrElse(() => failure), failure);
    verify(repository.saveSettings(settings)).called(1);
  });
}
