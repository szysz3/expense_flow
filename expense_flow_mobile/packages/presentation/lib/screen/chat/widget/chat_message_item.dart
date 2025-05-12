import 'package:domain/model/chat_message.dart';
import 'package:flutter/material.dart';

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
    // Widget implementation will go here
    return Container();
  }
}
