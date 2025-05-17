import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';

class GetChatMessagesStreamUseCase {
  final ChatRepository _chatRepository;

  GetChatMessagesStreamUseCase(this._chatRepository);

  Stream<Either<Failure, ChatMessage>> call() {
    final rawStream = _chatRepository.messagesStream;

    return rawStream.where((eitherFailureOrMessage) {
      if (eitherFailureOrMessage.isLeft()) {
        return true;
      }

      return eitherFailureOrMessage.fold(
          (failure) => true,
          (message) =>
              message.sender.toLowerCase() !=
              'user' // Filter user messages as they echoed back
          );
    });
  }
}
