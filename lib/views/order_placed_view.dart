import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/order_tracking_view.dart';

class OrderPlacedView extends StatelessWidget {
  const OrderPlacedView({super.key, this.orderId});

  /// Optional order reference number to surface on the success screen.
  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hero icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: cs.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Headline
                Text(
                  'Order placed!',
                  style: tt.headlineLarge?.copyWith(
                    fontFamily: 'DMSerifDisplay',
                    color: cs.primary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Body
                Text(
                  "Your order is on its way.\nWe'll let you know when it's ready for pickup.",
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Order number badge
                if (orderId != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Order #$orderId',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Primary CTA — Track order
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: cs.primary,
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrderTrackingView()),
                    ),
                    child: Text(
                      'Track order',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary CTA — Back to home
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: BorderSide(color: cs.outline),
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                    ),
                    child: Text(
                      'Back to home',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
