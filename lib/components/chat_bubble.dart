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
    final Color bubbleColor = (type == 'sender') ? Color(0xFF0AB68B) : const Color.fromARGB(255, 226, 226, 226);
    final Color textColor = (type == 'sender') ? Colors.white : Colors.black;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: bubbleColor,
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 16, color: textColor),
        ));
  }
}
