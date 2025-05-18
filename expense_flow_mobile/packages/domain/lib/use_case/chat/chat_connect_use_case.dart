import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';

class ChatConnectUseCase {
  final ChatRepository _chatRepository;

  ChatConnectUseCase(this._chatRepository);

  Future<Either<Failure, void>> call() {
    return _chatRepository.connect();
  }
}
