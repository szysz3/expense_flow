import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:data/repository/chat/chat_repository_config.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/chat_repository.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRepositoryConfig _config;
  final Logger _logger;
  final Connectivity _connectivity;

  WebSocketChannel? _channel;
  late var _messagesController =
      StreamController<Either<Failure, ChatMessage>>.broadcast();
  StreamSubscription? _channelSubscription;

  bool get _isConnected => _channel != null && _channel?.closeCode == null;

  ChatRepositoryImpl({
    required ChatRepositoryConfig config,
    required Logger logger,
    required Connectivity connectivity,
  })  : _config = config,
        _logger = logger,
        _connectivity = connectivity;

  @override
  Future<Either<Failure, void>> connect() async {
    if (_isConnected) {
      _logger.i('Already connected to WebSocket server.');
      return const Right(null);
    }

    if (_messagesController.isClosed) {
      _logger.i('Reinitializing closed stream controller');
      _messagesController =
          StreamController<Either<Failure, ChatMessage>>.broadcast();
    }

    if (await _hasNoConnectivity()) {
      return Left(ConnectionFailure());
    }

    try {
      _logger.i('Connecting to WebSocket: ${_config.webSocketUrl}');
      _channel = WebSocketChannel.connect(Uri.parse(_config.webSocketUrl));
      _channel!.sink.add(jsonEncode({'api_key': _config.apiKey}));

      await _setupChannelListener();

      return const Right(null);
    } catch (e, s) {
      _logger.e('Failed to connect to WebSocket', error: e, stackTrace: s);
      _channel = null;
      return Left(ServerFailure('Failed to connect: $e'));
    }
  }

  Future<void> _setupChannelListener() async {
    await _channelSubscription?.cancel();

    _channelSubscription = _channel!.stream.listen(
      _handleIncomingMessage,
      onError: _handleStreamError,
      onDone: _handleStreamClosed,
      cancelOnError: false,
    );
  }

  @override
  Stream<Either<Failure, ChatMessage>> get messagesStream =>
      _messagesController.stream;

  @override
  Future<Either<Failure, void>> sendMessage(String content,
      {String? conversationId}) async {
    if (!_isConnected) {
      _logger.w('Cannot send message, WebSocket not connected.');
      return Left(
          ServerFailure('Not connected to chat server. Please connect first.'));
    }

    if (await _hasNoConnectivity()) {
      return Left(ConnectionFailure());
    }

    try {
      final messagePayload = {
        'message': content,
        if (conversationId != null) 'conversation_id': conversationId,
      };

      _logger.d('Sending message: ${jsonEncode(messagePayload)}');
      _channel!.sink.add(jsonEncode(messagePayload));
      return const Right(null);
    } catch (e, s) {
      _logger.e('Error sending message', error: e, stackTrace: s);
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  void dispose() {
    _logger.i('Disposing ChatRepositoryImpl');

    _channelSubscription?.cancel();
    _channelSubscription = null;

    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    if (!_messagesController.isClosed) {
      _messagesController.close();
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      _logger.d('WebSocket data received: $data');

      if (_messagesController.isClosed) {
        _logger.w('Stream controller is closed, ignoring incoming message');
        return;
      }

      final jsonResponse = jsonDecode(data as String);

      if (jsonResponse is! Map<String, dynamic>) {
        _logger.w('Received invalid JSON from WebSocket: $jsonResponse');
        return;
      }

      if (jsonResponse.containsKey('error')) {
        _logger.w('WebSocket error message: ${jsonResponse['error']}');
        _messagesController
            .add(Left(ServerFailure(jsonResponse['error'].toString())));
        return;
      }

      if (jsonResponse.containsKey('status') &&
          jsonResponse['status'] == 'connected') {
        _logger
            .i('WebSocket connection established: ${jsonResponse['message']}');
        return;
      }

      final chatMessage = ChatMessage.fromJson(jsonResponse);
      _messagesController.add(Right(chatMessage));
    } catch (e, s) {
      _logger.e('Error parsing WebSocket message', error: e, stackTrace: s);
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    _logger.e('WebSocket stream error', error: error, stackTrace: stackTrace);
    _messagesController.add(Left(ServerFailure('WebSocket error: $error')));
    _channel = null;
  }

  void _handleStreamClosed() {
    _logger.i(
        'WebSocket connection closed. Code: ${_channel?.closeCode}, reason: ${_channel?.closeReason}');
    _messagesController.add(Left(ServerFailure('WebSocket connection closed')));
    _channel = null;
  }

  Future<bool> _hasNoConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.none);
  }
}
