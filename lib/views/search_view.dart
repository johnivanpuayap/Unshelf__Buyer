/// SearchView — full search experience.
///
/// Top bar: theme-styled search field.
/// Filter chips: All / Bakery / Produce / Grocery / Baked goods.
/// Results: 2-column [ProductCard.compact] grid.
/// Empty states:
///   • No query → "Find near-expiry food" prompt.
///   • Query but no results → "No matches for '$query'".
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/product_card.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<_SearchResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _activeQuery = '';
  String? _selectedCategory; // null = All

  static const List<String> _categoryFilters = [
    'Grocery',
    'Fruits',
    'Vegetables',
    'Baked Goods',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _activeQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeQuery = trimmed;
    });

    try {
      // 1. Listed batches → minPrices
      final batchesSnap = await _firestore
          .collection('batches')
          .where('isListed', isEqualTo: true)
          .get();

      final Map<String, double> minPrices = {};
      final Set<String> listedProductIds = {};
      for (final doc in batchesSnap.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final price = (data['price'] as num?)?.toDouble();
        if (productId == null || price == null) continue;
        listedProductIds.add(productId);
        if (!minPrices.containsKey(productId) || price < minPrices[productId]!) {
          minPrices[productId] = price;
        }
      }

      // 2. Name prefix-range search
      QuerySnapshot productsSnap;
      if (_selectedCategory != null) {
        productsSnap = await _firestore
            .collection('products')
            .where('name', isGreaterThanOrEqualTo: trimmed)
            .where('name', isLessThanOrEqualTo: '$trimmed')
            .where('category', isEqualTo: _selectedCategory)
            .get();
      } else {
        productsSnap = await _firestore
            .collection('products')
            .where('name', isGreaterThanOrEqualTo: trimmed)
            .where('name', isLessThanOrEqualTo: '$trimmed')
            .get();
      }

      final List<_SearchResult> results = [];

      for (final doc in productsSnap.docs) {
        if (!listedProductIds.contains(doc.id)) continue;

        final data = doc.data() as Map<String, dynamic>;
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

        DateTime? expiryDate;
        final rawExpiry = data['expiryDate'];
        if (rawExpiry is Timestamp) {
          expiryDate = rawExpiry.toDate();
        } else if (rawExpiry is String) {
          expiryDate = DateTime.tryParse(rawExpiry);
        }
        expiryDate ??= DateTime.now().add(const Duration(days: 99));

        results.add(_SearchResult(
          id: doc.id,
          name: data['name'] as String? ?? '',
          price: minPrices[doc.id]!,
          discount: (data['discount'] as num?)?.toInt() ?? 0,
          expiryDate: expiryDate,
          mainImageUrl: data['mainImageUrl'] as String?,
          storeName: storeName,
          isBundle: false,
        ));
      }

      // 3. Also search bundles
      final bundlesSnap = await _firestore
          .collection('bundles')
          .where('name', isGreaterThanOrEqualTo: trimmed)
          .where('name', isLessThanOrEqualTo: '$trimmed')
          .get();

      for (final doc in bundlesSnap.docs) {
        final data = doc.data();
        final price = (data['price'] as num?)?.toDouble() ?? 0;

        results.add(_SearchResult(
          id: doc.id,
          name: data['name'] as String? ?? '',
          price: price,
          discount: 0,
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          mainImageUrl: data['mainImageUrl'] as String?,
          storeName: null,
          isBundle: true,
        ));
      }

      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_outlined),
              hintText: 'Search products…',
              // Rely on InputDecorationTheme for fill, border, radius
            ),
            onChanged: _performSearch,
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            _FilterChipRow(
              categories: _categoryFilters,
              selected: _selectedCategory,
              onSelected: (cat) {
                setState(() => _selectedCategory = cat);
                if (_activeQuery.isNotEmpty) _performSearch(_activeQuery);
              },
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildResults(cs, tt)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ColorScheme cs, TextTheme tt) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.search_outlined,
          headline: 'Find near-expiry food',
          body: 'Type a product name to see what\'s available nearby.',
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: Icons.search_off_outlined,
          headline: 'No matches for "$_activeQuery"',
          body: 'Try a different name or remove the category filter.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final r = _results[index];
        if (r.isBundle) {
          return _BundleCard(id: r.id, name: r.name, price: r.price, imageUrl: r.mainImageUrl);
        }
        return ProductCard.compact(
          productId: r.id,
          name: r.name,
          price: r.price,
          discount: r.discount,
          expiryDate: r.expiryDate,
          mainImageUrl: r.mainImageUrl,
          storeName: r.storeName,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip row
// ---------------------------------------------------------------------------

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: selected == cat,
                  onSelected: (_) => onSelected(cat == selected ? null : cat),
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal bundle card (compact, same shape as ProductCard.compact)
// ---------------------------------------------------------------------------

class _BundleCard extends StatelessWidget {
  const _BundleCard({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BundleView(bundleId: id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF1F2A20).withValues(alpha: 0.06),
              offset: const Offset(0, 8),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1,
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(color: cs.outline.withValues(alpha: 0.12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: tt.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('PHP ${price.toStringAsFixed(2)}',
                      style: tt.labelLarge?.copyWith(color: cs.primary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    child: Text('Bundle deal', style: tt.labelSmall?.copyWith(color: cs.tertiary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data type
// ---------------------------------------------------------------------------

class _SearchResult {
  const _SearchResult({
    required this.id,
    required this.name,
    required this.price,
    required this.discount,
    required this.expiryDate,
    required this.isBundle,
    this.mainImageUrl,
    this.storeName,
  });

  final String id;
  final String name;
  final double price;
  final int discount;
  final DateTime expiryDate;
  final String? mainImageUrl;
  final String? storeName;
  final bool isBundle;
}
