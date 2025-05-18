import 'package:domain/model/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_event.freezed.dart';

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.init() = InitEvent;

  const factory ChatEvent.refresh() = RefreshEvent;

  const factory ChatEvent.messageChanged(String message) = MessageChangedEvent;

  const factory ChatEvent.sendMessage() = SendMessageEvent;

  const factory ChatEvent.clearError() = ClearErrorEvent;

  const factory ChatEvent.messageReceived(ChatMessage message) =
      MessageReceivedEvent;

  const factory ChatEvent.connectionStatusChanged(bool isConnected,
      [String? errorMessage]) = ConnectionStatusChangedEvent;
}
