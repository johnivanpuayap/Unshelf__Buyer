import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/components/empty_state_view.dart';
import 'package:unshelf_buyer/components/product_card.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  Future<bool> _productHasBatch(String productId) async {
    final snap = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: productId)
        .where('isListed', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<_FavoriteProduct?> _buildFavoriteProduct(String productId) async {
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!productDoc.exists) return null;

    final hasBatch = await _productHasBatch(productId);
    if (!hasBatch) return null;

    final data = productDoc.data()!;
    final storeId = data['sellerId'] as String;

    // Fetch cheapest active batch
    final batchSnap = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: productId)
        .where('isListed', isEqualTo: true)
        .get();

    double minPrice = double.infinity;
    int discount = 0;
    DateTime? expiryDate;

    for (final b in batchSnap.docs) {
      final price = (b['price'] as num).toDouble();
      if (price < minPrice) {
        minPrice = price;
        discount = (b['discount'] as num?)?.toInt() ?? 0;
        final ts = b['expiryDate'];
        if (ts is Timestamp) expiryDate = ts.toDate();
      }
    }

    if (minPrice == double.infinity || expiryDate == null) return null;

    // Store name
    final storeDoc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
    final storeName =
        storeDoc.exists ? (storeDoc['store_name'] as String?) ?? '' : '';

    return _FavoriteProduct(
      productId: productId,
      name: data['name'] as String? ?? '',
      price: minPrice,
      discount: discount,
      expiryDate: expiryDate,
      mainImageUrl: data['mainImageUrl'] as String?,
      storeName: storeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Favorites', style: tt.titleLarge),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: EmptyStateView(
                icon: Icons.favorite_outline,
                headline: 'No favorites yet',
                body: 'Tap the heart on any product to save it here.',
              ),
            );
          }

          final productIds =
              snapshot.data!.docs.map((d) => d.id).toList();

          return FutureBuilder<List<_FavoriteProduct?>>(
            future: Future.wait(
                productIds.map((id) => _buildFavoriteProduct(id))),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = (snap.data ?? [])
                  .whereType<_FavoriteProduct>()
                  .toList();

              if (items.isEmpty) {
                return Center(
                  child: EmptyStateView(
                    icon: Icons.favorite_outline,
                    headline: 'No favorites yet',
                    body:
                        'Tap the heart on any product to save it here.',
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ProductCard.compact(
                    productId: item.productId,
                    name: item.name,
                    price: item.price,
                    discount: item.discount,
                    expiryDate: item.expiryDate,
                    mainImageUrl: item.mainImageUrl,
                    storeName: item.storeName,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteProduct {
  const _FavoriteProduct({
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
