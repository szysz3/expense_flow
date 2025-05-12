import 'package:dartz/dartz.dart';

import '../../model/chat_message.dart';
import '../../model/failure/failures.dart';
import '../../repository/chat_repository.dart';
import 'base/base_use_case.dart';

class GetMessagesUseCase
    implements BaseUseCase<NoParams, Either<Failure, List<ChatMessage>>> {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(NoParams params) async {
    return await repository.getMessages();
  }
}
