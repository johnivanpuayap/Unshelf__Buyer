/// ProductCard — vertical card used in the "Expiring soon" section of the
/// home view and anywhere the app lists individual products.
///
/// Shows a product thumbnail, name, store name, discounted price,
/// struck-through original price, and an expiry badge.  Tapping the card
/// navigates to [ProductPage].
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
  });

  final String productId;
  final String name;
  final double price;
  final int discount;
  final DateTime expiryDate;
  final String? mainImageUrl;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final discountedPrice = price * (1 - discount / 100);
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    final expiryLabel = daysUntilExpiry <= 0
        ? 'Expires today'
        : daysUntilExpiry == 1
            ? 'Expires tomorrow'
            : 'Expires in $daysUntilExpiry days';

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
                child: (mainImageUrl != null && mainImageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: mainImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: cs.outline.withValues(alpha: 0.12),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.outline.withValues(alpha: 0.12),
                          child: Icon(Icons.image_not_supported_outlined,
                              color: cs.outline),
                        ),
                      )
                    : Container(color: cs.outline.withValues(alpha: 0.12)),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
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
                    // Expiry badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
