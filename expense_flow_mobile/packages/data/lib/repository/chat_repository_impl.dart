import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:logger/logger.dart';
// ignore: depend_on_referenced_packages
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Logger _errorLogger;
  final Connectivity _connectivity;
  final String _webSocketUrl;
  final String? _apiKey;

  WebSocketChannel? _channel;
  StreamController<Either<Failure, ChatMessage>>? _messagesStreamController;
  StreamSubscription? _channelSubscription;

  ChatRepositoryImpl({
    required Logger errorLogger,
    required Connectivity connectivity,
    required String webSocketUrl,
    String? apiKey,
  })  : _errorLogger = errorLogger,
        _connectivity = connectivity,
        _webSocketUrl = webSocketUrl,
        _apiKey = apiKey;

  @override
  Future<Either<Failure, void>> connect() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Use ConnectionFailure for no internet
      return Left(ConnectionFailure());
    }

    if (_channel != null && _channel?.closeCode == null) {
      _errorLogger.i('Already connected or connecting.');
      return Right(null);
    }

    _messagesStreamController ??=
        StreamController<Either<Failure, ChatMessage>>.broadcast();

    try {
      _errorLogger.i('Connecting to WebSocket: $_webSocketUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));

      final keyToSend = _apiKey;
      if (keyToSend != null) {
        _errorLogger.i('Sending API key.');
        _channel!.sink.add(jsonEncode({'api_key': keyToSend}));
      }

      _channelSubscription?.cancel();
      _channelSubscription = _channel!.stream.listen(
        (data) {
          try {
            _errorLogger.d('WebSocket data received: $data');
            final jsonResponse = jsonDecode(data as String);

            if (jsonResponse is Map<String, dynamic>) {
              if (jsonResponse.containsKey('error')) {
                _errorLogger
                    .w('WebSocket error message: ${jsonResponse['error']}');
                // Use ServerFailure for errors from the WebSocket server
                _messagesStreamController?.add(
                    Left(ServerFailure(jsonResponse['error'].toString())));
              } else if (jsonResponse.containsKey('status') &&
                  jsonResponse['status'] == 'connected') {
                _errorLogger.i(
                    'WebSocket connection established: ${jsonResponse['message']}');
              } else {
                final chatMessage = ChatMessage.fromJson(jsonResponse);
                _messagesStreamController?.add(Right(chatMessage));
              }
            } else {
              _errorLogger
                  .w('Received non-map JSON from WebSocket: $jsonResponse');
              // _messagesStreamController?.add(
              //     Left(Failure.decodingFailure('Unexpected message format')));
            }
          } catch (e, s) {
            _errorLogger.e('Error parsing WebSocket message',
                error: e, stackTrace: s);
            // _messagesStreamController?.add(
            //     Left(Failure.decodingFailure('Error parsing message: $e')));
          }
        },
        onError: (error, stackTrace) {
          _errorLogger.e('WebSocket stream error',
              error: error, stackTrace: stackTrace);
          // Use ServerFailure for WebSocket stream errors
          _messagesStreamController
              ?.add(Left(ServerFailure('WebSocket error: $error')));
          _channel = null;
        },
        onDone: () {
          _errorLogger.i(
              'WebSocket connection closed by server. Close code: ${_channel?.closeCode}, reason: ${_channel?.closeReason}');
          // Use ServerFailure when connection is closed by server
          _messagesStreamController
              ?.add(Left(ServerFailure('WebSocket connection closed')));
          _channel = null;
        },
        cancelOnError: false,
      );
      return Right(null);
    } catch (e, s) {
      _errorLogger.e('Failed to connect to WebSocket', error: e, stackTrace: s);
      _channel = null;
      // Use ServerFailure for general connection failures to the WebSocket URL
      return Left(ServerFailure('Failed to connect to WebSocket: $e'));
    }
  }

  @override
  Stream<Either<Failure, ChatMessage>> get messagesStream {
    _messagesStreamController ??=
        StreamController<Either<Failure, ChatMessage>>.broadcast();
    return _messagesStreamController!.stream;
  }

  @override
  Future<Either<Failure, void>> sendMessage(String content,
      {String? conversationId}) async {
    if (_channel == null || _channel?.closeCode != null) {
      _errorLogger.w('Cannot send message, WebSocket not connected.');
      // Use ServerFailure for logical error of not being connected
      return Left(
          ServerFailure('Not connected to chat server. Please connect first.'));
    }

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Use ConnectionFailure for no internet
      return Left(ConnectionFailure());
    }

    try {
      final messagePayload = {
        'message': content,
        if (conversationId != null) 'conversation_id': conversationId,
      };
      _errorLogger.d('Sending message: ${jsonEncode(messagePayload)}');
      _channel!.sink.add(jsonEncode(messagePayload));
      return Right(null);
    } catch (e, s) {
      _errorLogger.e('Error sending message via WebSocket',
          error: e, stackTrace: s);
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  void dispose() {
    _errorLogger.i('Disposing ChatRepositoryImpl');
    _channelSubscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _messagesStreamController?.close();
    _channel = null;
    _messagesStreamController = null;
  }
}
