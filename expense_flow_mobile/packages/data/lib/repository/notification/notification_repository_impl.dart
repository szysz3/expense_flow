import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/device_platform.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/notification_repository.dart';
import 'package:logger/logger.dart';

import '../../remote/api_endpoints.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio _dio;
  final Logger _logger;
  final Connectivity _connectivity;

  NotificationRepositoryImpl({
    required Dio dio,
    required Logger logger,
    required Connectivity connectivity,
  })  : _dio = dio,
        _logger = logger,
        _connectivity = connectivity;

  Future<Either<Failure, bool>> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left(ConnectionFailure());
      }
      return const Right(true);
    } catch (e) {
      _logger.w('Failed to check connectivity', error: e);
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, void>> registerDevice(
    String token,
    DevicePlatform platform,
  ) async {
    try {
      final connectivityCheck = await _checkConnectivity();
      if (connectivityCheck.isLeft()) {
        return Left(connectivityCheck.fold(
            (l) => l, (r) => ServerFailure('Unknown error')));
      }

      await _dio.post(
        ApiEndpoints.notificationDevices,
        data: {
          'token': token,
          'platform': platform.value,
        },
      );

      _logger.i('Device registered for notifications: $platform');
      return const Right(null);
    } on DioException catch (e) {
      _logger.e(
        'Failed to register device',
        error: e,
        stackTrace: e.stackTrace,
      );
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error registering device',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Failed to register device: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> unregisterDevice(String token) async {
    try {
      final connectivityCheck = await _checkConnectivity();
      if (connectivityCheck.isLeft()) {
        return Left(connectivityCheck.fold(
            (l) => l, (r) => ServerFailure('Unknown error')));
      }

      await _dio.delete(
        ApiEndpoints.notificationDevices,
        data: {
          'token': token,
        },
      );

      _logger.i('Device unregistered from notifications');
      return const Right(null);
    } on DioException catch (e) {
      _logger.e(
        'Failed to unregister device',
        error: e,
        stackTrace: e.stackTrace,
      );
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
      _logger.e(
        'Unexpected error unregistering device',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(
          ServerFailure('Failed to unregister device: ${e.toString()}'));
    }
  }

  Failure _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ConnectionFailure();
    }

    if (error.response == null) {
      return ConnectionFailure();
    }

    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 401:
        return UnauthorizedFailure();
      case 404:
        return NotFoundFailure();
      case 422:
        return ValidationFailure(_extractValidationErrors(error));
      default:
        return ServerFailure(
          error.response?.data?['detail']?['error'] ??
              'Server error occurred (status: $statusCode)',
        );
    }
  }

  List<Map<String, dynamic>> _extractValidationErrors(DioException error) {
    try {
      final details = error.response?.data?['detail'];
      if (details is List) {
        return details.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
