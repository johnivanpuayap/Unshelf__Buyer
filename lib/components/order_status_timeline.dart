/// OrderStatusTimeline — vertical timeline showing order progress.
///
/// Stages: Placed → Confirmed → Preparing → Ready for pickup → Picked up.
/// Past stages: filled primary circle + check icon.
/// Current stage: outlined primary circle + pulsing ring (AnimatedContainer).
/// Future stages: grey outlined circle.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OrderStage { placed, confirmed, preparing, ready, completed }

class StageTimestamp {
  const StageTimestamp({required this.stage, this.timestamp});
  final OrderStage stage;
  final DateTime? timestamp;
}

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.currentStage,
    this.timestamps = const [],
  });

  final OrderStage currentStage;
  final List<StageTimestamp> timestamps;

  static const _stages = [
    OrderStage.placed,
    OrderStage.confirmed,
    OrderStage.preparing,
    OrderStage.ready,
    OrderStage.completed,
  ];

  static const _labels = {
    OrderStage.placed: 'Order placed',
    OrderStage.confirmed: 'Confirmed',
    OrderStage.preparing: 'Preparing your order',
    OrderStage.ready: 'Ready for pickup',
    OrderStage.completed: 'Picked up',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentIndex = _stages.indexOf(currentStage);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: List.generate(_stages.length, (i) {
          final stage = _stages[i];
          final isPast = i < currentIndex;
          final isCurrent = i == currentIndex;
          final isFuture = i > currentIndex;
          final isLast = i == _stages.length - 1;

          final ts = timestamps
              .where((t) => t.stage == stage)
              .map((t) => t.timestamp)
              .firstOrNull;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Circle + vertical connector ──────────────────────────
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    _StageCircle(
                      isPast: isPast,
                      isCurrent: isCurrent,
                      isFuture: isFuture,
                      cs: cs,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isPast
                            ? cs.primary
                            : cs.outline.withValues(alpha: 0.3),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Label + timestamp ────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[stage] ?? '',
                        style: isCurrent
                            ? tt.titleSmall?.copyWith(color: cs.primary)
                            : isFuture
                                ? tt.bodyMedium?.copyWith(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.38))
                                : tt.bodyMedium?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600),
                      ),
                      if (ts != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, h:mm a').format(ts),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StageCircle extends StatefulWidget {
  const _StageCircle({
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
    required this.cs,
  });

  final bool isPast;
  final bool isCurrent;
  final bool isFuture;
  final ColorScheme cs;

  @override
  State<_StageCircle> createState() => _StageCircleState();
}

class _StageCircleState extends State<_StageCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;

    if (widget.isPast) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cs.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: cs.onPrimary, size: 16),
      );
    }

    if (widget.isCurrent) {
      return ScaleTransition(
        scale: _scale,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary, width: 2.5),
            color: cs.primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    // Future
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
    );
  }
}
