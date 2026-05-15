/// StarRatingPicker — interactive 5-star tap-to-rate widget.
///
/// Unlike the read-only [_StarRow] in store_reviews_view, this is an input
/// widget: tapping a star sets the rating to that star's index.
///
/// Use-count: review_view (D), order_details (future) → extract now because
/// it's a distinct interactive concern from the display-only star row.
library;

import 'package:flutter/material.dart';

class StarRatingPicker extends StatelessWidget {
  const StarRatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.starSize = 40.0,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < value;
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? cs.tertiary : cs.outline,
              size: starSize,
            ),
          ),
        );
      }),
    );
  }
}
