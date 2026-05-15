/// ProductCard — card used throughout the buyer app to surface an individual
/// product.
///
/// Two layout modes:
///   • Default (row): wide thumbnail on the left, details on the right.
///     Used in the "Expiring soon" home section.
///   • Compact (grid): thumbnail fills the top, details below.
///     Used in category / search / store product grids (2-column).
///
/// Use [ProductCard.compact] to build the grid variant.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/product_view.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.discount,
    required this.expiryDate,
    this.mainImageUrl,
    this.storeName,
  }) : _compact = false;

  /// Grid / compact variant — square thumbnail above, info below.
  const ProductCard.compact({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.discount,
    required this.expiryDate,
    this.mainImageUrl,
    this.storeName,
  }) : _compact = true;

  final String productId;
  final String name;
  final double price;
  final int discount;
  final DateTime expiryDate;
  final String? mainImageUrl;
  final String? storeName;
  final bool _compact;

  @override
  Widget build(BuildContext context) {
    return _compact ? _buildCompact(context) : _buildRow(context);
  }

  Widget _buildRow(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final discountedPrice = price * (1 - discount / 100);
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    final expiryLabel = _expiryLabel(daysUntilExpiry);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductPage(productId: productId)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _thumbnail(cs),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _details(tt, cs, discountedPrice, daysUntilExpiry, expiryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final discountedPrice = price * (1 - discount / 100);
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    final expiryLabel = _expiryLabel(daysUntilExpiry);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductPage(productId: productId)),
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1,
                child: _thumbnail(cs),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: tt.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (storeName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      storeName!,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'PHP ${discountedPrice.toStringAsFixed(2)}',
                    style: tt.labelLarge?.copyWith(color: cs.primary),
                  ),
                  if (discount > 0) ...[
                    Text(
                      'PHP ${price.toStringAsFixed(2)}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _expiryBadge(tt, cs, daysUntilExpiry, expiryLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(ColorScheme cs) {
    if (mainImageUrl != null && mainImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: mainImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: cs.outline.withValues(alpha: 0.12)),
        errorWidget: (_, __, ___) => Container(
          color: cs.outline.withValues(alpha: 0.12),
          child: Icon(Icons.image_not_supported_outlined, color: cs.outline),
        ),
      );
    }
    return Container(color: cs.outline.withValues(alpha: 0.12));
  }

  Widget _details(
    TextTheme tt,
    ColorScheme cs,
    double discountedPrice,
    int daysUntilExpiry,
    String expiryLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: tt.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (storeName != null) ...[
          const SizedBox(height: 2),
          Text(
            storeName!,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'PHP ${discountedPrice.toStringAsFixed(2)}',
              style: tt.titleSmall?.copyWith(color: cs.primary),
            ),
            if (discount > 0) ...[
              const SizedBox(width: 6),
              Text(
                'PHP ${price.toStringAsFixed(2)}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _expiryBadge(tt, cs, daysUntilExpiry, expiryLabel),
      ],
    );
  }

  Widget _expiryBadge(
      TextTheme tt, ColorScheme cs, int daysUntilExpiry, String expiryLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        expiryLabel,
        style: tt.labelSmall?.copyWith(
          color: daysUntilExpiry <= 1
              ? cs.error
              : cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _expiryLabel(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return 'Expires today';
    if (daysUntilExpiry == 1) return 'Expires tomorrow';
    return 'Expires in $daysUntilExpiry days';
  }
}
