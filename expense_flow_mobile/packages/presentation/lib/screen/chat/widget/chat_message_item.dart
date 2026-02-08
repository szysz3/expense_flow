import 'package:domain/model/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:presentation/core/widget/glass_container.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) _buildAvatar(context),
          const SizedBox(width: 6),
          Flexible(
            child: GlassContainer(
              blur: 14,
              tint: isCurrentUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
              tintOpacity: isCurrentUser ? 0.28 : 0.18,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBlock(
                    data: message.content,
                    config: MarkdownConfig.darkConfig,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (isCurrentUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: isCurrentUser
          ? theme.colorScheme.primary.withValues(alpha: 0.5)
          : theme.colorScheme.secondary.withValues(alpha: 0.5),
      child: Text(
        isCurrentUser ? 'U' : 'A',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
