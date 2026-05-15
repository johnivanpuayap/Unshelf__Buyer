import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/components/category_row_widget.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';

class SearchView extends StatefulWidget {
  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, double> minPrices = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 80,
        title: Container(
          height: 50,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
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
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    // Remove default InputDecorationTheme padding/fill for this inline field
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  onChanged: (query) {
                    _performSearch(query);
                  },
                  onSubmitted: (query) => _performSearch(query),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: cs.primary.withValues(alpha: 0.6),
            height: 4.0,
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String productId, bool isBundle, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                  return isBundle ? BundleView(bundleId: productId) : ProductPage(productId: productId);
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: data['mainImageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'], // Product Name
                        style: tt.titleSmall?.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PHP ${minPrices[productId]?.toStringAsFixed(2) ?? 'N/A'}", // Price
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['store_name'] ?? "Unknown Store", // Store Name
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Divider between product cards
        Divider(
          thickness: 0.5,
          height: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isNotEmpty) {
      // Fetch all batches where `isListed` is true
      var batchesSnapshot = await _firestore.collection('batches').where('isListed', isEqualTo: true).get();

      // Extract product IDs from batches
      List<String> productIds = batchesSnapshot.docs.map((doc) => doc['productId'] as String).toSet().toList();

      // Build the minPrices map for each product
      minPrices.clear();
      for (var batch in batchesSnapshot.docs) {
        Map tempData = batch.data();
        String tempProductId = tempData['productId'];
        double tempPrice = tempData['price'].toDouble();
        if (!minPrices.containsKey(tempProductId) || tempPrice < minPrices[tempProductId]!) {
          minPrices[tempProductId] = tempPrice;
        }
      }

      // Fetch all products matching the name query (no need for documentId filtering yet)
      final searchSnapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query')
          .get();

      // List to hold the final filtered products with their store data
      List<Map<String, dynamic>> searchResults = [];

      // Loop through each product document from the query
      for (var productDoc in searchSnapshot.docs) {
        final productData = productDoc.data() as Map<String, dynamic>; // Get product data

        // Only include products whose document ID is in the productIds list
        if (productIds.contains(productDoc.id)) {
          // Fetch the store details for each product
          final sellerId = productData['sellerId']; // Get sellerId
          final storeSnapshot = await _firestore.collection('stores').doc(sellerId).get();

          // Retrieve store data if store exists
          if (storeSnapshot.exists) {
            productData['store_name'] = storeSnapshot['store_name'];
            productData['store_image_url'] = storeSnapshot['store_image_url'];
          } else {
            productData['store_name'] = 'Unknown Store'; // Fallback
            productData['store_image_url'] = ''; // Fallback
          }

          // Add the product data (with store details) to searchResults
          searchResults.add({
            'productId': productDoc.id, // Include productId (document ID)
            ...productData, // Include product data and store data
          });
        }
      }

      // Update state with the final results
      setState(() {
        _searchResults = searchResults; // Update the search results
      });
    }
  }

  Widget _buildSearchResults() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          "No results found.",
          style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final data = _searchResults[index];
        final productId = _searchResults[index]['productId'];

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildProductCard(data, productId, false, context),
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchBundles() async {
    final snapshot = await _firestore.collection('bundles').get();

    return snapshot.docs;
  }
}
