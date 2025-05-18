import 'package:domain/model/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default('') String currentMessage,
    @Default(false) bool isLoading,
    @Default(false) bool isSending,
    AppError? error,
  }) = _ChatState;
}
