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

    // Pill-ish shape with a "tail" corner on the side the bubble originates from.
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isSender ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isSender ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: bubbleColor,
      ),
      child: Text(
        message,
        style: tt.bodyMedium?.copyWith(color: textColor),
      ),
    );
  }
}
