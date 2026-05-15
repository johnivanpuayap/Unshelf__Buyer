import 'package:unshelf_buyer/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
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
    // Check if product has a batch
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
    // Fetch minimum prices for the products in the productIds list
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
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 0))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: data['mainImageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'], // Product Name
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PHP ${minPrices[productId]?.toStringAsFixed(2) ?? 'N/A'}", // Price
                        style: const TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeName ?? "Unknown Store", // Store Name
                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                    ],
                  ),
                ), // Heart button (Remove from favorites)
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.primaryColor),
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
        const SizedBox(
          height: 15,
        ),
        Divider(
          thickness: 0.2,
          height: 1,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "My Favorites",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: AppColors.lightColor,
            height: 6.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }

          // Extract product IDs from favorites
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

                      // Fetch store details
                      return FutureBuilder<Map<String, String>>(
                        future: _fetchStoreDetails(storeId),
                        builder: (context, storeSnapshot) {
                          if (storeSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          // If the product doesn't have a batch, skip
                          return FutureBuilder<bool>(
                            future: _productHasBatch(productId),
                            builder: (context, batchSnapshot) {
                              if (batchSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              // If the product doesn't have a batch, skip
                              if (!batchSnapshot.hasData || !batchSnapshot.data!) {
                                return const SizedBox.shrink();
                              }

                              final storeName = storeSnapshot.data?['storeName'] ?? 'Unknown Store';
                              final storeImageUrl = storeSnapshot.data?['storeImageUrl'] ?? '';
                              final price = minPrices[productId];

                              if (price == null) {
                                return const SizedBox.shrink();
                              }

                              // Use the provided card styling
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
