import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:logger/logger.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;
  final Logger _errorLogger;
  final Connectivity _connectivity;

  ChatRepositoryImpl({
    required Dio dio,
    required Logger errorLogger,
    required Connectivity connectivity,
  })  : _dio = dio,
        _errorLogger = errorLogger,
        _connectivity = connectivity;

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages() async {
    // Implementation will go here
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String content) async {
    // Implementation will go here
    throw UnimplementedError();
  }
}
