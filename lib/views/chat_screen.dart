/// ChatScreen — conversations list (one tile per store the buyer has chatted with
/// or can chat with).
///
/// Layout:
///   • AppBar "Messages" with basket shortcut action.
///   • StreamBuilder over all stores ordered by name.
///   • Each store: CircleAvatar (network image, initials fallback) + store name +
///     "Tap to start a conversation" sub-line, trailing chevron.
///   • Empty: EmptyStateView with chat-bubble icon.
///   • Loading / error states.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/chat_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Derive initials from a store name (up to 2 chars).
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
        title: Text(
          'Messages',
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Basket',
            icon: CircleAvatar(
              backgroundColor: cs.onPrimary.withValues(alpha: 0.15),
              radius: 18,
              child: Icon(Icons.shopping_basket_outlined,
                  color: cs.onPrimary, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BasketView(),
                fullscreenDialog: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: cs.secondary, height: 4),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .orderBy('store_name')
            .snapshots(),
        builder: (context, snapshot) {
          // ── Error ─────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: EmptyStateView(
                icon: Icons.cloud_off_outlined,
                headline: 'Something went wrong',
                body: 'Could not load conversations. Please try again.',
                ctaLabel: 'Retry',
                onCta: () => setState(() {}),
              ),
            );
          }

          // ── Loading ────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // ── Empty ──────────────────────────────────────────────────────────
          if (docs.isEmpty) {
            return Center(
              child: EmptyStateView(
                icon: Icons.chat_bubble_outline,
                headline: 'No conversations yet',
                body: 'Reach out to a store from any product page.',
              ),
            );
          }

          // ── List ───────────────────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 72, color: cs.outlineVariant),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final storeName = (data['store_name'] as String?) ?? 'Store';
              final imageUrl = data['store_image_url'] as String?;

              return _StoreTile(
                storeId: docs[index].id,
                storeName: storeName,
                imageUrl: imageUrl,
                initials: _initials(storeName),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatView(
                      receiverName: storeName,
                      receiverUserID: docs[index].id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Private tile widget ──────────────────────────────────────────────────────

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.storeId,
    required this.storeName,
    this.imageUrl,
    required this.initials,
    required this.onTap,
  });

  final String storeId;
  final String storeName;
  final String? imageUrl;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(imageUrl!)
                  : null,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Text(initials,
                      style: tt.labelLarge
                          ?.copyWith(color: cs.onPrimaryContainer))
                  : null,
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to start a conversation',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
