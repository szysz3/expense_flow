import 'dart:async';

import 'package:dartz/dartz.dart';

import '../model/chat_message.dart';
import '../model/failure/failures.dart';

abstract class ChatRepository {
  Future<Either<Failure, void>> connect();

  Stream<Either<Failure, ChatMessage>> get messagesStream;

  Future<Either<Failure, void>> sendMessage(String content,
      {String? conversationId});

  void dispose();
}
