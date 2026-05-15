/// BasketRow — a single item row inside the basket screen.
///
/// Shows: product thumbnail (64×64 rounded), product name, store name,
/// [QuantityStepper], and the line price in DM Serif Display.
///
/// Use-count: basket_view (E) → 1 direct call site, but abstracted here for
/// Group F re-use in order_details_view.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/quantity_stepper.dart';

class BasketRow extends StatelessWidget {
  const BasketRow({
    super.key,
    required this.productName,
    required this.productImageUrl,
    required this.storeName,
    required this.unitPrice,
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final String productName;
  final String productImageUrl;
  final String storeName;

  /// Price per unit after discount.
  final double unitPrice;

  final int quantity;

  /// Stock ceiling passed to [QuantityStepper].
  final int maxQuantity;

  final ValueChanged<int> onQuantityChanged;

  /// Whether this row's checkbox is checked.
  final bool isSelected;

  /// If non-null, a leading checkbox is rendered.
  final ValueChanged<bool?>? onSelectionChanged;

  double get lineTotal => unitPrice * quantity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Optional selection checkbox
          if (onSelectionChanged != null)
            Checkbox(
              value: isSelected,
              activeColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onSelectionChanged,
            ),

          // Product thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: productImageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 72,
                height: 72,
                color: cs.surfaceContainerHighest,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.image_not_supported_outlined,
                    color: cs.outline, size: 28),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + store + stepper
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  storeName,
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                QuantityStepper(
                  value: quantity,
                  min: 1,
                  max: maxQuantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Line price
          Text(
            '₱${lineTotal.toStringAsFixed(2)}',
            style: tt.titleMedium?.copyWith(
              fontFamily: 'DMSerifDisplay',
              color: cs.primary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
