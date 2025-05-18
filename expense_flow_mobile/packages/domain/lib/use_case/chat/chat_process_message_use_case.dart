import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';

class ChatProcessMessageParams {
  final ChatMessage incomingMessage;
  final List<ChatMessage> existingMessages;

  ChatProcessMessageParams({
    required this.incomingMessage,
    required this.existingMessages,
  });
}

class ChatProcessMessageUseCase {
  const ChatProcessMessageUseCase();

  Either<Failure, List<ChatMessage>> call(ChatProcessMessageParams params) {
    final incomingMessage = params.incomingMessage;
    final existingMessages = params.existingMessages;

    final updatedMessages = List<ChatMessage>.from(existingMessages);
    final existingIndex = existingMessages.indexWhere((m) =>
        m.id == incomingMessage.id && m.sender == incomingMessage.sender);

    if (existingIndex >= 0) {
      updatedMessages[existingIndex] = incomingMessage;
    } else {
      updatedMessages.insert(0, incomingMessage);
    }

    return Right(updatedMessages);
  }
}
