import 'dart:async';

import 'package:dartz/dartz.dart';

import '../model/chat_message.dart';
import '../model/failure/failures.dart';

abstract class ChatRepository {
  /// Establishes connection to the chat server.
  /// An optional [apiKey] can be provided for authentication.
  Future<Either<Failure, void>> connect();

  /// Stream of incoming chat messages from the server.
  /// Listen to this stream after a successful [connect] call.
  Stream<Either<Failure, ChatMessage>> get messagesStream;

  /// Sends a chat message with the given [content].
  /// An optional [conversationId] can be provided to associate the message
  /// with a specific conversation.
  Future<Either<Failure, void>> sendMessage(String content,
      {String? conversationId});

  /// Closes the connection and releases resources.
  void dispose();
}
