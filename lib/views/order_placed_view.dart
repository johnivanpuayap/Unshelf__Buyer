import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/home_view.dart';

class OrderPlacedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/salad.png',
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed',
              style: tt.headlineSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment is complete.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: 'Please check ',
                style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Order Tracking',
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' page in Profile',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeView()),
                );
              },
              child: Text(
                'Continue Shopping',
                style: tt.labelLarge?.copyWith(color: cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
