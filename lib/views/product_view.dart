/// ProductPage — single product detail screen.
///
/// Layout:
///   • Hero: image carousel (PageView + indicator dots) with floating back
///     and basket buttons overlay.
///   • Content: expiry badge, discount badge, product name, store row,
///     price block (current + strikethrough original), description, batch
///     selector, reviews preview.
///   • Pinned bottom bar: QuantityStepper + "Add to basket" CTA.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/quantity_stepper.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/store_reviews_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _quantity = 1;
  int _carouselPage = 0;
  Map<String, dynamic>? _sellerData;
  bool _isFavorite = false;

  List<DocumentSnapshot>? _batches;
  DocumentSnapshot? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _checkIfFavorite();
    _fetchBatches();
  }

  // ── Data fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchSellerData() async {
    final productSnap = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    final productData = productSnap.data();
    if (productData == null) return;

    final sellerSnap = await FirebaseFirestore.instance
        .collection('stores')
        .doc(productData['sellerId'] as String)
        .get();
    if (mounted) {
      setState(() {
        _sellerData = sellerSnap.data();
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId)
        .get();
    if (mounted) setState(() => _isFavorite = doc.exists);
  }

  Future<void> _fetchBatches() async {
    final snap = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: widget.productId)
        .where('isListed', isEqualTo: true)
        .get();
    if (mounted) {
      setState(() {
        _batches = snap.docs;
        if (_batches!.isNotEmpty) _selectedBatch = _batches!.first;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId);

    if (_isFavorite) {
      await ref.delete();
    } else {
      await ref.set({
        'added_at': FieldValue.serverTimestamp(),
        'is_bundle': false,
      });
    }
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to Favorites' : 'Removed from Favorites',
          ),
        ),
      );
    }
  }

  Future<void> _addToCart(String batchId, int quantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sign in to add items to your basket.')),
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('baskets')
          .doc(user.uid)
          .collection('cart_items')
          .doc(batchId)
          .set({'quantity': quantity});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Added to basket')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to basket: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.data!.exists) {
            return const Center(
              child: EmptyStateView(
                icon: Icons.error_outline,
                headline: 'Product not found',
                body: 'This product may no longer be available.',
              ),
            );
          }

          final productData =
              snapshot.data!.data() as Map<String, dynamic>;
          final batchData =
              _selectedBatch?.data() as Map<String, dynamic>?;

          // Price calculation
          final rawPrice = (batchData?['price'] as num? ??
                  productData['price'] as num? ??
                  0)
              .toDouble();
          final discount =
              (batchData?['discount'] as num? ?? 0).toDouble();
          final discountedPrice = rawPrice * (1 - discount / 100);

          // Expiry
          final expiryTs = batchData?['expiryDate'] as Timestamp?;
          final expiryDate = expiryTs?.toDate();
          final daysLeft =
              expiryDate?.difference(DateTime.now()).inDays ?? 0;

          // Images
          final mainImageUrl =
              productData['mainImageUrl'] as String? ?? '';
          final additionalUrls =
              (productData['additionalImageUrls'] as List<dynamic>?)
                      ?.cast<String>() ??
                  [];
          final allImages = [
            if (mainImageUrl.isNotEmpty) mainImageUrl,
            ...additionalUrls,
          ];

          return Column(
            children: [
              // ── Hero carousel ────────────────────────────────────────
              _HeroCarousel(
                images: allImages,
                currentPage: _carouselPage,
                onPageChanged: (p) => setState(() => _carouselPage = p),
                onBack: () => Navigator.pop(context),
                onBasket: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BasketView()),
                ),
              ),

              // ── Scrollable content ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Row(
                        children: [
                          _ExpiryBadge(
                            daysLeft: daysLeft,
                            expiryDate: expiryDate,
                          ),
                          if (discount > 0) ...[
                            const SizedBox(width: 8),
                            _DiscountBadge(discount: discount),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: cs.primary,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Product name
                      Text(
                        productData['name'] as String? ?? '',
                        style: tt.headlineMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Store row
                      _StoreRow(
                        sellerData: _sellerData,
                        sellerId:
                            productData['sellerId'] as String? ?? '',
                      ),

                      Divider(
                          color: cs.outline.withValues(alpha: 0.3),
                          height: 32),

                      // Price block
                      _PriceBlock(
                        currentPrice: discountedPrice,
                        originalPrice: rawPrice,
                        hasDiscount: discount > 0,
                        quantifier:
                            productData['quantifier'] as String? ??
                                'unit',
                        tt: tt,
                        cs: cs,
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productData['description'] as String? ?? '',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.85),
                          height: 1.55,
                        ),
                      ),

                      Divider(
                          color: cs.outline.withValues(alpha: 0.3),
                          height: 32),

                      // Batch selector
                      if (_batches != null && _batches!.isNotEmpty) ...[
                        Text(
                          'Choose a batch',
                          style: tt.titleMedium
                              ?.copyWith(color: cs.onSurface),
                        ),
                        const SizedBox(height: 8),
                        _BatchDropdown(
                          batches: _batches!,
                          selected: _selectedBatch,
                          onChanged: (b) =>
                              setState(() => _selectedBatch = b),
                          tt: tt,
                          cs: cs,
                        ),
                        Divider(
                            color: cs.outline.withValues(alpha: 0.3),
                            height: 32),
                      ],

                      // Reviews preview
                      _ReviewsPreview(
                        sellerId:
                            productData['sellerId'] as String? ?? '',
                        onViewAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreReviewsView(
                              storeId: productData['sellerId']
                                  as String? ??
                                  '',
                            ),
                          ),
                        ),
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
      bottomNavigationBar: _BottomBar(
        quantity: _quantity,
        batchId: _selectedBatch?.id,
        onQuantityChanged: (q) => setState(() => _quantity = q),
        onAddToCart: () {
          if (_selectedBatch != null) {
            _addToCart(_selectedBatch!.id, _quantity);
          }
        },
      ),
    );
  }
}

// ── Hero carousel ────────────────────────────────────────────────────────────

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.images,
    required this.currentPage,
    required this.onPageChanged,
    required this.onBack,
    required this.onBasket,
  });

  final List<String> images;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onBasket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.42;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Image PageView
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: images.isEmpty
                ? Container(
                    width: double.infinity,
                    height: height,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: cs.outline, size: 48),
                  )
                : PageView.builder(
                    itemCount: images.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: height,
                        placeholder: (_, __) => Container(
                          color: cs.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image_outlined,
                              color: cs.outline),
                        ),
                      );
                    },
                  ),
          ),

          // Back button
          Positioned(
            top: 48,
            left: 16,
            child: _OverlayButton(
              icon: Icons.arrow_back,
              onPressed: onBack,
            ),
          ),

          // Basket button
          Positioned(
            top: 48,
            right: 16,
            child: _OverlayButton(
              icon: Icons.shopping_basket_outlined,
              onPressed: onBasket,
            ),
          ),

          // Indicator dots
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final active = index == currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
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

// ── Expiry badge ─────────────────────────────────────────────────────────────

class _ExpiryBadge extends StatelessWidget {
  const _ExpiryBadge({required this.daysLeft, required this.expiryDate});

  final int daysLeft;
  final DateTime? expiryDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String label;
    if (expiryDate == null) {
      label = 'Expiry unknown';
    } else if (daysLeft <= 0) {
      label = 'Expires today';
    } else if (daysLeft == 1) {
      label = 'Expires tomorrow';
    } else {
      label = 'Expires in $daysLeft days';
    }

    final isUrgent = daysLeft <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? cs.errorContainer
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isUrgent
              ? cs.error.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: isUrgent
              ? cs.onErrorContainer
              : cs.onSurface.withValues(alpha: 0.75),
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

// ── Store row ────────────────────────────────────────────────────────────────

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.sellerData,
    required this.sellerId,
  });

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
            // Avatar
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
            // Name
            Expanded(
              child: Text(
                storeName,
                style: tt.titleSmall?.copyWith(color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Visit pill
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
    required this.quantifier,
    required this.tt,
    required this.cs,
  });

  final double currentPrice;
  final double originalPrice;
  final bool hasDiscount;
  final String quantifier;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'PHP ${currentPrice.toStringAsFixed(2)}',
          style: tt.displaySmall?.copyWith(
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiscount)
                Text(
                  'PHP ${originalPrice.toStringAsFixed(2)}',
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.45),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              Text(
                'per $quantifier',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Batch dropdown ───────────────────────────────────────────────────────────

class _BatchDropdown extends StatelessWidget {
  const _BatchDropdown({
    required this.batches,
    required this.selected,
    required this.onChanged,
    required this.tt,
    required this.cs,
  });

  final List<DocumentSnapshot> batches;
  final DocumentSnapshot? selected;
  final ValueChanged<DocumentSnapshot?> onChanged;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DocumentSnapshot>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
      ),
      onChanged: onChanged,
      items: batches.map((batch) {
        final data = batch.data() as Map<String, dynamic>;
        final expiryTs = data['expiryDate'] as Timestamp?;
        final expiryStr = expiryTs != null
            ? DateFormat('MMM d, yyyy').format(expiryTs.toDate())
            : 'Unknown expiry';
        return DropdownMenuItem<DocumentSnapshot>(
          value: batch,
          child: Text(
            'Batch ${data['batchNumber']} · ${data['stock']} left · $expiryStr',
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        );
      }).toList(),
    );
  }
}

// ── Reviews preview ──────────────────────────────────────────────────────────

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview({
    required this.sellerId,
    required this.onViewAll,
  });

  final String sellerId;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(sellerId)
          .collection('reviews')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews',
                  style: tt.titleMedium?.copyWith(color: cs.onSurface),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View all',
                    style: tt.labelMedium?.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReviewCard(
                  rating:
                      (data['rating'] as num?)?.toInt() ?? 0,
                  reviewerName:
                      data['reviewer_name'] as String? ??
                          data['reviewerName'] as String? ??
                          'Anonymous',
                  body: data['description'] as String? ?? '',
                  timestamp:
                      (data['created_at'] as Timestamp?)?.toDate(),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.quantity,
    required this.batchId,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  final int quantity;
  final String? batchId;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            QuantityStepper(
              value: quantity,
              onChanged: onQuantityChanged,
              min: 1,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: batchId != null ? onAddToCart : null,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Add to basket',
                    style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
