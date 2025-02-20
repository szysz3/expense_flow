import 'package:dartz/dartz.dart';
import 'package:data/repository/receipt/receipt_repository_config.dart';
import 'package:data/utils/content_type_resolver_impl.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/model/receipt_query.dart';
import 'package:domain/model/search_result.dart';
import 'package:domain/repository/receipt_repository.dart';

import '../../consts/error_messages.dart';
import '../../consts/http_constants.dart';
import '../../consts/receipt_constants.dart';
import '../../remote/api_endpoints.dart';
import '../../utils/content_type_resolver.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final Dio _dio;
  final RepositoryConfig _config;
  final ContentTypeResolver _contentTypeResolver;

  ReceiptRepositoryImpl({
    required Dio dio,
    required RepositoryConfig config,
    ContentTypeResolver? contentTypeResolver,
  })  : _dio = dio,
        _config = config,
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

  @override
  Future<Either<Failure, Receipt>> analyzeReceipt(
    String filePath, {
    String llmType = ReceiptConstants.defaultLlmType,
  }) async {
    try {
      final extension = filePath.split('.').last;
      final contentType = _contentTypeResolver.resolveContentType(extension);

      final formData =
          await _createAnalyzeFormData(filePath, contentType, llmType);
      final response = await _dio.post(ApiEndpoints.analyze, data: formData);

      return Right(
          Receipt.fromJson(response.data[ReceiptConstants.receiptKey]));
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
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

  @override
  Future<Either<Failure, Receipt>> getReceipt(String id) async {
    return _executeRequest(() async {
      final response = await _dio.get('${ApiEndpoints.receipt}$id');
      return Receipt.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, SearchResult>> searchReceipts(
      ReceiptQuery query) async {
    return _executeRequest(() async {
      final response = await _dio.post(
        ApiEndpoints.search,
        data: query.toJson(),
      );
      return SearchResult.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, List<CategoryWithItems>>> getCategories() async {
    return _executeRequest(() async {
      final response = await _dio.get(ApiEndpoints.categories);
      return (response.data[ReceiptConstants.categoriesKey] as List)
          .map((json) => CategoryWithItems.fromJson(json))
          .toList();
    });
  }

  @override
  Future<Either<Failure, List<MonthSummary>>> getMonthsSummary() async {
    return _executeRequest(() async {
      final response = await _dio.get(ApiEndpoints.monthsSummary);
      return (response.data[ReceiptConstants.monthsKey] as List)
          .map((json) => MonthSummary.fromJson(json))
          .toList();
    });
  }

  @override
  Future<Either<Failure, Receipt>> createReceipt({
    required ReceiptItem receiptItem,
  }) async {
    return _executeRequest(() async {
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
    });
  }

  Future<Either<Failure, T>> _executeRequest<T>(
    Future<T> Function() request,
  ) async {
    try {
      final result = await request();
      return Right(result);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e, stackTrace) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioError e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case HttpConstants.statusUnauthorized:
          return UnauthorizedFailure();
        case HttpConstants.statusNotFound:
          return NotFoundFailure();
        case HttpConstants.statusValidationError:
          return ValidationFailure(
            (e.response!.data[ReceiptConstants.detailKey] as List)
                .cast<Map<String, dynamic>>(),
          );
      }
    }

    if (_isTimeoutError(e)) {
      return ConnectionFailure();
    }

    return ServerFailure(e.message ?? ErrorMessages.unknownServerError);
  }

  bool _isTimeoutError(DioError e) {
    return e.type == DioErrorType.connectionTimeout ||
        e.type == DioErrorType.receiveTimeout ||
        e.type == DioErrorType.sendTimeout;
  }
}
