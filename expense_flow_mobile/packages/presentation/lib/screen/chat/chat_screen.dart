import 'package:domain/use_case/connect_to_chat_use_case.dart';
import 'package:domain/use_case/dispose_chat_connection_use_case.dart';
import 'package:domain/use_case/get_chat_messages_stream_use_case.dart';
import 'package:domain/use_case/send_message_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../di/di.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'widget/chat_input_field.dart';
import 'widget/chat_message_item.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatScreen(),
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(
        getIt<ConnectToChatUseCase>(),
        getIt<GetChatMessagesStreamUseCase>(),
        getIt<SendMessageUseCase>(),
        getIt<DisposeChatConnectionUseCase>(),
        getIt<Logger>(),
        getIt<LocalizationService>(),
      )..add(const ChatEvent.init()),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: MediaQuery.of(context).padding.top +
              40, // Space for modal drag handle and status bar
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Column(
              children: [
                _buildModalHeader(context),
                Expanded(
                  child: BlocConsumer<ChatBloc, ChatState>(
                    listener: (context, state) {
                      if (state.error != null) {
                        ErrorUtils.showErrorSnackBar(
                          context,
                          state.error!,
                        );
                      }
                      // If currentMessage in state is empty (e.g., after sending), clear controller
                      if (state.currentMessage.isEmpty &&
                          _textController.text.isNotEmpty) {
                        _textController.clear();
                      }
                    },
                    builder: (context, state) {
                      if (state.isLoading && state.messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.messages.isEmpty && !state.isLoading) {
                        return Center(
                          child: Text(
                            "No messages yet",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final isCurrentUser = message.sender == 'User';
                          return ChatMessageItem(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            onTap: () {
                              // Handle message tap if needed, e.g., copy text
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  // Rebuild ChatInputField only when isSending or currentMessage changes
                  // currentMessage is used to potentially update the controller if needed externally
                  // but primarily, controller drives the input field's text.
                  buildWhen: (previous, current) =>
                      previous.isSending != current.isSending ||
                      previous.currentMessage != current.currentMessage,
                  builder: (context, state) {
                    return ChatInputField(
                      controller: _textController,
                      focusNode: _focusNode,
                      onChanged: (message) => context
                          .read<ChatBloc>()
                          .add(ChatEvent.messageChanged(message)),
                      onSend: () {
                        context
                            .read<ChatBloc>()
                            .add(const ChatEvent.sendMessage());
                        // Optionally, keep focus or dismiss keyboard
                        // _focusNode.requestFocus();
                      },
                      isLoading: state.isSending,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Optionally, add a title or close button here
        ],
      ),
    );
  }
}
