/// EmptyStateView — centred placeholder used for empty, loading and error
/// states throughout the buyer app.
///
/// Pass [icon], [headline], and [body] for the static visual.  Supply
/// [ctaLabel] + [onCta] to render an [OutlinedButton] below the body.
/// For the error variant, the caller passes [ctaLabel] = "Try again".
library;

import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            style: tt.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onCta,
              child: Text(ctaLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
