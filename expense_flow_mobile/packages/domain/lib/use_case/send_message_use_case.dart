import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _chatRepository;

  SendMessageUseCase(this._chatRepository);

  Future<Either<Failure, void>> call(SendMessageParams params) {
    return _chatRepository.sendMessage(
      params.content,
      conversationId: params.conversationId,
    );
  }
}

class SendMessageParams {
  final String content;
  final String? conversationId;

  SendMessageParams({required this.content, this.conversationId});
}
