import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/components/basket_row.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/section_header.dart';
import 'package:unshelf_buyer/views/basket_checkout_view.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class BasketView extends StatefulWidget {
  const BasketView({super.key});

  @override
  _BasketViewState createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  User? user;
  Map<String, List<Map<String, dynamic>>> groupedBasketItems = {};
  Set<String> selectedBatchIds = {};
  double total = 0.0;
  String? selectedSellerId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchBasketItems();
  }

  // ─── Selection helpers ────────────────────────────────────────────────

  void _toggleStoreSelection(String sellerId, bool isSelected) {
    final storeItems = groupedBasketItems[sellerId];
    if (storeItems == null) return;
    setState(() {
      if (isSelected) {
        for (final item in storeItems) {
          selectedBatchIds.add(item['batchId'] as String);
        }
        selectedSellerId = sellerId;
      } else {
        for (final item in storeItems) {
          selectedBatchIds.remove(item['batchId'] as String);
        }
        if (selectedBatchIds.isEmpty) selectedSellerId = null;
      }
      _updateTotal();
    });
  }

  void _toggleItemSelection(String batchId, String sellerId, bool? value) {
    setState(() {
      if (value == true) {
        if (selectedSellerId == null || selectedSellerId == sellerId) {
          selectedBatchIds.add(batchId);
          selectedSellerId = sellerId;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only order from one store at a time.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        selectedBatchIds.remove(batchId);
        final storeItems = groupedBasketItems[sellerId];
        final stillSelected =
            storeItems?.any((i) => selectedBatchIds.contains(i['batchId'])) ??
                false;
        if (!stillSelected) selectedSellerId = null;
      }
      _updateTotal();
    });
  }

  // ─── Data fetching ────────────────────────────────────────────────────

  Future<void> fetchBasketItems() async {
    if (user == null) return;
    setState(() => isLoading = true);

    try {
      final basketSnapshot = await FirebaseFirestore.instance
          .collection('baskets')
          .doc(user!.uid)
          .collection('cart_items')
          .get();

      if (basketSnapshot.docs.isEmpty) {
        setState(() {
          groupedBasketItems = {};
          isLoading = false;
        });
        return;
      }

      final batchIds = basketSnapshot.docs.map((d) => d.id).toList();
      final quantities = {
        for (final d in basketSnapshot.docs) d.id: d['quantity'] as int
      };

      final batchSnapshotsFuture = FirebaseFirestore.instance
          .collection('batches')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
      final bundleSnapshotsFuture = FirebaseFirestore.instance
          .collection('bundles')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      final batchSnapshots = await batchSnapshotsFuture;
      final bundleSnapshots = await bundleSnapshotsFuture;

      final productIds =
          batchSnapshots.docs.map((d) => d['productId'] as String).toSet();
      final Set<String> sellerIds = {
        ...batchSnapshots.docs.map((d) => d['sellerId'] as String),
        ...bundleSnapshots.docs.map((d) => d['sellerId'] as String),
      };

      final productsFuture = productIds.isEmpty
          ? Future.value(<String, Map<String, dynamic>>{})
          : FirebaseFirestore.instance
              .collection('products')
              .where(FieldPath.documentId, whereIn: productIds.toList())
              .get()
              .then((s) => {for (final d in s.docs) d.id: d.data()});

      final storesFuture = sellerIds.isEmpty
          ? Future.value(<String, Map<String, dynamic>>{})
          : FirebaseFirestore.instance
              .collection('stores')
              .where(FieldPath.documentId, whereIn: sellerIds.toList())
              .get()
              .then((s) => {for (final d in s.docs) d.id: d.data()});

      final products = await productsFuture;
      final stores = await storesFuture;

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      // Bundles
      for (final bundleDoc in bundleSnapshots.docs) {
        final data = bundleDoc.data();
        final bundleId = bundleDoc.id;
        final sellerId = data['sellerId'] as String;
        final storeData = stores[sellerId];
        if (storeData == null) continue;

        grouped.putIfAbsent(sellerId, () => []).add({
          'batchId': bundleId,
          'quantity': quantities[bundleId] ?? 0,
          'batchPrice': data['price'],
          'batchDiscount': data['discount'] ?? 0,
          'batchStock': data['stock'],
          'productName': data['name'],
          'productMainImageUrl': data['mainImageUrl'] ?? '',
          'productQuantifier': 'unit',
          'storeName': storeData['store_name'],
          'storeImageUrl': storeData['store_image_url'] ?? '',
          'isBundle': true,
        });
      }

      // Batches
      for (final batchDoc in batchSnapshots.docs) {
        final data = batchDoc.data();
        final batchId = batchDoc.id;
        final productId = data['productId'] as String;
        final sellerId = data['sellerId'] as String;
        final productData = products[productId];
        final storeData = stores[sellerId];
        if (productData == null || storeData == null) continue;

        grouped.putIfAbsent(sellerId, () => []).add({
          'batchId': batchId,
          'quantity': quantities[batchId] ?? 0,
          'batchPrice': data['price'],
          'batchDiscount': data['discount'] ?? 0,
          'batchStock': data['stock'],
          'productName': productData['name'],
          'productMainImageUrl': productData['mainImageUrl'] ?? '',
          'productQuantifier': productData['quantifier'],
          'storeName': storeData['store_name'],
          'storeImageUrl': storeData['store_image_url'] ?? '',
          'isBundle': false,
        });
      }

      setState(() {
        groupedBasketItems = grouped;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchBasketItems error: $e');
      setState(() => isLoading = false);
    }
  }

  // ─── Total ────────────────────────────────────────────────────────────

  void _updateTotal() {
    double t = 0.0;
    for (final items in groupedBasketItems.values) {
      for (final item in items) {
        if (selectedBatchIds.contains(item['batchId'])) {
          final discount = (item['batchDiscount'] as num?)?.toDouble() ?? 0;
          final price = (item['batchPrice'] as num).toDouble();
          final qty = item['quantity'] as int;
          t += price * (1 - discount / 100) * qty;
        }
      }
    }
    setState(() => total = t);
  }

  // ─── Clear basket ─────────────────────────────────────────────────────

  Future<void> _clearBasket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear basket?'),
        content: const Text('This will remove all items from your basket.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true || user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final cartRef = FirebaseFirestore.instance
        .collection('baskets')
        .doc(user!.uid)
        .collection('cart_items');

    for (final items in groupedBasketItems.values) {
      for (final item in items) {
        batch.delete(cartRef.doc(item['batchId'] as String));
      }
    }
    await batch.commit();
    setState(() {
      groupedBasketItems = {};
      selectedBatchIds.clear();
      selectedSellerId = null;
      total = 0;
    });
  }

  // ─── Checkout ─────────────────────────────────────────────────────────

  void _proceedToCheckout() {
    if (selectedSellerId == null || selectedBatchIds.isEmpty) return;

    final selectedItems = groupedBasketItems[selectedSellerId]!
        .where((i) => selectedBatchIds.contains(i['batchId']))
        .toList();

    final cleanItems = selectedItems.map((item) {
      final discount = (item['batchDiscount'] as num?)?.toDouble() ?? 0;
      final price = (item['batchPrice'] as num).toDouble();
      return {
        'batchId': item['batchId'],
        'productName': item['productName'],
        'productMainImageUrl': item['productMainImageUrl'],
        'batchPrice': price * (1 - discount / 100),
        'quantity': item['quantity'],
        'isBundle': item['isBundle'],
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CheckoutView(basketItems: cleanItems, sellerId: selectedSellerId),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEmpty = groupedBasketItems.isEmpty && !isLoading;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        toolbarHeight: 60,
        title: Text(
          'Your basket',
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimary,
            fontFamily: 'DMSerifDisplay',
          ),
        ),
        actions: [
          if (!isEmpty && !isLoading)
            IconButton(
              tooltip: 'Clear basket',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearBasket,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.shopping_basket_outlined,
                    headline: 'Your basket is empty',
                    body: 'Browse listings near you and add items to get started.',
                    ctaLabel: 'Browse listings',
                    onCta: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeView()),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: groupedBasketItems.length,
                  itemBuilder: (context, storeIndex) {
                    final sellerId =
                        groupedBasketItems.keys.elementAt(storeIndex);
                    final storeItems = groupedBasketItems[sellerId]!;
                    final storeName =
                        storeItems.first['storeName'] as String;
                    final storeImageUrl =
                        storeItems.first['storeImageUrl'] as String;

                    final allSelected = storeItems
                        .every((i) => selectedBatchIds.contains(i['batchId']));
                    final someSelected = storeItems
                        .any((i) => selectedBatchIds.contains(i['batchId']));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store header row
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreView(storeId: sellerId),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 16, 16, 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: allSelected,
                                  tristate:
                                      someSelected && !allSelected,
                                  activeColor: cs.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (v) =>
                                      _toggleStoreSelection(sellerId, v ?? false),
                                ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: storeImageUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(storeImageUrl)
                                      : null,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  child: storeImageUrl.isEmpty
                                      ? Icon(Icons.storefront_outlined,
                                          color: cs.outline, size: 18)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                SectionHeader(title: storeName),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ),
                        ),

                        // Item rows
                        ...storeItems.map((item) {
                          final batchId = item['batchId'] as String;
                          final discount =
                              (item['batchDiscount'] as num?)?.toDouble() ?? 0;
                          final price =
                              (item['batchPrice'] as num).toDouble() *
                                  (1 - discount / 100);
                          return BasketRow(
                            productName: item['productName'] as String,
                            productImageUrl:
                                item['productMainImageUrl'] as String,
                            storeName: storeName,
                            unitPrice: price,
                            quantity: item['quantity'] as int,
                            maxQuantity: item['batchStock'] as int,
                            isSelected: selectedBatchIds.contains(batchId),
                            onSelectionChanged: (v) =>
                                _toggleItemSelection(batchId, sellerId, v),
                            onQuantityChanged: (newQty) {
                              setState(() {
                                item['quantity'] = newQty;
                                _updateTotal();
                              });
                            },
                          );
                        }),

                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: cs.outline.withValues(alpha: 0.3),
                          indent: 16,
                          endIndent: 16,
                        ),
                      ],
                    );
                  },
                ),
      // ─── Pinned summary + CTA ──────────────────────────────────────────
      bottomSheet: isEmpty || isLoading
          ? null
          : _SummarySheet(
              subtotal: total,
              onCheckout: selectedBatchIds.isEmpty ? null : _proceedToCheckout,
            ),
    );
  }
}

// ─── Pinned summary card ──────────────────────────────────────────────────────

class _SummarySheet extends StatelessWidget {
  const _SummarySheet({
    required this.subtotal,
    required this.onCheckout,
  });

  final double subtotal;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Fee placeholder — real calculation happens in checkout.
    const double fee = 0.0;
    final total = subtotal + fee;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Subtotal row
          _SummaryRow(label: 'Subtotal', amount: subtotal, tt: tt, cs: cs),
          const SizedBox(height: 4),
          _SummaryRow(label: 'Service fee', amount: fee, tt: tt, cs: cs),

          Divider(height: 20, color: cs.outline.withValues(alpha: 0.3)),

          // Total row — DM Serif Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: tt.titleMedium?.copyWith(color: cs.onSurface)),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: tt.titleLarge?.copyWith(
                  fontFamily: 'DMSerifDisplay',
                  color: cs.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkout CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: cs.primary,
                disabledBackgroundColor:
                    cs.onSurface.withValues(alpha: 0.12),
              ),
              onPressed: onCheckout,
              child: Text(
                'Checkout',
                style: tt.labelLarge?.copyWith(
                  color: onCheckout != null ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.tt,
    required this.cs,
  });

  final String label;
  final double amount;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          amount == 0 ? 'Free' : '₱${amount.toStringAsFixed(2)}',
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}
