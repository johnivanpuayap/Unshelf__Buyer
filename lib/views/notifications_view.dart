import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/section_header.dart';

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

enum _NotificationType { order, product, store, general }

class _NotificationItem {
  const _NotificationItem({
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  final _NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  // TODO(data-layer): add routeId field once Firestore notifications are wired.
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  // Placeholder — replace with a Riverpod stream once the data layer is ready.
  // TODO(data-layer): wire to Firestore notifications collection.
  List<_NotificationItem> _loadNotifications() => const [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final all = _loadNotifications();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Notifications', style: tt.titleLarge),
      ),
      body: SafeArea(
        child: all.isEmpty
            ? _buildEmptyState()
            : _buildGroupedList(context, all),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
    );
  }

  Widget _buildEmptyState() => const Center(
        child: EmptyStateView(
          icon: Icons.notifications_none_outlined,
          headline: 'No notifications yet',
          body:
              "We'll let you know when stores have new listings or your orders update.",
        ),
      );

  Widget _buildGroupedList(BuildContext context, List<_NotificationItem> items) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final today = items
        .where((n) => n.timestamp.isAfter(todayStart))
        .toList();
    final thisWeek = items
        .where((n) =>
            n.timestamp.isAfter(weekStart) &&
            !n.timestamp.isAfter(todayStart))
        .toList();
    final earlier = items
        .where((n) => !n.timestamp.isAfter(weekStart))
        .toList();

    return ListView(
      children: [
        if (today.isNotEmpty) ...[
          const SectionHeader(title: 'Today'),
          ...today.map((n) => _NotificationTile(item: n)),
        ],
        if (thisWeek.isNotEmpty) ...[
          const SectionHeader(title: 'This week'),
          ...thisWeek.map((n) => _NotificationTile(item: n)),
        ],
        if (earlier.isNotEmpty) ...[
          const SectionHeader(title: 'Earlier'),
          ...earlier.map((n) => _NotificationTile(item: n)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notification tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final _NotificationItem item;

  IconData _iconFor(_NotificationType type) => switch (type) {
        _NotificationType.order => Icons.receipt_long_outlined,
        _NotificationType.product => Icons.inventory_2_outlined,
        _NotificationType.store => Icons.store_outlined,
        _NotificationType.general => Icons.info_outline,
      };

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleTap(BuildContext context) {
    // TODO(data-layer): navigate to order / product / store detail using
    // item.routeId when routes are wired.
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF1F2A20).withValues(alpha: 0.06),
                offset: const Offset(0, 8),
                blurRadius: 28,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(item.type),
                    size: 20,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: tt.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing timestamp
                Text(
                  _formatTimestamp(item.timestamp),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
