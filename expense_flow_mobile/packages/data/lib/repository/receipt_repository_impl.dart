import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_query.dart';
import 'package:domain/model/search_result.dart';
import 'package:domain/repository/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final Dio dio;
  final String baseUrl;
  final String apiKey;

  ReceiptRepositoryImpl({
    required this.dio,
    required this.baseUrl,
    required this.apiKey,
  }) {
    dio.options.baseUrl = baseUrl;
    dio.options.headers = {
      'X-API-Key': apiKey,
      'accept': 'application/json',
    };
  }

  @override
  Future<Either<Failure, Receipt>> analyzeReceipt(String filePath,
      {String llmType = 'local'}) async {
    try {
      // Determine content type based on file extension
      final extension = filePath.split('.').last.toLowerCase();
      final contentType = _getContentType(extension);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          contentType: DioMediaType.parse(contentType), // Add content type
        ),
        'llm_type': llmType,
      });

      final response = await dio.post(
        '/api/receipts/analyze',
        data: formData,
      );

      final receipt = Receipt.fromJson(response.data['receipt']);

      return Right(receipt);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        throw ValidationFailure([
          {'msg': 'Unsupported file type'}
        ]);
    }
  }

  @override
  Future<Either<Failure, Receipt>> getReceipt(String id) async {
    try {
      final response = await dio.get('/api/receipts/$id');
      final receipt = Receipt.fromJson(response.data);
      return Right(receipt);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SearchResult>> searchReceipts(
      ReceiptQuery query) async {
    try {
      final response = await dio.post(
        '/api/receipts/search',
        data: query.toJson(),
      );

      final searchResult = SearchResult.fromJson(response.data);
      return Right(searchResult);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CategoryWithItems>>> getCategories() async {
    try {
      final response = await dio.get('/api/categories');

      final categories = (response.data['categories'] as List)
          .map((json) => CategoryWithItems.fromJson(json))
          .toList();

      return Right(categories);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthSummary>>> getMonthsSummary() async {
    try {
      final response = await dio.get('/api/months/summary');

      final summaries = (response.data['months'] as List)
          .map((json) => MonthSummary.fromJson(json))
          .toList();

      return Right(summaries);
    } on DioError catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioError e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case 403:
          return UnauthorizedFailure();
        case 404:
          return NotFoundFailure();
        case 422:
          return ValidationFailure((e.response!.data['detail'] as List)
              .cast<Map<String, dynamic>>());
      }
    }

    if (e.type == DioErrorType.connectionTimeout ||
        e.type == DioErrorType.receiveTimeout ||
        e.type == DioErrorType.sendTimeout) {
      return ConnectionFailure();
    }

    return ServerFailure(e.message ?? 'Unknown server error');
  }
}
