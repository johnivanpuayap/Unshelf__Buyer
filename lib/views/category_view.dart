/// CategoryProductsPage — 2-column grid of [ProductCard.compact] widgets for
/// a single product category.
///
/// Data: fetches all batches with isListed=true, cross-references products
/// in the matching category, then loads store names.  Sorting is controlled
/// by a sheet affordance in the AppBar (expiring soon / lowest price).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/category_row_widget.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/product_card.dart';

enum _CategorySort { expiringSoon, lowestPrice }

class CategoryProductsPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<_ProductEntry> _products = [];
  bool _isLoading = true;
  String? _error;
  _CategorySort _sort = _CategorySort.expiringSoon;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Listed batches → minPrices map
      final batchesSnap =
          await _firestore.collection('batches').where('isListed', isEqualTo: true).get();

      final Map<String, double> minPrices = {};
      for (final doc in batchesSnap.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final price = (data['price'] as num?)?.toDouble();
        if (productId == null || price == null) continue;
        if (!minPrices.containsKey(productId) || price < minPrices[productId]!) {
          minPrices[productId] = price;
        }
      }

      // 2. Products in this category
      final productsSnap = await _firestore
          .collection('products')
          .where('category', isEqualTo: widget.category.categoryKey)
          .get();

      final List<_ProductEntry> results = [];

      for (final doc in productsSnap.docs) {
        if (!minPrices.containsKey(doc.id)) continue;

        final data = doc.data();
        final sellerId = data['sellerId'] as String?;
        String storeName = 'Unknown store';

        if (sellerId != null) {
          final storeSnap =
              await _firestore.collection('stores').doc(sellerId).get();
          if (storeSnap.exists) {
            storeName =
                (storeSnap.data()?['store_name'] as String?) ?? storeName;
          }
        }

        // Expiry
        DateTime? expiryDate;
        final rawExpiry = data['expiryDate'];
        if (rawExpiry is Timestamp) {
          expiryDate = rawExpiry.toDate();
        } else if (rawExpiry is String) {
          expiryDate = DateTime.tryParse(rawExpiry);
        }
        expiryDate ??= DateTime.now().add(const Duration(days: 99));

        results.add(_ProductEntry(
          productId: doc.id,
          name: data['name'] as String? ?? '',
          price: minPrices[doc.id]!,
          discount: (data['discount'] as num?)?.toInt() ?? 0,
          expiryDate: expiryDate,
          mainImageUrl: data['mainImageUrl'] as String?,
          storeName: storeName,
        ));
      }

      setState(() {
        _products = results;
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySorting() {
    setState(() {
      if (_sort == _CategorySort.expiringSoon) {
        _products.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      } else {
        _products.sort((a, b) => a.price.compareTo(b.price));
      }
    });
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final tt = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text('Sort by', style: tt.titleMedium),
                ),
                _SortTile(
                  label: 'Expiring soon',
                  selected: _sort == _CategorySort.expiringSoon,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _sort = _CategorySort.expiringSoon);
                    _applySorting();
                  },
                ),
                _SortTile(
                  label: 'Lowest price',
                  selected: _sort == _CategorySort.lowestPrice,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _sort = _CategorySort.lowestPrice);
                    _applySorting();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_outlined),
            tooltip: 'Sort',
            onPressed: _openSortSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          headline: 'Could not load products',
          body: 'Check your connection and try again.',
          ctaLabel: 'Try again',
          onCta: _fetch,
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.shopping_bag_outlined,
          headline: 'Nothing here yet',
          body: 'No listed products in this category right now.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        return ProductCard.compact(
          productId: p.productId,
          name: p.name,
          price: p.price,
          discount: p.discount,
          expiryDate: p.expiryDate,
          mainImageUrl: p.mainImageUrl,
          storeName: p.storeName,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _ProductEntry {
  const _ProductEntry({
    required this.productId,
    required this.name,
    required this.price,
    required this.discount,
    required this.expiryDate,
    this.mainImageUrl,
    this.storeName,
  });

  final String productId;
  final String name;
  final double price;
  final int discount;
  final DateTime expiryDate;
  final String? mainImageUrl;
  final String? storeName;
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(label, style: tt.bodyLarge),
      trailing: selected
          ? Icon(Icons.check_rounded, color: cs.primary)
          : null,
      onTap: onTap,
    );
  }
}
