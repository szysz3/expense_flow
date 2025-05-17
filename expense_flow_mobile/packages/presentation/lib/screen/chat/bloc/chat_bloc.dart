import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/use_case/connect_to_chat_use_case.dart';
import 'package:domain/use_case/dispose_chat_connection_use_case.dart';
import 'package:domain/use_case/get_chat_messages_stream_use_case.dart';
import 'package:domain/use_case/send_message_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_error.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ConnectToChatUseCase _connectToChatUseCase;
  final GetChatMessagesStreamUseCase _getChatMessagesStreamUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final DisposeChatConnectionUseCase _disposeChatConnectionUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  StreamSubscription<Either<Failure, ChatMessage>>? _messagesSubscription;
  Completer<void>? _refreshCompleter;
  String _conversationId = Uuid().v4();

  ChatBloc(
    this._connectToChatUseCase,
    this._getChatMessagesStreamUseCase,
    this._sendMessageUseCase,
    this._disposeChatConnectionUseCase,
    this._errorLogger,
    this._localizationService,
  ) : super(const ChatState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<MessageChangedEvent>(_onMessageChanged);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearErrorEvent>(_onClearError);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<ConnectionStatusChangedEvent>(_onConnectionStatusChanged);

    add(const InitEvent());
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, messages: []));

    final connectResult = await _connectToChatUseCase.call();

    connectResult.fold(
      (failure) {
        _errorLogger.e("Connection failed: ${failure.message}");
        _handleConnectionStatusChange(emit, false,
            errorMessage: _mapFailureToMessage(failure));
      },
      (_) {
        _errorLogger
            .i("Connection attempt successful, listening for messages.");
        _handleConnectionStatusChange(emit, true);
        _messagesSubscription?.cancel();

        // Listen to the message stream
        _messagesSubscription = _getChatMessagesStreamUseCase.call().listen(
          (eitherMessageOrFailure) {
            eitherMessageOrFailure.fold(
              (failure) {
                _errorLogger
                    .e("Error from messages stream: ${failure.message}");
                add(ChatEvent.clearError());
                add(ChatEvent.connectionStatusChanged(false,
                    _mapFailureToMessage(failure, 'Chat service error.')));
              },
              (message) {
                _errorLogger.d("Message received from stream: ${message.id}");
                // Use the MessageReceivedEvent which will be handled by _onMessageReceived
                add(ChatEvent.messageReceived(message));
              },
            );
          },
          onError: (error) {
            _errorLogger.e("Critical error on messages stream: $error");
            add(ChatEvent.connectionStatusChanged(
                false, 'Chat service disconnected: $error'));
          },
          onDone: () {
            _errorLogger.i("Messages stream closed.");
            if (state.error == null) {
              add(ChatEvent.connectionStatusChanged(
                  false, 'Chat connection closed.'));
            } else {
              add(ChatEvent.connectionStatusChanged(false));
            }
          },
        );
      },
    );
  }

  void _handleConnectionStatusChange(Emitter<ChatState> emit, bool isConnected,
      {String? errorMessage}) {
    if (!isConnected && errorMessage != null) {
      emit(state.copyWith(
          isLoading: false,
          isSending: false,
          error: AppError(
              // Removed 'title'
              // title: _localizationService.translate('chat_connection_error_title') ?? 'Connection Error',
              message: errorMessage)));
    } else if (isConnected) {
      emit(state.copyWith(isLoading: false, error: null));
    } else {
      // Connected is false, but no specific error message (e.g. onDone from stream without prior error)
      emit(state.copyWith(isLoading: false, isSending: false));
    }
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ChatState> emit,
  ) async {
    _refreshCompleter = Completer<void>();
    _messagesSubscription?.cancel();
    _disposeChatConnectionUseCase.call();
    await _onInit(const InitEvent(), emit);
    _refreshCompleter?.complete();
  }

  void _onMessageChanged(
    MessageChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(currentMessage: event.message));
  }

  // Add these handlers to your ChatBloc class
  void _onMessageReceived(
    MessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final incomingMessage = event.message;

    // Find if we already have a message with the same ID
    final existingMessageIndex = state.messages.indexWhere((m) =>
        m.id == incomingMessage.id && m.sender == incomingMessage.sender);

    List<ChatMessage> updatedMessages;

    if (existingMessageIndex >= 0) {
      // We found an existing message with the same ID - update it
      _errorLogger.d("Updating existing message: ${incomingMessage.id}");
      updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[existingMessageIndex] = incomingMessage;
    } else {
      // This is a new message, add it to the list
      _errorLogger.d("Adding new message: ${incomingMessage.id}");
      updatedMessages = [incomingMessage, ...state.messages];
    }

    emit(state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        isSending: false,
        error: null));
  }

  void _onConnectionStatusChanged(
    ConnectionStatusChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    if (!event.isConnected && event.errorMessage != null) {
      emit(state.copyWith(
          isLoading: false,
          isSending: false,
          error: AppError(message: event.errorMessage ?? "ERror")));
    } else if (event.isConnected) {
      emit(state.copyWith(isLoading: false, error: null));
    } else {
      // Connected is false, but no specific error message
      emit(state.copyWith(isLoading: false, isSending: false));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final messageContent = state.currentMessage.trim();
    if (messageContent.isEmpty) return;

    emit(state.copyWith(isSending: true, error: null));

    final userMessage = ChatMessage(
      id: Uuid().v4(), // Make sure each message has a unique ID
      content: messageContent,
      sender: 'User',
      timestamp: DateTime.now(),
    );

    final optimisticMessages = [userMessage, ...state.messages];
    emit(state.copyWith(
      messages: optimisticMessages,
      currentMessage: '',
    ));

    final result = await _sendMessageUseCase.call(
      SendMessageParams(
        content: messageContent,
        conversationId: _conversationId,
      ),
    );

    result.fold(
      (failure) {
        _errorLogger.e("Failed to send message: ${failure.message}");
        emit(state.copyWith(
          isSending: false,
          error: AppError(
            message: _mapFailureToMessage(failure, 'Could not send message.'),
          ),
        ));
      },
      (_) {
        _errorLogger.i("Message sent successfully via use case.");
        emit(state.copyWith(isSending: false));
      },
    );
  }

  void _onClearError(
    ClearErrorEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  String _mapFailureToMessage(Failure failure, [String? defaultMessage]) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is ConnectionFailure) {
      return failure.message;
    }
    return defaultMessage ?? failure.message ?? 'An unknown error occurred.';
  }

  Future<void> refresh() async {
    add(const ChatEvent.refresh());
    return _refreshCompleter?.future;
  }

  @override
  Future<void> close() {
    _errorLogger.i('Closing ChatBloc and disposing resources.');
    _messagesSubscription?.cancel();
    _disposeChatConnectionUseCase.call();
    return super.close();
  }
}
