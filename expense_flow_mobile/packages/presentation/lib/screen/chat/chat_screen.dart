import 'package:domain/use_case/chat/chat_connect_use_case.dart';
import 'package:domain/use_case/chat/chat_create_user_message_use_case.dart';
import 'package:domain/use_case/chat/chat_disconnect_use_case.dart';
import 'package:domain/use_case/chat/chat_observe_messages_use_case.dart';
import 'package:domain/use_case/chat/chat_process_message_use_case.dart';
import 'package:domain/use_case/chat/chat_send_message_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
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
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _initChatBloc();
  }

  void _initChatBloc() {
    _chatBloc = _createChatBloc();
  }

  @override
  void dispose() {
    _chatBloc.close();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _chatBloc,
      child: _buildChatModal(context),
    );
  }

  ChatBloc _createChatBloc() {
    return ChatBloc(
      getIt<ChatConnectUseCase>(),
      getIt<ChatObserveMessagesUseCase>(),
      getIt<ChatSendMessageUseCase>(),
      getIt<ChatDisconnectUseCase>(),
      getIt<ChatProcessMessageUseCase>(),
      getIt<ChatCreateUserMessageUseCase>(),
      getIt<Logger>(),
      getIt<LocalizationService>(),
    )..add(const ChatEvent.init());
  }

  Widget _buildChatModal(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildModalHeader(context),
                Expanded(
                  child: _buildMessageList(),
                ),
                _buildInputField(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
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
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.messages.isEmpty && !state.isLoading) {
          return Center(
            child: Text(
              AppLocalizations.of(context).noMessagesYet,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8.0),
          itemCount: state.messages.length,
          itemBuilder: (context, index) => _buildMessageItem(context, index),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, ChatState state) {
    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }

    if (state.currentMessage.isEmpty && _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    final message = context.read<ChatBloc>().state.messages[index];
    final isCurrentUser = message.sender == AppLocalizations.of(context).user;

    return ChatMessageItem(
      message: message,
      isCurrentUser: isCurrentUser,
      onTap: () {
        // actions on message bubble not available yet
      },
    );
  }

  Widget _buildInputField() {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (previous, current) =>
          previous.isSending != current.isSending ||
          previous.currentMessage != current.currentMessage,
      builder: (context, state) {
        return ChatInputField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: (message) =>
              context.read<ChatBloc>().add(ChatEvent.messageChanged(message)),
          onSend: () => _sendMessage(context),
          isLoading: state.isSending,
        );
      },
    );
  }

  void _sendMessage(BuildContext context) {
    context.read<ChatBloc>().add(const ChatEvent.sendMessage());
  }
}
