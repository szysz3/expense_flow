import 'package:domain/repository/chat_repository.dart';

class ChatDisconnectUseCase {
  final ChatRepository _chatRepository;

  ChatDisconnectUseCase(this._chatRepository);

  void call() {
    _chatRepository.dispose();
  }
}
