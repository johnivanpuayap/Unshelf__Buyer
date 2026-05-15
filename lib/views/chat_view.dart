/// ChatView — single conversation between the buyer and a store.
///
/// Layout:
///   • AppBar: back + store name + small avatar in leading area.
///   • Reversed ListView of chat bubbles (existing ChatBubble component).
///     Outgoing: primary green, right-aligned.
///     Incoming: surfaceContainerHighest, left-aligned.
///   • Bottom composer: themed TextField + send IconButton.
///   • Empty state: centred hint "Send a message to start the conversation."
///   • Loading / error states.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/chat_bubble.dart';
import 'package:unshelf_buyer/services/chat_service.dart';

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.receiverName,
    required this.receiverUserID,
  });

  final String receiverName;
  final String receiverUserID;

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    _messageController.clear();
    await _chatService.sendMessage(widget.receiverUserID, text);
    setState(() => _isSending = false);
  }

  // Initials fallback for the small AppBar avatar.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
              child: Text(
                _initials(widget.receiverName),
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverName,
                style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: cs.secondary, height: 4),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(cs, tt)),
          _buildComposer(cs, tt),
          // Extra bottom inset so composer clears the system nav bar.
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────────────

  Widget _buildMessageList(ColorScheme cs, TextTheme tt) {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(
        widget.receiverUserID,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load messages.',
                style: tt.bodyMedium?.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No messages yet',
                    style: tt.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send a message to start the conversation.',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Reversed so latest message is at bottom.
        final reversedDocs = docs.reversed.toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: reversedDocs.length,
          itemBuilder: (context, index) {
            final data =
                reversedDocs[index].data() as Map<String, dynamic>;
            final isMe =
                data['senderId'] == _firebaseAuth.currentUser!.uid;
            return _MessageRow(
              message: data['message'] as String? ?? '',
              isMe: isMe,
            );
          },
        );
      },
    );
  }

  // ── Composer ─────────────────────────────────────────────────────────────

  Widget _buildComposer(ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: tt.bodyMedium
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.45)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Material(
            color: cs.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isSending ? null : _sendMessage,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary),
                      )
                    : Icon(Icons.send_rounded,
                        color: cs.onPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message row helper ───────────────────────────────────────────────────────

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.isMe});

  final String message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 4),
          ChatBubble(
            message: message,
            type: isMe ? 'sender' : 'receiver',
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
