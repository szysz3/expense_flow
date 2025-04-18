import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:data/utils/content_type_resolver_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/daily_expense.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/model/receipt_query.dart';
import 'package:domain/model/search_result.dart';
import 'package:domain/model/unprocessed_receipt.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/get_receipts_use_case.dart';
import 'package:logger/logger.dart';

import '../../consts/error_messages.dart';
import '../../consts/http_constants.dart';
import '../../consts/receipt_constants.dart';
import '../../remote/api_endpoints.dart';
import '../../remote/exception/exceptions.dart';
import '../../utils/content_type_resolver.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final Dio _dio;
  final RepositoryConfig _config;
  final ContentTypeResolver _contentTypeResolver;
  final Logger _errorLogger;
  final Connectivity _connectivity;

  ReceiptRepositoryImpl({
    required Dio dio,
    required RepositoryConfig config,
    required Logger errorLogger,
    required Connectivity connectivity,
    ContentTypeResolver? contentTypeResolver,
  })  : _dio = dio,
        _config = config,
        _errorLogger = errorLogger,
        _connectivity = connectivity,
        _contentTypeResolver =
            contentTypeResolver ?? ContentTypeResolverImpl() {
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
      // TODO: onConnectivityChanged should be used instead
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Left(ConnectionFailure());
      }
      return const Right(true);
    } catch (e) {
      _errorLogger.w('Failed to check connectivity', error: e);
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, Receipt>> analyzeReceipt(
    String filePath, {
    String llmType = ReceiptConstants.defaultLlmType,
  }) async {
    try {
      final connectivityCheck = await _checkConnectivity();
      if (connectivityCheck.isLeft()) {
        return Left(connectivityCheck.fold(
            (l) => l, (r) => ServerFailure('Unknown error')));
      }

      final extension = filePath.split('.').last;
      final contentType = _contentTypeResolver.resolveContentType(extension);

      final formData =
          await _createAnalyzeFormData(filePath, contentType, llmType);
      final response = await _dio.post(ApiEndpoints.analyze, data: formData);

      final responseData = response.data;
      final rawData = responseData['raw_data'];

      final transformedData = {
        'id': responseData['id'],
        'merchant': rawData['merchant'],
        'items': rawData['items'],
        'total': rawData['total'],
        'transaction_datetime': rawData['transaction_datetime'],
        'added_datetime': responseData['created_at'],
      };

      return Right(Receipt.fromJson(transformedData));
    } on DioException catch (e, stackTrace) {
      _errorLogger.e('API error during receipt analysis',
          error: e, stackTrace: stackTrace);
      return Left(_handleDioError(e));
    } catch (e) {
      _errorLogger.e('Exception during receipt analysis', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Receipt>> updateReceipt(Receipt receipt) async {
    try {
      final connectivityCheck = await _checkConnectivity();
      if (connectivityCheck.isLeft()) {
        return Left(connectivityCheck.fold(
            (l) => l, (r) => ServerFailure('Unknown error')));
      }

      final response = await _dio.put(
        '${ApiEndpoints.receipt}${receipt.id}',
        data: receipt.toJson(),
      );

      return Right(Receipt.fromJson(response.data));
    } on DioException catch (e, stackTrace) {
      _errorLogger.e('API error during receipt update',
          error: e, stackTrace: stackTrace);
      return Left(_handleDioError(e));
    } catch (e) {
      _errorLogger.e('Exception during receipt update', error: e);
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<FormData> _createAnalyzeFormData(
    String filePath,
    String contentType,
    String llmType,
  ) async {
    return FormData.fromMap({
      FormDataConstants.fileField: await MultipartFile.fromFile(
        filePath,
        contentType: DioMediaType.parse(contentType),
      ),
      FormDataConstants.llmTypeField: llmType,
    });
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
        'API error in repository',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
      _errorLogger.e(
        'Exception in repository',
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
            final details =
                (e.response!.data[ReceiptConstants.detailKey] as List)
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
  Future<Either<Failure, Receipt>> getReceipt(String id) async {
    return _executeRequest(
      () async {
        final response = await _dio.get('${ApiEndpoints.receipt}$id');
        return Receipt.fromJson(response.data);
      },
      context: 'getReceipt: $id',
    );
  }

  @override
  Future<Either<Failure, SearchResult>> searchReceipts(
      ReceiptQuery query) async {
    return _executeRequest(
      () async {
        final response = await _dio.post(
          ApiEndpoints.search,
          data: query.toJson(),
        );
        return SearchResult.fromJson(response.data);
      },
      context: 'searchReceipts',
    );
  }

  @override
  Future<Either<Failure, List<CategoryWithItems>>> getCategories() async {
    return _executeRequest(
      () async {
        final response = await _dio.get(ApiEndpoints.categories);
        return (response.data[ReceiptConstants.categoriesKey] as List)
            .map((json) => CategoryWithItems.fromJson(json))
            .toList();
      },
      context: 'getCategories',
    );
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
  Future<Either<Failure, List<MonthSummary>>> getMonthsSummary() async {
    return _executeRequest(
      () async {
        final response = await _dio.get(ApiEndpoints.monthsSummary);
        return (response.data[ReceiptConstants.monthsKey] as List)
            .map((json) => MonthSummary.fromJson(json))
            .toList();
      },
      context: 'getMonthsSummary',
    );
  }

  @override
  Future<Either<Failure, Receipt>> createReceipt({
    required ReceiptItem receiptItem,
  }) async {
    return _executeRequest(
      () async {
        final response = await _dio.post(
          ApiEndpoints.createReceipt,
          data: {
            'description': receiptItem.description,
            'quantity': receiptItem.quantity,
            'total_price': receiptItem.totalPrice,
            'category': receiptItem.category,
          },
        );
        return Receipt.fromJson(response.data[ReceiptConstants.receiptKey]);
      },
      context: 'createReceipt',
    );
  }

  @override
  Future<Either<Failure, List<DailyExpense>>> getDailyExpenses(
      int year, int month) async {
    return _executeRequest(
      () async {
        final response =
            await _dio.get(ApiEndpoints.dailyExpenses(year, month));
        return (response.data as List)
            .map((json) => DailyExpense.fromJson(json))
            .toList();
      },
      context: 'getDailyExpenses: $year-$month',
    );
  }

  @override
  Future<Either<Failure, ReceiptsResponse>> getReceipts(
      int page, int pageSize) async {
    return _executeRequest(
      () async {
        final response = await _dio.get(
          ApiEndpoints.receipts,
          queryParameters: {
            'page': page,
            'page_size': pageSize,
          },
        );

        final List<Receipt> receipts = (response.data['receipts'] as List)
            .map((json) => Receipt.fromJson(json))
            .toList();

        return ReceiptsResponse(
          receipts: receipts,
          totalCount: response.data['total_count'] ?? receipts.length,
        );
      },
      context: 'getReceipts: page $page, size $pageSize',
    );
  }

  @override
  Future<Either<Failure, bool>> deleteReceipt(String id) async {
    return _executeRequest(
      () async {
        try {
          final response = await _dio.delete('${ApiEndpoints.receipt}$id');

          if (response.statusCode == 200 && response.data['success'] == true) {
            return true;
          } else {
            throw ServerException(
                response.data['message'] ?? 'Failed to delete receipt');
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            throw NotFoundException();
          }
          rethrow;
        }
      },
      context: 'deleteReceipt: $id',
    );
  }
}
