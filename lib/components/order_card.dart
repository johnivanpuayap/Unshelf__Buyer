/// OrderCard — a single order row used in OrderHistoryView.
///
/// Shows: store avatar + name, order number, status pill,
/// item count + total price, and order date.  Tappable.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.storeImageUrl,
    required this.storeName,
    required this.orderId,
    required this.status,
    required this.itemCount,
    required this.totalPrice,
    required this.createdAt,
    required this.onTap,
  });

  final String storeImageUrl;
  final String storeName;
  final String orderId;
  final String status;
  final int itemCount;
  final double totalPrice;
  final DateTime createdAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pillColor = _statusColor(status, cs);
    final pillTextColor = _statusTextColor(status, cs);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 1,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Store row ───────────────────────────────────────────────
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: storeImageUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 40,
                      height: 40,
                      color: cs.surfaceContainerHighest,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.store_outlined,
                          color: cs.outline, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    storeName,
                    style: tt.titleSmall?.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: tt.labelSmall?.copyWith(
                      color: pillTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),

            const SizedBox(height: 10),

            // ── Meta row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${totalPrice.toStringAsFixed(2)}',
                      style: tt.titleSmall?.copyWith(
                        fontFamily: 'DM Serif Display',
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(createdAt),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status, ColorScheme cs) {
  switch (status) {
    case 'Pending':
      return cs.secondaryContainer;
    case 'Confirmed':
      return cs.primaryContainer;
    case 'Preparing':
      return cs.primaryContainer;
    case 'Ready':
      return cs.primaryContainer;
    case 'Completed':
      return cs.surfaceContainerHighest;
    case 'Cancelled':
      return cs.errorContainer;
    default:
      return cs.surfaceContainerHighest;
  }
}

Color _statusTextColor(String status, ColorScheme cs) {
  switch (status) {
    case 'Pending':
      return cs.onSecondaryContainer;
    case 'Confirmed':
    case 'Preparing':
    case 'Ready':
      return cs.onPrimaryContainer;
    case 'Completed':
      return cs.onSurface;
    case 'Cancelled':
      return cs.onErrorContainer;
    default:
      return cs.onSurface;
  }
}
