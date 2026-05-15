import 'package:unshelf_buyer/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/components/category_row_widget.dart';

class CategoryProductsPage extends StatefulWidget {
  final CategoryItem category;

  const CategoryProductsPage({required this.category});

  @override
  _CategoryProductsPageState createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _categoryProducts = [];
  Map<String, double> minPrices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryProducts();
  }

  Future<void> _fetchCategoryProducts() async {
    try {
      // Fetch all listed batches
      var batchesSnapshot = await _firestore.collection('batches').where('isListed', isEqualTo: true).get();

      minPrices.clear();
      List<String> productIds = [];
      for (var batch in batchesSnapshot.docs) {
        Map tempData = batch.data();
        String tempProductId = tempData['productId'];
        double tempPrice = tempData['price'].toDouble();

        if (!minPrices.containsKey(tempProductId) || tempPrice < minPrices[tempProductId]!) {
          minPrices[tempProductId] = tempPrice;
        }
        productIds.add(tempProductId);
      }

      final productsSnapshot =
          await _firestore.collection('products').where('category', isEqualTo: widget.category.categoryKey).get();

      List<Map<String, dynamic>> categoryResults = [];

      // Include only those with minPrices
      for (var productDoc in productsSnapshot.docs) {
        final productData = productDoc.data() as Map<String, dynamic>;

        if (minPrices.containsKey(productDoc.id)) {
          final sellerId = productData['sellerId'];

          // Fetch store details
          final storeSnapshot = await _firestore.collection('stores').doc(sellerId).get();
          if (storeSnapshot.exists) {
            productData['store_name'] = storeSnapshot['store_name'];
            productData['store_image_url'] = storeSnapshot['store_image_url'];
          } else {
            productData['store_name'] = 'Unknown Store';
            productData['store_image_url'] = '';
          }

          // Merge productData and minPrice
          categoryResults.add({
            'productId': productDoc.id,
            'minPrice': minPrices[productDoc.id],
            ...productData,
          });
        }
      }

      setState(() {
        _categoryProducts = categoryResults;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching products: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductPage(productId: product['productId']),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: product['mainImageUrl'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 30),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'No Name',
                        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['minPrice'] != null ? "PHP ${product['minPrice'].toStringAsFixed(2)}" : "No price available",
                        style: const TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['store_name'] ?? "Unknown Store",
                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                    ],
                  ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          widget.category.categoryName,
          style: const TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoryProducts.isEmpty
              ? Center(
                  child: Text(
                    "No listed products in this category",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16.0),
                  ),
                )
              : ListView.builder(
                  itemCount: _categoryProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_categoryProducts[index]);
                  },
                ),
    );
  }
}
