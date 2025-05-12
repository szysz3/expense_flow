import 'dart:async';

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
    // Implementation will go here
  }

  Future<void> _onRefresh(
    RefreshEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Implementation will go here
  }

  void _onMessageChanged(
    MessageChangedEvent event,
    Emitter<ChatState> emit,
  ) {
    // Implementation will go here
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Implementation will go here
  }

  void _onClearError(
    ClearErrorEvent event,
    Emitter<ChatState> emit,
  ) {
    // Implementation will go here
  }

  Future<void> refresh() async {
    add(const ChatEvent.refresh());
    return _refreshCompleter?.future;
  }
}
