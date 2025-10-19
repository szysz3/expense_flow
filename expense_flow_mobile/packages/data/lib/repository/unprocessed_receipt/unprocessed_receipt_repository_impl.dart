import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/unprocessed_receipt.dart';
import 'package:domain/repository/unprocessed_receipt_repository.dart';
import 'package:logger/logger.dart';

import '../../consts/error_messages.dart';
import '../../consts/http_constants.dart';
import '../../remote/api_endpoints.dart';
import '../../remote/exception/exceptions.dart';

class UnprocessedReceiptRepositoryImpl implements UnprocessedReceiptRepository {
  final Dio _dio;
  final RepositoryConfig _config;
  final Logger _errorLogger;
  final Connectivity _connectivity;

  UnprocessedReceiptRepositoryImpl({
    required Dio dio,
    required RepositoryConfig config,
    required Logger errorLogger,
    required Connectivity connectivity,
  })  : _dio = dio,
        _config = config,
        _errorLogger = errorLogger,
        _connectivity = connectivity {
    _configureDio();
  }

  void _configureDio() {
    _dio.options
      ..baseUrl = _config.baseUrl
      ..headers = {
        HttpConstants.apiKeyHeader: _config.apiKey,
        HttpConstants.acceptHeader: HttpConstants.acceptValue,
      }
      ..sendTimeout = _config.timeout
      ..receiveTimeout = _config.timeout;
  }

  Future<Either<Failure, bool>> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left(ConnectionFailure());
      }
      return const Right(true);
    } catch (e) {
      _errorLogger.w('Failed to check connectivity', error: e);
      return const Right(true);
    }
  }

  Future<Either<Failure, T>> _executeRequest<T>(
    Future<T> Function() request, {
    String? context,
  }) async {
    try {
      final connectivityCheck = await _checkConnectivity();
      if (connectivityCheck.isLeft()) {
        return Left(connectivityCheck.fold(
            (l) => l, (r) => ServerFailure('Unknown error')));
      }

      final result = await request();
      return Right(result);
    } on DioException catch (e, stackTrace) {
      _errorLogger.e(
        'API error in unprocessed receipt repository',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in unprocessed receipt repository',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case HttpConstants.statusUnauthorized:
          return UnauthorizedFailure();
        case HttpConstants.statusNotFound:
          return NotFoundFailure();
        case HttpConstants.statusValidationError:
          try {
            final details = (e.response!.data['detail'] as List)
                .cast<Map<String, dynamic>>();
            return ValidationFailure(details);
          } catch (_) {
            return ValidationFailure([
              {'msg': 'Validation error occurred'}
            ]);
          }
      }
    }

    if (_isTimeoutError(e)) {
      return ConnectionFailure();
    }

    switch (e.type) {
      case DioExceptionType.connectionError:
        return ConnectionFailure();
      case DioExceptionType.badResponse:
        return ServerFailure('Bad response from server');
      case DioExceptionType.cancel:
        return ServerFailure('Request was cancelled');
      default:
        return ServerFailure(e.message ?? ErrorMessages.unknownServerError);
    }
  }

  bool _isTimeoutError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  @override
  Future<Either<Failure, UnprocessedReceiptsResponse>>
      getUnprocessedReceipts() async {
    return _executeRequest(
      () async {
        final response = await _dio.get(ApiEndpoints.unprocessedReceipts);
        return UnprocessedReceiptsResponse.fromJson(response.data);
      },
      context: 'getUnprocessedReceipts',
    );
  }

  @override
  Future<Either<Failure, bool>> deleteUnprocessedReceipt(String id) async {
    return _executeRequest(
      () async {
        try {
          final response = await _dio.delete('/api/temp-receipts/$id');

          if (response.statusCode == 200 && response.data['success'] == true) {
            return true;
          } else {
            throw ServerException(response.data['message'] ??
                'Failed to delete unprocessed receipt');
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            throw NotFoundException();
          }
          rethrow;
        }
      },
      context: 'deleteUnprocessedReceipt: $id',
    );
  }

  @override
  Future<Either<Failure, UnprocessedReceipt>> updateUnprocessedReceipt(
      UnprocessedReceipt receipt) async {
    return _executeRequest(
      () async {
        final response = await _dio.put(
          '/api/temp-receipts/${receipt.id}',
          data: receipt.toJson(),
        );

        return UnprocessedReceipt.fromJson(response.data);
      },
      context: 'updateUnprocessedReceipt: ${receipt.id}',
    );
  }
}
