/// BundleView — single product-bundle detail screen.
///
/// Layout:
///   • Hero: bundle cover image with floating back / basket overlay.
///   • Content: bundle name, badges (discount, stock), store row, price block,
///     description, component list (each batch with thumb + name + included qty).
///   • Pinned bottom bar: QuantityStepper + "Add bundle to basket" CTA.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/quantity_stepper.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class BundleView extends StatefulWidget {
  const BundleView({super.key, required this.bundleId});

  final String bundleId;

  @override
  State<BundleView> createState() => _BundleViewState();
}

class _BundleViewState extends State<BundleView> {
  int _quantity = 1;
  Map<String, dynamic>? _sellerData;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    final snap = await FirebaseFirestore.instance
        .collection('bundles')
        .doc(widget.bundleId)
        .get();
    final bundleData = snap.data();
    if (bundleData == null || !mounted) return;

    final sellerSnap = await FirebaseFirestore.instance
        .collection('stores')
        .doc(bundleData['sellerId'] as String)
        .get();
    if (mounted) {
      setState(() {
        _sellerData = sellerSnap.data();
      });
    }
  }

  Future<void> _addToCart(String bundleId, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to add items to your basket.')),
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('baskets')
          .doc(user.uid)
          .collection('cart_items')
          .doc(bundleId)
          .set({'quantity': quantity});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bundle added to basket')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to basket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bundles')
            .doc(widget.bundleId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const Center(
              child: EmptyStateView(
                icon: Icons.error_outline,
                headline: 'Bundle not found',
                body: 'This bundle may no longer be available.',
              ),
            );
          }

          final bundleData =
              snapshot.data!.data() as Map<String, dynamic>;
          final rawPrice =
              (bundleData['price'] as num? ?? 0).toDouble();
          final discount =
              (bundleData['discount'] as num? ?? 0).toDouble();
          final discountedPrice = rawPrice * (1 - discount / 100);
          final stock = (bundleData['stock'] as num? ?? 0).toInt();
          final mainImageUrl =
              bundleData['mainImageUrl'] as String? ?? '';
          final sellerId =
              bundleData['sellerId'] as String? ?? '';
          final items =
              (bundleData['items'] as List<dynamic>?) ?? [];

          return Column(
            children: [
              // ── Hero image ───────────────────────────────────────────
              _BundleHero(
                imageUrl: mainImageUrl,
                onBack: () => Navigator.pop(context),
                onBasket: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BasketView()),
                ),
              ),

              // ── Scrollable content ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Row(
                        children: [
                          if (discount > 0) _DiscountBadge(discount: discount),
                          if (discount > 0) const SizedBox(width: 8),
                          _StockBadge(stock: stock, cs: cs, tt: tt),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Bundle name
                      Text(
                        bundleData['name'] as String? ?? '',
                        style: tt.headlineMedium
                            ?.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 16),

                      // Store row
                      _StoreRow(
                        sellerData: _sellerData,
                        sellerId: sellerId,
                      ),

                      Divider(
                          color: cs.outline.withValues(alpha: 0.3),
                          height: 32),

                      // Price block
                      _PriceBlock(
                        currentPrice: discountedPrice,
                        originalPrice: rawPrice,
                        hasDiscount: discount > 0,
                        tt: tt,
                        cs: cs,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if ((bundleData['description'] as String?)
                              ?.isNotEmpty ==
                          true) ...[
                        Text(
                          'Description',
                          style: tt.titleMedium
                              ?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bundleData['description'] as String,
                          style: tt.bodyMedium?.copyWith(
                            color:
                                cs.onSurface.withValues(alpha: 0.85),
                            height: 1.55,
                          ),
                        ),
                        Divider(
                            color: cs.outline.withValues(alpha: 0.3),
                            height: 32),
                      ],

                      // Bundle components
                      Text(
                        'What\'s in the bundle',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 12),

                      if (items.isEmpty)
                        Text(
                          'No items listed.',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        )
                      else
                        _BundleComponentList(
                          items: items,
                          tt: tt,
                          cs: cs,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ── Pinned bottom bar ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          child: Row(
            children: [
              QuantityStepper(
                value: _quantity,
                onChanged: (q) => setState(() => _quantity = q),
                min: 1,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        _addToCart(widget.bundleId, _quantity),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Add bundle to basket',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bundle hero ──────────────────────────────────────────────────────────────

class _BundleHero extends StatelessWidget {
  const _BundleHero({
    required this.imageUrl,
    required this.onBack,
    required this.onBasket,
  });

  final String imageUrl;
  final VoidCallback onBack;
  final VoidCallback onBasket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.38;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                    placeholder: (_, __) =>
                        Container(color: cs.surfaceContainerHighest),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: cs.outline, size: 48),
                    ),
                  )
                : Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.shopping_bag_outlined,
                        color: cs.outline, size: 48),
                  ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: _OverlayButton(icon: Icons.arrow_back, onPressed: onBack),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: _OverlayButton(
                icon: Icons.shopping_basket_outlined, onPressed: onBasket),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: cs.onSurface, size: 22),
        ),
      ),
    );
  }
}

// ── Discount badge ───────────────────────────────────────────────────────────

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.discount});

  final double discount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '–${discount.toStringAsFixed(0)}% off',
        style: tt.labelSmall?.copyWith(color: cs.onSecondary),
      ),
    );
  }
}

// ── Stock badge ──────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.stock,
    required this.cs,
    required this.tt,
  });

  final int stock;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$stock in stock',
        style: tt.labelSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

// ── Store row ────────────────────────────────────────────────────────────────

class _StoreRow extends StatelessWidget {
  const _StoreRow({required this.sellerData, required this.sellerId});

  final Map<String, dynamic>? sellerData;
  final String sellerId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final storeName =
        sellerData?['store_name'] as String? ?? 'Loading...';
    final storeImageUrl = sellerData?['store_image_url'] as String?;

    return GestureDetector(
      onTap: sellerData != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StoreView(storeId: sellerId)),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.outline.withValues(alpha: 0.15),
              backgroundImage: storeImageUrl != null &&
                      storeImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(storeImageUrl)
                  : null,
              child: storeImageUrl == null || storeImageUrl.isEmpty
                  ? Icon(Icons.store_outlined, color: cs.outline, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                storeName,
                style: tt.titleSmall?.copyWith(color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Visit',
                style: tt.labelMedium?.copyWith(color: cs.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price block ──────────────────────────────────────────────────────────────

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.currentPrice,
    required this.originalPrice,
    required this.hasDiscount,
    required this.tt,
    required this.cs,
  });

  final double currentPrice;
  final double originalPrice;
  final bool hasDiscount;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'PHP ${currentPrice.toStringAsFixed(2)}',
          style: tt.displaySmall?.copyWith(color: cs.primary),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'PHP ${originalPrice.toStringAsFixed(2)}',
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.45),
                decoration: TextDecoration.lineThrough,
                decorationColor: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bundle component list ────────────────────────────────────────────────────

class _BundleComponentList extends StatelessWidget {
  const _BundleComponentList({
    required this.items,
    required this.tt,
    required this.cs,
  });

  final List<dynamic> items;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final batchIds = items
        .map((i) => (i as Map<String, dynamic>)['batchId'] as String?)
        .whereType<String>()
        .toList();

    if (batchIds.isEmpty) {
      return Text(
        'No items listed.',
        style: tt.bodyMedium
            ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('batches')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final batchDocs = snap.data!.docs;

        return Column(
          children: batchDocs.map((batchDoc) {
            final batchData =
                batchDoc.data() as Map<String, dynamic>;
            final productId =
                batchData['productId'] as String? ?? '';

            // Find qty from items list
            final itemEntry = items.firstWhere(
              (i) =>
                  (i as Map<String, dynamic>)['batchId'] ==
                  batchDoc.id,
              orElse: () => <String, dynamic>{},
            ) as Map<String, dynamic>;
            final qty =
                (itemEntry['quantity'] as num? ?? 1).toInt();

            return _ComponentRow(
              productId: productId,
              qty: qty,
              tt: tt,
              cs: cs,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.productId,
    required this.qty,
    required this.tt,
    required this.cs,
  });

  final String productId;
  final int qty;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        final productData =
            snap.data?.data() as Map<String, dynamic>?;
        final name =
            productData?['name'] as String? ?? 'Unknown product';
        final imageUrl =
            productData?['mainImageUrl'] as String? ?? '';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductPage(productId: productId),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: cs.outline
                                    .withValues(alpha: 0.12)),
                            errorWidget: (_, __, ___) => Container(
                              color: cs.outline
                                  .withValues(alpha: 0.12),
                              child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: cs.outline,
                                  size: 20),
                            ),
                          )
                        : Container(
                            color:
                                cs.outline.withValues(alpha: 0.12),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: tt.bodyMedium
                        ?.copyWith(color: cs.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '×$qty',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
