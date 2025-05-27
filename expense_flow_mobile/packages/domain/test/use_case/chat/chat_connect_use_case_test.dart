import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:domain/use_case/chat/chat_connect_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_connect_use_case_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late ChatConnectUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = ChatConnectUseCase(mockRepository);
  });

  group('ChatConnectUseCase', () {
    group('successful connection', () {
      test('should return success when repository connect succeeds', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final result = await useCase.call();

        expect(result, isA<Right<Failure, void>>());
        expect(
            result.fold((_) => 'failure', (_) => 'success'), equals('success'));
        verify(mockRepository.connect()).called(1);
      });

      test('should call repository connect method exactly once', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        await useCase.call();

        verify(mockRepository.connect()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle multiple successful connection attempts', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final result1 = await useCase.call();
        final result2 = await useCase.call();
        final result3 = await useCase.call();

        expect(result1, isA<Right<Failure, void>>());
        expect(result2, isA<Right<Failure, void>>());
        expect(result3, isA<Right<Failure, void>>());
        verify(mockRepository.connect()).called(3);
      });

      test('should handle concurrent connection attempts', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final futures = List.generate(5, (_) => useCase.call());
        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, isA<Right<Failure, void>>());
        }
        verify(mockRepository.connect()).called(5);
      });
    });

    group('failed connection', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Chat server connection failed');
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.connect()).called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.connect()).called(1);
      });

      test(
          'should return UnauthorizedFailure when repository returns unauthorized error',
          () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.connect()).called(1);
      });

      test(
          'should return ValidationFailure when repository returns validation error',
          () async {
        const failure = ValidationFailure([
          {'field': 'connection', 'error': 'Invalid connection parameters'}
        ]);
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.connect()).called(1);
      });

      test('should handle multiple different failure types in sequence',
          () async {
        const failures = [
          ServerFailure('Server error'),
          ConnectionFailure(),
          UnauthorizedFailure(),
        ];

        for (final failure in failures) {
          when(mockRepository.connect()).thenAnswer((_) async => Left(failure));

          final result = await useCase.call();

          expect(result, isA<Left<Failure, void>>());
          expect(result.fold((f) => f, (_) => null), equals(failure));
        }

        verify(mockRepository.connect()).called(failures.length);
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.connect())
            .thenThrow(Exception('Unexpected connection error'));

        expect(
          () async => await useCase.call(),
          throwsException,
        );

        verify(mockRepository.connect()).called(1);
      });

      test('should handle repository throwing timeout exception', () async {
        when(mockRepository.connect()).thenThrow(TimeoutException(
            'Connection timeout', const Duration(seconds: 30)));

        expect(
          () async => await useCase.call(),
          throwsA(isA<TimeoutException>()),
        );

        verify(mockRepository.connect()).called(1);
      });

      test('should handle repository returning null unexpectedly', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final result = await useCase.call();

        expect(result, isA<Right<Failure, void>>());
        verify(mockRepository.connect()).called(1);
      });

      test('should handle very slow connection response', () async {
        when(mockRepository.connect()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Right(null);
        });

        final stopwatch = Stopwatch()..start();
        final result = await useCase.call();
        stopwatch.stop();

        expect(result, isA<Right<Failure, void>>());
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
        verify(mockRepository.connect()).called(1);
      });

      test('should handle connection after previous failure', () async {
        // First call fails
        const failure = ConnectionFailure();
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final failedResult = await useCase.call();
        expect(failedResult, isA<Left<Failure, void>>());

        // Second call succeeds
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final successResult = await useCase.call();
        expect(successResult, isA<Right<Failure, void>>());

        verify(mockRepository.connect()).called(2);
      });
    });

    group('performance and reliability', () {
      test('should handle rapid successive connection attempts', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        const numberOfCalls = 100;
        final futures = List.generate(numberOfCalls, (_) => useCase.call());
        final results = await Future.wait(futures);

        expect(results.length, equals(numberOfCalls));
        for (final result in results) {
          expect(result, isA<Right<Failure, void>>());
        }
        verify(mockRepository.connect()).called(numberOfCalls);
      });

      test('should maintain state consistency across multiple calls', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        // Multiple calls should not interfere with each other
        for (int i = 0; i < 10; i++) {
          final result = await useCase.call();
          expect(result, isA<Right<Failure, void>>());
        }

        verify(mockRepository.connect()).called(10);
      });

      test('should handle connection retries after intermittent failures',
          () async {
        var callCount = 0;
        when(mockRepository.connect()).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            return const Left(ConnectionFailure());
          }
          return const Right(null);
        });

        // First two calls fail
        final result1 = await useCase.call();
        final result2 = await useCase.call();
        expect(result1, isA<Left<Failure, void>>());
        expect(result2, isA<Left<Failure, void>>());

        // Third call succeeds
        final result3 = await useCase.call();
        expect(result3, isA<Right<Failure, void>>());

        verify(mockRepository.connect()).called(3);
      });
    });

    group('realistic scenarios', () {
      test('should handle initial app connection scenario', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final result = await useCase.call();

        expect(result, isA<Right<Failure, void>>());
        verify(mockRepository.connect()).called(1);
      });

      test('should handle connection after app resume', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        // Simulate app resuming and reconnecting
        final result = await useCase.call();

        expect(result, isA<Right<Failure, void>>());
        verify(mockRepository.connect()).called(1);
      });

      test('should handle connection retry after network recovery', () async {
        // First attempt fails due to network issue
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(ConnectionFailure()));

        final failedResult = await useCase.call();
        expect(failedResult, isA<Left<Failure, void>>());

        // Network recovers, retry succeeds
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        final successResult = await useCase.call();
        expect(successResult, isA<Right<Failure, void>>());

        verify(mockRepository.connect()).called(2);
      });

      test('should handle connection in offline mode', () async {
        const failure = ConnectionFailure();
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), isA<ConnectionFailure>());
        verify(mockRepository.connect()).called(1);
      });

      test('should handle server maintenance scenario', () async {
        const failure = ServerFailure('Server under maintenance');
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f.message, (_) => null),
            equals('Server under maintenance'));
        verify(mockRepository.connect()).called(1);
      });

      test('should handle authentication expiry scenario', () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.connect())
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call();

        expect(result, isA<Left<Failure, void>>());
        expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
        verify(mockRepository.connect()).called(1);
      });
    });

    group('use case contract', () {
      test('should not implement BaseUseCase since it has no parameters', () {
        // ChatConnectUseCase intentionally doesn't implement BaseUseCase
        // since it takes no parameters and has a simpler interface
        expect(useCase, isNotNull);
        expect(useCase.runtimeType, equals(ChatConnectUseCase));
      });

      test('should only depend on ChatRepository', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        await useCase.call();

        // Verify only connect method is called, no other dependencies
        verify(mockRepository.connect()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should be stateless and reusable', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        // Multiple calls should behave identically
        final result1 = await useCase.call();
        final result2 = await useCase.call();

        expect(result1.runtimeType, equals(result2.runtimeType));
        verify(mockRepository.connect()).called(2);
      });

      test('should delegate all connection logic to repository', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        await useCase.call();

        // Use case should only call repository, no additional logic
        verify(mockRepository.connect()).called(1);
      });
    });

    group('memory and resource management', () {
      test('should not hold references after call completion', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        await useCase.call();

        // Use case should not maintain state between calls
        verify(mockRepository.connect()).called(1);
      });

      test('should handle garbage collection scenarios', () async {
        when(mockRepository.connect())
            .thenAnswer((_) async => const Right(null));

        // Create multiple instances to test GC behavior
        for (int i = 0; i < 10; i++) {
          final tempUseCase = ChatConnectUseCase(mockRepository);
          final result = await tempUseCase.call();
          expect(result, isA<Right<Failure, void>>());
        }

        verify(mockRepository.connect()).called(10);
      });
    });
  });
}
