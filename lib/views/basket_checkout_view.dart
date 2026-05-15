import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/components/datetime_picker.dart';
import 'package:unshelf_buyer/views/order_placed_view.dart';
import 'package:unshelf_buyer/viewmodels/order_viewmodel.dart';

class CheckoutView extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> basketItems;
  final String? sellerId;

  const CheckoutView(
      {super.key, required this.basketItems, required this.sellerId});

  @override
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  String storeName = '';
  String storeImageUrl = '';
  double totalRegular = 0.0;
  double totalAmount = 0.0;
  DateTime? selectedPickupDateTime;
  String selectedPaymentMethod = 'Cash';
  String orderId = '';
  int points = 0;
  bool usePoints = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStoreDetails();
    _fetchUserDetails();
    _calculateTotal();
    _generateOrderId();
  }

  // ─── Data ────────────────────────────────────────────────────────────

  Future<void> _fetchStoreDetails() async {
    if (widget.sellerId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.sellerId)
        .get();
    if (snap.exists && mounted) {
      setState(() {
        storeName = snap.data()?['store_name'] ?? '';
        storeImageUrl = snap.data()?['store_image_url'] ?? '';
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (snap.exists && mounted) {
      setState(() {
        points = (snap.data()?['points'] as num?)?.toInt() ?? 0;
      });
    }
  }

  void _calculateTotal() {
    totalRegular = widget.basketItems.fold(
      0.0,
      (sum, item) =>
          sum + (item['batchPrice'] as num).toDouble() * (item['quantity'] as int),
    );
    totalAmount = totalRegular;
  }

  void _updateTotal() {
    setState(() {
      totalAmount = usePoints
          ? (totalRegular - points).clamp(0.0, double.infinity)
          : totalRegular;
    });
  }

  Future<void> _generateOrderId() async {
    final now = DateTime.now();
    final start =
        now.subtract(Duration(hours: now.hour, minutes: now.minute, seconds: now.second));
    final end = start.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    setState(() {
      orderId =
          '${DateFormat('yyyyMMdd').format(now)}-${(snap.size + 1).toString().padLeft(3, '0')}';
    });
  }

  Future<void> _selectPickupDateTime() async {
    final picked = await showDateTimePicker(context: context);
    if (picked != null && mounted) {
      setState(() => selectedPickupDateTime = picked);
    }
  }

  // ─── Confirm order ────────────────────────────────────────────────────

  Future<void> _confirmOrder() async {
    if (selectedPickupDateTime == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isSubmitting = true);

    try {
      if (selectedPaymentMethod == 'Card') {
        final vm = ref.read(orderViewModelProvider.notifier);
        final success = await vm.processOrderAndPayment(
          user.uid,
          widget.basketItems,
          widget.sellerId!,
          orderId,
          totalAmount,
          selectedPickupDateTime,
          usePoints,
          points,
        );
        if (success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrderPlacedView()),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('orders').add({
          'buyerId': user.uid,
          'completedAt': null,
          'createdAt': DateTime.now(),
          'isPaid': false,
          'orderId': orderId,
          'orderItems': widget.basketItems
              .map((item) => {
                    'batchId': item['batchId'],
                    'quantity': item['quantity'],
                    'price': item['batchPrice'],
                    'isBundle': item['isBundle'],
                  })
              .toList(),
          'sellerId': widget.sellerId,
          'status': 'Pending',
          'subTotal': totalRegular,
          'totalPrice': totalAmount,
          'pickupTime': Timestamp.fromDate(selectedPickupDateTime!),
          'pointsDiscount': usePoints ? points : 0,
        });

        for (final item in widget.basketItems) {
          final batchId = item['batchId'] as String;
          final quantity = item['quantity'] as int;

          final batchSnap = await FirebaseFirestore.instance
              .collection('batches')
              .doc(batchId)
              .get();

          if (batchSnap.exists) {
            final current = (batchSnap.data()?['stock'] as num?)?.toInt() ?? 0;
            final next = current - quantity;
            if (next < 0) throw Exception('Insufficient stock for $batchId');
            await FirebaseFirestore.instance
                .collection('batches')
                .doc(batchId)
                .update({'stock': next});
          } else {
            final bundleSnap = await FirebaseFirestore.instance
                .collection('bundles')
                .doc(batchId)
                .get();
            if (bundleSnap.exists) {
              final current =
                  (bundleSnap.data()?['stock'] as num?)?.toInt() ?? 0;
              final next = current - quantity;
              if (next < 0) throw Exception('Insufficient stock for $batchId');
              await FirebaseFirestore.instance
                  .collection('bundles')
                  .doc(batchId)
                  .update({'stock': next});
            }
          }

          await FirebaseFirestore.instance
              .collection('baskets')
              .doc(user.uid)
              .collection('cart_items')
              .doc(batchId)
              .delete();
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrderPlacedView()),
          );
        }
      }
    } catch (e) {
      debugPrint('Order confirmation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          'Checkout',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        children: [
          // ── Pickup window ──────────────────────────────────────────────
          _SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _IconCircle(icon: Icons.schedule_outlined, cs: cs),
              title: Text('Pickup window', style: tt.titleSmall),
              subtitle: selectedPickupDateTime != null
                  ? Text(
                      DateFormat('EEE, MMM d • h:mm a')
                          .format(selectedPickupDateTime!),
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    )
                  : Text(
                      'Tap to choose a pickup time',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
              trailing: Icon(Icons.chevron_right, color: cs.outline),
              onTap: _selectPickupDateTime,
            ),
          ),

          const SizedBox(height: 12),

          // ── Payment method ─────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      _IconCircle(icon: Icons.payment_outlined, cs: cs),
                  title: Text('Payment method', style: tt.titleSmall),
                  subtitle: Text(
                    selectedPaymentMethod,
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['Cash', 'Card'].map((method) {
                    final selected = selectedPaymentMethod == method;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => selectedPaymentMethod = method),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                selected ? cs.primary : Colors.transparent,
                            side: BorderSide(
                              color: selected ? cs.primary : cs.outline,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            method,
                            style: tt.labelMedium?.copyWith(
                              color: selected ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Points redemption ──────────────────────────────────────────
          if (points > 0) ...[
            _SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _IconCircle(icon: Icons.stars_outlined, cs: cs),
                title: Text('Use loyalty points', style: tt.titleSmall),
                subtitle: Text(
                  'Deduct ₱${points.toStringAsFixed(0)} from total',
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                trailing: Switch(
                  value: usePoints,
                  activeColor: cs.primary,
                  onChanged: (v) {
                    setState(() => usePoints = v);
                    _updateTotal();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Order summary ──────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      _IconCircle(icon: Icons.receipt_long_outlined, cs: cs),
                  title: Text('Order summary', style: tt.titleSmall),
                ),
                const SizedBox(height: 4),

                // Items list
                ...widget.basketItems.map((item) {
                  final price = (item['batchPrice'] as num).toDouble();
                  final qty = item['quantity'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Thumb
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['productMainImageUrl'] as String,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: cs.outline, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'] as String,
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurface),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₱${price.toStringAsFixed(2)} × $qty',
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.55)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₱${(price * qty).toStringAsFixed(2)}',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurface),
                        ),
                      ],
                    ),
                  );
                }),

                Divider(
                    height: 20,
                    color: cs.outline.withValues(alpha: 0.3)),

                // Subtotal / discount / total
                _AmountRow(
                    label: 'Subtotal',
                    amount: totalRegular,
                    tt: tt,
                    cs: cs),
                if (usePoints && points > 0) ...[
                  const SizedBox(height: 4),
                  _AmountRow(
                    label: 'Points discount',
                    amount: -points.toDouble(),
                    tt: tt,
                    cs: cs,
                    isDiscount: true,
                  ),
                ],
                const SizedBox(height: 4),
                _AmountRow(
                    label: 'Service fee',
                    amount: 0,
                    tt: tt,
                    cs: cs),
                Divider(
                    height: 16,
                    color: cs.outline.withValues(alpha: 0.3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: tt.titleSmall
                            ?.copyWith(color: cs.onSurface)),
                    Text(
                      '₱${totalAmount.toStringAsFixed(2)}',
                      style: tt.titleMedium?.copyWith(
                        fontFamily: 'DMSerifDisplay',
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ─── Pinned "Place order" CTA ──────────────────────────────────────
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: cs.primary,
              disabledBackgroundColor:
                  cs.onSurface.withValues(alpha: 0.12),
            ),
            onPressed: (selectedPickupDateTime == null || isSubmitting)
                ? null
                : _confirmOrder,
            child: isSubmitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : Text(
                    selectedPickupDateTime == null
                        ? 'Choose pickup time first'
                        : 'Place order',
                    style: tt.labelLarge?.copyWith(
                      color: selectedPickupDateTime != null
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
      child: child,
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.cs});
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.tt,
    required this.cs,
    this.isDiscount = false,
  });

  final String label;
  final double amount;
  final TextTheme tt;
  final ColorScheme cs;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.bodySmall
                ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
        Text(
          isDiscount
              ? '-₱${amount.abs().toStringAsFixed(2)}'
              : amount == 0
                  ? 'Free'
                  : '₱${amount.toStringAsFixed(2)}',
          style: tt.bodySmall?.copyWith(
            color: isDiscount ? cs.primary : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
