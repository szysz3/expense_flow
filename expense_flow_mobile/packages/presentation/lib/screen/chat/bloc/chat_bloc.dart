import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/use_case/chat/chat_connect_use_case.dart';
import 'package:domain/use_case/chat/chat_create_user_message_use_case.dart';
import 'package:domain/use_case/chat/chat_disconnect_use_case.dart';
import 'package:domain/use_case/chat/chat_observe_messages_use_case.dart';
import 'package:domain/use_case/chat/chat_process_message_use_case.dart';
import 'package:domain/use_case/chat/chat_send_message_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_error.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatConnectUseCase _connectUseCase;
  final ChatObserveMessagesUseCase _observeMessagesUseCase;
  final ChatSendMessageUseCase _sendMessageUseCase;
  final ChatDisconnectUseCase _disconnectUseCase;
  final ChatProcessMessageUseCase _processMessageUseCase;
  final ChatCreateUserMessageUseCase _createUserMessageUseCase;
  final Logger _logger;
  final LocalizationService _localization;

  StreamSubscription<Either<Failure, ChatMessage>>? _messagesSubscription;
  Completer<void>? _refreshCompleter;
  final String _conversationId = Uuid().v4();

  ChatBloc(
    this._connectUseCase,
    this._observeMessagesUseCase,
    this._sendMessageUseCase,
    this._disconnectUseCase,
    this._processMessageUseCase,
    this._createUserMessageUseCase,
    this._logger,
    this._localization,
  ) : super(const ChatState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<MessageChangedEvent>(_onMessageChanged);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearErrorEvent>(_onClearError);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<ConnectionStatusChangedEvent>(_onConnectionStatusChanged);
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, messages: []));

    final connectResult = await _connectUseCase.call();

    connectResult.fold(
      (failure) {
        _logger.e("Connection failed: ${failure.message}");
        _updateConnectionStatus(emit, false, failure.message);
      },
      (_) {
        _updateConnectionStatus(emit, true);
        _messagesSubscription?.cancel();
        _subscribeToMessages(emit);
      },
    );
  }

  void _subscribeToMessages(Emitter<ChatState> emit) {
    _messagesSubscription = _observeMessagesUseCase.call().listen(
      (result) {
        result.fold(
          (failure) {
            _logger.e("Error from messages stream: ${failure.message}");
            add(ChatEvent.clearError());
            add(ChatEvent.connectionStatusChanged(
                false,
                _localization.localizations
                    .chatServiceDisconnected(failure.message)));
          },
          (message) {
            add(ChatEvent.messageReceived(message));
          },
        );
      },
      onError: (error) {
        _logger.e("Critical error on messages stream: $error");
        add(ChatEvent.connectionStatusChanged(
            false,
            _localization.localizations
                .chatServiceDisconnected(error.toString())));
      },
      onDone: () {
        _logger.i("Messages stream closed.");
        add(ChatEvent.connectionStatusChanged(
            false,
            state.error == null
                ? _localization.localizations.chatConnectionClosed
                : null));
      },
    );
  }

  void _updateConnectionStatus(
    Emitter<ChatState> emit,
    bool isConnected, [
    String? errorMessage,
  ]) {
    emit(state.copyWith(
      isLoading: false,
      isSending: false,
      error: errorMessage != null ? AppError(message: errorMessage) : null,
    ));
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ChatState> emit,
  ) async {
    _refreshCompleter = Completer<void>();
    _cleanupResources();
    await _onInit(const InitEvent(), emit);
    _refreshCompleter?.complete();
  }

  void _onMessageChanged(
    MessageChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(currentMessage: event.message));
  }

  void _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final result = _processMessageUseCase(
      ChatProcessMessageParams(
        incomingMessage: event.message,
        existingMessages: state.messages,
      ),
    );

    result.fold(
      (failure) {
        _logger.e("Error processing message: ${failure.message}");
        emit(state.copyWith(error: AppError(message: failure.message)));
      },
      (updatedMessages) {
        emit(state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          isSending: false,
          error: null,
        ));
      },
    );
  }

  void _onConnectionStatusChanged(
    ConnectionStatusChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    _updateConnectionStatus(emit, event.isConnected, event.errorMessage);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final messageContent = state.currentMessage;
    if (messageContent.trim().isEmpty) return;

    emit(state.copyWith(isSending: true, error: null));

    final userMessageResult = _createUserMessageUseCase(
      ChatCreateUserMessageParams(
        content: messageContent,
        senderName: _localization.localizations.user,
      ),
    );

    userMessageResult.fold(
      (failure) {
        emit(state.copyWith(
          isSending: false,
          error: AppError(message: failure.message),
        ));
        return;
      },
      (userMessage) {
        emit(state.copyWith(
          messages: [userMessage, ...state.messages],
          currentMessage: '',
        ));

        _sendMessage(userMessage.content, emit);
      },
    );
  }

  Future<void> _sendMessage(String content, Emitter<ChatState> emit) async {
    final result = await _sendMessageUseCase.call(
      SendMessageParams(
        content: content,
        conversationId: _conversationId,
      ),
    );

    result.fold(
      (failure) {
        _logger.e("Failed to send message: ${failure.message}");
        emit(state.copyWith(
          isSending: false,
          error: AppError(message: failure.message),
        ));
      },
      (_) => emit(state.copyWith(isSending: false)),
    );
  }

  void _onClearError(
    ClearErrorEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  Future<void> refresh() async {
    add(const ChatEvent.refresh());
    return _refreshCompleter?.future;
  }

  void _cleanupResources() {
    _messagesSubscription?.cancel();
    _disconnectUseCase.call();
  }

  @override
  Future<void> close() {
    _cleanupResources();
    return super.close();
  }
}
