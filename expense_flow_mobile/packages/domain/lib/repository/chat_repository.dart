import 'package:dartz/dartz.dart';

import '../model/chat_message.dart';
import '../model/failure/failures.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages();

  Future<Either<Failure, ChatMessage>> sendMessage(String content);
}
