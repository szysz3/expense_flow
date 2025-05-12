import 'package:domain/use_case/get_messages_use_case.dart';
import 'package:domain/use_case/send_message_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../core/error/error_utils.dart';
import '../../core/widget/error_display_widget.dart';
import '../../di/di.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'widget/chat_input_field.dart';
import 'widget/chat_message_item.dart';

class ChatScreen extends StatelessWidget {
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
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => ChatBloc(
            getIt<GetMessagesUseCase>(),
            getIt<SendMessageUseCase>(),
            getIt<Logger>(),
            getIt<LocalizationService>(),
          )..add(const ChatEvent.init()),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                _buildModalHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ChatScreenView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreenView extends StatefulWidget {
  const ChatScreenView({super.key});

  @override
  State<ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<ChatScreenView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.error != null) {
          ErrorUtils.showErrorSnackBar(context, state.error!);
          context.read<ChatBloc>().add(const ChatEvent.clearError());
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildMessageList(context, state),
            ),
            const SizedBox(height: 8.0),
            ChatInputField(
              controller: _messageController,
              focusNode: _focusNode,
              onChanged: (value) {
                context.read<ChatBloc>().add(ChatEvent.messageChanged(value));
              },
              onSend: () {
                context.read<ChatBloc>().add(const ChatEvent.sendMessage());
                _messageController.clear();
                _focusNode.requestFocus();
              },
              isLoading: state.isSending,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageList(BuildContext context, ChatState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return ErrorDisplayWidget(
        error: state.error!,
        isFullScreen: true,
      );
    }

    if (state.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    const currentUser = 'User';
    return RefreshIndicator(
      onRefresh: () => context.read<ChatBloc>().refresh(),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true, // Places newest messages at the bottom
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final isCurrentUser = message.sender == currentUser;

          return ChatMessageItem(
            message: message,
            isCurrentUser: isCurrentUser,
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'packages/presentation/assets/icon_chat.svg',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start conversation',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}
