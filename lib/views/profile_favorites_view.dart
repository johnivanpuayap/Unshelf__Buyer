import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({Key? key}) : super(key: key);

  Future<void> _removeFromFavorites(String productId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoriteRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(productId);

    await favoriteRef.delete();
  }

  Future<bool> _productHasBatch(String productId) async {
    final batchSnapshot = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: productId)
        .where('isListed', isEqualTo: true)
        .limit(1)
        .get();
    return batchSnapshot.docs.isNotEmpty;
  }

  Future<Map<String, String>> _fetchStoreDetails(String storeId) async {
    final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    if (storeSnapshot.exists) {
      final storeData = storeSnapshot.data();
      return {
        'storeName': storeData?['store_name'] ?? 'No Store Name',
        'storeImageUrl': storeData?['store_image_url'] ?? '',
      };
    }
    return {'storeName': 'No Store Name', 'storeImageUrl': ''};
  }

  Future<Map<String, double>> _getMinPrices(List<String> productIds) async {
    Map<String, double> minPrices = {};

    for (String productId in productIds) {
      final batchSnapshot = await FirebaseFirestore.instance
          .collection('batches')
          .where('productId', isEqualTo: productId)
          .where('isListed', isEqualTo: true)
          .get();

      if (batchSnapshot.docs.isNotEmpty) {
        double minPrice = double.infinity;

        for (var batch in batchSnapshot.docs) {
          final price = batch['price'].toDouble();
          if (price < minPrice) {
            minPrice = price;
          }
        }

        minPrices[productId] = minPrice;
      }
    }

    return minPrices;
  }

  Widget _buildProductCard(Map<String, dynamic> data, String storeName, String storeImageUrl, String productId,
      BuildContext context, Map<String, double> minPrices) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                  return ProductPage(productId: productId);
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: data['mainImageUrl'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'],
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PHP ${minPrices[productId]?.toStringAsFixed(2) ?? 'N/A'}",
                        style: tt.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeName,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.favorite, color: cs.primary),
                  onPressed: () {
                    _removeFromFavorites(productId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Successfully removed from favorites.'),
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 0.5, color: cs.outline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "My Favorites",
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(color: cs.secondary, height: 4.0),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No favorites yet.', style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            );
          }

          List<String> productIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return FutureBuilder<Map<String, double>>(
            future: _getMinPrices(productIds),
            builder: (context, minPriceSnapshot) {
              if (minPriceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final minPrices = minPriceSnapshot.data ?? {};

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final favoriteDoc = snapshot.data!.docs[index];
                  final productId = favoriteDoc.id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final productData = productSnapshot.data!;
                      final storeId = productData['sellerId'] as String;

                      return FutureBuilder<Map<String, String>>(
                        future: _fetchStoreDetails(storeId),
                        builder: (context, storeSnapshot) {
                          if (storeSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          return FutureBuilder<bool>(
                            future: _productHasBatch(productId),
                            builder: (context, batchSnapshot) {
                              if (batchSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!batchSnapshot.hasData || !batchSnapshot.data!) {
                                return const SizedBox.shrink();
                              }

                              final storeName = storeSnapshot.data?['storeName'] ?? 'Unknown Store';
                              final storeImageUrl = storeSnapshot.data?['storeImageUrl'] ?? '';
                              final price = minPrices[productId];

                              if (price == null) {
                                return const SizedBox.shrink();
                              }

                              return _buildProductCard(productData.data() as Map<String, dynamic>, storeName, storeImageUrl,
                                  productId, context, minPrices);
                            },
                          );
                        },
                      );
                    },
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
