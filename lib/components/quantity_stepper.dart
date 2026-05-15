/// QuantityStepper — inline [–] count [+] control.
///
/// Uses theme tokens only; no hardcoded colors. The [max] parameter disables
/// the increment button when the count equals [max].
///
/// Use-count: product_view (D), product_bundle_view (D), basket_view (E) → 3+.
library;

import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final atMin = value <= min;
    final atMax = max != null && value >= max!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onPressed: atMin ? null : () => onChanged(value - 1),
            cs: cs,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: tt.titleMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onPressed: atMax ? null : () => onChanged(value + 1),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.cs,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        iconSize: 18,
        icon: Icon(icon),
        color: onPressed != null ? cs.primary : cs.outline,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
