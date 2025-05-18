import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';

class ChatObserveMessagesUseCase {
  final ChatRepository _chatRepository;

  ChatObserveMessagesUseCase(this._chatRepository);

  Stream<Either<Failure, ChatMessage>> call() {
    return _chatRepository.messagesStream.map((eitherFailureOrMessage) {
      return eitherFailureOrMessage.fold(
        (failure) => Left(failure),
        (message) {
          // API returns messages in chunks and the last one always contains
          // a new line character which we don't want to display
          final trimmedContent =
              message.content.replaceAll(RegExp(r'\n+$'), '');
          return Right(message.copyWith(content: trimmedContent));
        },
      );
    });
  }
}
