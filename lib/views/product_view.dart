import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  ProductPage({required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _quantity = 1;
  Map<String, dynamic>? sellerData;
  bool isFavorite = false;

  List<DocumentSnapshot>? _batches;
  DocumentSnapshot? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _checkIfFavorite();
    _fetchBatches();
  }

  Future<void> _fetchSellerData() async {
    var productSnapshot = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    var productData = productSnapshot.data() as Map<String, dynamic>;

    var sellerSnapshot = await FirebaseFirestore.instance.collection('stores').doc(productData['sellerId']).get();
    setState(() {
      sellerData = sellerSnapshot.data();
    });
  }

  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoriteDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(widget.productId).get();

      setState(() {
        isFavorite = favoriteDoc.exists;
      });
    }
  }

  Future<void> _fetchBatches() async {
    var batchDocs = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: widget.productId)
        .where('isListed', isEqualTo: true)
        .get();

    setState(() {
      _batches = batchDocs.docs;
      if (_batches!.isNotEmpty) {
        _selectedBatch = _batches!.first; // Default batch
      }
    });
  }

  void _onBatchSelected(DocumentSnapshot? batch) {
    setState(() {
      _selectedBatch = batch;
    });
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoriteRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(widget.productId);

      if (isFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({'added_at': FieldValue.serverTimestamp(), 'is_bundle': false});
      }

      setState(() {
        isFavorite = !isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFavorite ? 'Added to Favorites' : 'Removed from Favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var productData = snapshot.data!.data() as Map<String, dynamic>;
          final batchData = _selectedBatch?.data() as Map<String, dynamic>?;

          double tempPrice = batchData?['price'].toDouble() ?? productData?['price'].toDouble();
          double finalPrice = tempPrice * (1 - batchData?['discount'] / 100).toDouble();
          batchData?['price'] = finalPrice;
          productData?['price'] = finalPrice;

          return Column(
            children: [
              Stack(
                children: [
                  InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: productData['mainImageUrl'],
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.5,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 40.0,
                    left: 16.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.white.withOpacity(0.6),
                      mini: true,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  Positioned(
                    top: 40.0,
                    right: 16.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BasketView(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      backgroundColor: Colors.white.withOpacity(0.6),
                      mini: true,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.shopping_basket, color: Colors.black),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productData['name'],
                            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: const Color(0xFF0AB68B),
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\u{20B1}${batchData?['price']?.toStringAsFixed(2) ?? productData['price']}/${productData['quantifier'] ?? 'unit'}',
                            style: const TextStyle(fontSize: 20, color: Color(0xFF0AB68B), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            batchData != null && batchData['expiryDate'] != null
                                ? 'Expires: ${DateFormat('MM/d/yy').format((batchData['expiryDate'] as Timestamp).toDate())}'
                                : 'Expires: Loading...',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      // Divider
                      Divider(color: Colors.grey[200]),
                      const SizedBox(height: 5.0),
                      GestureDetector(
                        onTap: () {
                          if (sellerData != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreView(storeId: productData['sellerId']),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      sellerData != null ? CachedNetworkImageProvider(sellerData!['store_image_url']) : null,
                                  radius: 20,
                                ),
                                const SizedBox(width: 15.0),
                                Text(
                                  sellerData != null ? sellerData!['store_name'] : 'Loading...',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20.0),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 138),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Text(
                                'Visit >',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 250, 134, 0),
                                ),
                              ),
                            ),
                            // Text(
                            //   'Distance: 6 km',
                            //   style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                            // ),
                          ],
                        ),
                      ),
                      // Divider
                      Divider(color: Colors.grey[200]),
                      // Space
                      const SizedBox(height: 10.0),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        productData['description'],
                        style: const TextStyle(fontSize: 18),
                      ),
                      // Space
                      const SizedBox(height: 10.0),
                      // Divider
                      Divider(color: Colors.grey[200]),
                      // Space
                      const SizedBox(height: 10.0),
                      // Dropdown HEADER
                      const Text(
                        'Choose a Batch',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      // Dropdown
                      if (_batches != null && _batches!.isNotEmpty)
                        DropdownButton<DocumentSnapshot>(
                          elevation: 5,
                          value: _selectedBatch,
                          isExpanded: true,
                          onChanged: _onBatchSelected,
                          items: _batches!.map((batch) {
                            final batchInfo = batch.data() as Map<String, dynamic>;
                            return DropdownMenuItem<DocumentSnapshot>(
                              value: batch,
                              child: Text(
                                'Batch: ${batchInfo['batchNumber']} (${batchInfo['stock']})',
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text(
                      _quantity.toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _selectedBatch != null ? () => _addToCart(context, _selectedBatch!.id, _quantity) : null,
              // Disable button until a batch is loaded
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0AB68B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("ADD TO CART", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, String batchId, int quantity) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('baskets')
            .doc(user.uid)
            .collection('cart_items')
            .doc(batchId)
            .set({'quantity': quantity});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to add items to cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    }
  }
}
