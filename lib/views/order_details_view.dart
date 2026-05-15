/// OrderDetailsView — full order details with status banner, sectioned cards,
/// and conditional action buttons.
///
/// Layout:
///   • AppBar: back + "Order #{id}"
///   • Status banner: pill/card showing current status with semantic colors
///   • Sections (SectionCard): store info, items, pickup details, totals
///   • Action buttons (conditional on status)
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/components/section_card.dart';
import 'package:unshelf_buyer/views/store_view.dart';
import 'package:unshelf_buyer/views/order_tracking_view.dart';

class OrderDetailsView extends StatefulWidget {
  final Map<String, dynamic> orderDetails;

  const OrderDetailsView({super.key, required this.orderDetails});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _cancelOrder() async {
    try {
      await _firestore
          .collection('orders')
          .doc(widget.orderDetails['docId'] as String?)
          .update({'status': 'Cancelled'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order cancelled.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep order'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder();
            },
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = widget.orderDetails;
    final status = d['status'] as String? ?? '';
    final orderId = d['orderId'] as String? ?? '';
    final items = d['orderItems'] as List<dynamic>? ?? [];
    final totalPrice = (d['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final pickupTime = d['pickupTime'] as DateTime?;
    final storeName = d['storeName'] as String? ?? '';
    final storeImageUrl = d['storeImageUrl'] as String? ?? '';
    final storeId = d['storeId'] as String? ?? '';
    final isPaid = d['isPaid'] as bool? ?? false;
    final pickupCode = d['pickupCode'] as String? ?? '';

    final isCancellable = status == 'Pending';
    final isActive = ['Pending', 'Confirmed', 'Preparing', 'Ready'].contains(status);
    final isCompleted = status == 'Completed';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          'Order #$orderId',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Status banner ────────────────────────────────────────────
          _StatusBanner(status: status),

          const SizedBox(height: 16),

          // ── Store info ───────────────────────────────────────────────
          SectionCard(
            child: GestureDetector(
              onTap: storeId.isNotEmpty
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreView(storeId: storeId),
                        ),
                      )
                  : null,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: storeImageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56,
                        height: 56,
                        color: cs.surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.store_outlined,
                            color: cs.outline, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeName, style: tt.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view store',
                          style: tt.bodySmall?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Items ─────────────────────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconCircle(icon: Icons.shopping_bag_outlined, cs: cs),
                    const SizedBox(width: 12),
                    Text('Items', style: tt.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(items.length, (i) {
                  final item = items[i] as Map<String, dynamic>;
                  final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                  final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                  final quantifier = item['quantifier'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item['mainImageUrl'] as String? ?? '',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 52,
                              height: 52,
                              color: cs.surfaceContainerHighest,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: cs.outline, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String? ?? '',
                                style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₱${price.toStringAsFixed(2)} / $quantifier',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '×$qty',
                              style: tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₱${(price * qty).toStringAsFixed(2)}',
                              style: tt.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Pickup details ────────────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconCircle(icon: Icons.schedule_outlined, cs: cs),
                    const SizedBox(width: 12),
                    Text('Pickup details', style: tt.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                if (pickupTime != null)
                  _DetailRow(
                    label: 'Pickup window',
                    value: DateFormat('EEE, MMM d • h:mm a').format(pickupTime),
                    cs: cs,
                    tt: tt,
                  ),
                _DetailRow(
                  label: 'Store',
                  value: storeName,
                  cs: cs,
                  tt: tt,
                ),
                if (status == 'Ready') ...[
                  const SizedBox(height: 4),
                  _DetailRow(
                    label: 'Pickup code',
                    value: pickupCode,
                    cs: cs,
                    tt: tt,
                    highlight: true,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Totals ────────────────────────────────────────────────────
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconCircle(icon: Icons.receipt_long_outlined, cs: cs),
                    const SizedBox(width: 12),
                    Text('Payment', style: tt.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                _AmountRow(
                    label: 'Subtotal', amount: totalPrice, tt: tt, cs: cs),
                const SizedBox(height: 4),
                _AmountRow(
                    label: 'Service fee', amount: 0, tt: tt, cs: cs),
                Divider(
                    height: 16, color: cs.outline.withValues(alpha: 0.3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: tt.titleSmall?.copyWith(color: cs.onSurface)),
                    Text(
                      '₱${totalPrice.toStringAsFixed(2)}',
                      style: tt.titleMedium?.copyWith(
                        fontFamily: 'DMSerifDisplay',
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment status',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? cs.primaryContainer
                            : cs.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Unpaid',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? cs.onPrimaryContainer
                              : cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Completed at / cancelled at extras ────────────────────────
          if (isCompleted && d['completedAt'] != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: _DetailRow(
                label: 'Completed',
                value: DateFormat('MMM d, yyyy HH:mm').format(
                    (d['completedAt'] as Timestamp).toDate()),
                cs: cs,
                tt: tt,
              ),
            ),
          ],
          if (status == 'Cancelled' && d['cancelledAt'] != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: _DetailRow(
                label: 'Cancelled',
                value: DateFormat('MMM d, yyyy HH:mm').format(
                    (d['cancelledAt'] as Timestamp).toDate()),
                cs: cs,
                tt: tt,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────
          if (isActive) ...[
            FilledButton.icon(
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Track order'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingView(
                      orderId: orderId,
                      status: status,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],

          if (isCancellable) ...[
            OutlinedButton.icon(
              icon: Icon(Icons.cancel_outlined, color: cs.error),
              label: Text(
                'Cancel order',
                style: TextStyle(color: cs.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.error),
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
              onPressed: _showCancelDialog,
            ),
            const SizedBox(height: 10),
          ],

          if (isCompleted) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Reorder'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reorder coming soon.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color bg;
    Color fg;
    IconData icon;
    String description;

    switch (status) {
      case 'Pending':
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        icon = Icons.hourglass_top_outlined;
        description = 'Your order is waiting to be confirmed.';
        break;
      case 'Confirmed':
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        icon = Icons.check_circle_outline;
        description = 'The store has confirmed your order.';
        break;
      case 'Preparing':
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        icon = Icons.soup_kitchen_outlined;
        description = 'Your order is being prepared.';
        break;
      case 'Ready':
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        icon = Icons.store_outlined;
        description = 'Your order is ready for pickup!';
        break;
      case 'Completed':
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        icon = Icons.check_circle_outline;
        description = 'Order picked up successfully.';
        break;
      case 'Cancelled':
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        icon = Icons.cancel_outlined;
        description = 'This order was cancelled.';
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
        icon = Icons.info_outline;
        description = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: tt.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: tt.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.cs});
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: cs.onPrimaryContainer, size: 18),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
    this.highlight = false,
  });

  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: highlight
                  ? tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: 1.4,
                    )
                  : tt.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.tt,
    required this.cs,
  });

  final String label;
  final double amount;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
