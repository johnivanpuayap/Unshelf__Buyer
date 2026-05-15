import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String type;

  const ChatBubble({
    super.key,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isSender = type == 'sender';
    final bubbleColor = isSender ? cs.primary : cs.surfaceContainerHighest;
    final textColor = isSender ? cs.onPrimary : cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bubbleColor,
      ),
      child: Text(
        message,
        style: tt.bodyMedium?.copyWith(color: textColor),
      ),
    );
  }
}
