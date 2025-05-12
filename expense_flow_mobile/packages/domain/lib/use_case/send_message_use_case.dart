import 'package:dartz/dartz.dart';

import '../../model/chat_message.dart';
import '../../model/failure/failures.dart';
import '../../repository/chat_repository.dart';
import 'base/base_use_case.dart';

class SendMessageParams {
  final String content;

  SendMessageParams({required this.content});
}

class SendMessageUseCase
    implements BaseUseCase<SendMessageParams, Either<Failure, ChatMessage>> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return await repository.sendMessage(params.content);
  }
}
