import 'package:domain/repository/chat_repository.dart';

class DisposeChatConnectionUseCase {
  final ChatRepository _chatRepository;

  DisposeChatConnectionUseCase(this._chatRepository);

  void call() {
    _chatRepository.dispose();
  }
}
