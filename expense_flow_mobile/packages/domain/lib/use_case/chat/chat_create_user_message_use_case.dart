import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:uuid/uuid.dart';

class ChatCreateUserMessageParams {
  final String content;
  final String senderName;

  ChatCreateUserMessageParams({
    required this.content,
    required this.senderName,
  });
}

class ChatCreateUserMessageUseCase {
  const ChatCreateUserMessageUseCase();

  Either<Failure, ChatMessage> call(ChatCreateUserMessageParams params) {
    if (params.content.trim().isEmpty) {
      return Left(ValidationFailure([
        {"msg": "Message content cannot be empty"}
      ]));
    }

    final userMessage = ChatMessage(
      id: Uuid().v4(),
      content: params.content.trim(),
      sender: params.senderName,
      timestamp: DateTime.now(),
    );

    return Right(userMessage);
  }
}
