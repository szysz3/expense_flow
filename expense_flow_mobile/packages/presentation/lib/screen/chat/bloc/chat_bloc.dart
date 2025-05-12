import 'dart:async';

import 'package:domain/model/chat_message.dart';
import 'package:domain/use_case/get_messages_use_case.dart';
import 'package:domain/use_case/send_message_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final Logger _errorLogger;
  final LocalizationService _localizationService;

  Completer<void>? _refreshCompleter;

  // Mock data for messages
  final List<ChatMessage> _mockMessages = [
    ChatMessage(
      id: '1',
      content: 'Hello! How can I help you with your expenses today?',
      sender: 'Assistant',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ChatMessage(
      id: '2',
      content: 'I\'d like to know more about my spending this month.',
      sender: 'User',
      timestamp: DateTime.now().subtract(const Duration(hours: 23)),
    ),
    ChatMessage(
      id: '3',
      content: 'Your top spending category this month is Groceries with \$320.',
      sender: 'Assistant',
      timestamp: DateTime.now().subtract(const Duration(hours: 22)),
    ),
  ];

  ChatBloc(
    this._getMessagesUseCase,
    this._sendMessageUseCase,
    this._errorLogger,
    this._localizationService,
  ) : super(const ChatState()) {
    on<InitEvent>(_onInit);
    on<RefreshEvent>(_onRefresh);
    on<MessageChangedEvent>(_onMessageChanged);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearErrorEvent>(_onClearError);
  }

  Future<void> _onInit(
    InitEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock messages
    emit(state.copyWith(
      isLoading: false,
      messages: List.from(_mockMessages),
    ));
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ChatState> emit,
  ) async {
    _refreshCompleter = Completer<void>();
    await _onInit(const InitEvent(), emit);
    _refreshCompleter?.complete();
  }

  void _onMessageChanged(
    MessageChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(currentMessage: event.message));
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentMessage.trim().isEmpty) return;

    emit(state.copyWith(isSending: true));

    // Create user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: state.currentMessage,
      sender: 'User',
      timestamp: DateTime.now(),
    );

    // Add user message to the list
    final updatedMessages = [userMessage, ...state.messages];
    emit(state.copyWith(
      messages: updatedMessages,
      currentMessage: '',
      isSending: true,
    ));

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Create mock response
    final responseMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: _generateMockResponse(state.currentMessage),
      sender: 'Assistant',
      timestamp: DateTime.now(),
    );

    // Add response to the list
    final finalMessages = [responseMessage, ...updatedMessages];
    emit(state.copyWith(
      messages: finalMessages,
      isSending: false,
    ));
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

  String _generateMockResponse(String userMessage) {
    // Simple mock responses based on user input
    final lowerCaseMessage = userMessage.toLowerCase();

    if (lowerCaseMessage.contains('hello') ||
        lowerCaseMessage.contains('hi') ||
        lowerCaseMessage.contains('hey')) {
      return 'Hello! How can I help you with your expenses today?';
    } else if (lowerCaseMessage.contains('spending') ||
        lowerCaseMessage.contains('expense') ||
        lowerCaseMessage.contains('cost')) {
      return 'Based on your recent transactions, your spending looks healthy. You\'ve spent 20% less on entertainment this month compared to last month.';
    } else if (lowerCaseMessage.contains('save') ||
        lowerCaseMessage.contains('saving')) {
      return 'You are currently saving about 15% of your income each month. That\'s a great start! Would you like some tips to increase your savings?';
    } else if (lowerCaseMessage.contains('budget') ||
        lowerCaseMessage.contains('plan')) {
      return 'Your monthly budget looks good. You\'re keeping within your limits for most categories. However, you might want to watch your grocery spending which is slightly over budget.';
    } else if (lowerCaseMessage.contains('receipt') ||
        lowerCaseMessage.contains('scan')) {
      return 'You can scan your receipts using the Scan feature in the bottom navigation. This helps track all your expenses automatically.';
    } else {
      return 'Thanks for your message. Is there anything specific about your finances you\'d like to know?';
    }
  }
}
