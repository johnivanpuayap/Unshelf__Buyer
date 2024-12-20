import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';
import 'package:unshelf_buyer/views/chat_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_address_view.dart';
import 'package:unshelf_buyer/views/store_reviews_view.dart';

class StoreView extends StatefulWidget {
  final String storeId;
  StoreView({required this.storeId});
  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, double> minPrices = {};
  late TextEditingController _searchController;
  String searchQuery = "";
  bool isFollowing = false;
  int followerCount = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });

    _checkIfFollow();
    // Fetch store details
    Provider.of<StoreViewModel>(context, listen: false).fetchStoreDetails(widget.storeId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFollow() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var followDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').doc(widget.storeId).get();

      setState(() {
        isFollowing = followDoc.exists;
      });
    }
  }

  Future<void> _toggleFollow() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var followRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').doc(widget.storeId);
      var storeRef = FirebaseFirestore.instance.collection('stores').doc(widget.storeId);

      // Update UI immediately when button is toggled
      setState(() {
        if (isFollowing) {
          // Decrease follow count optimistically
          followerCount -= 1;
        } else {
          // Increase follow count optimistically
          followerCount += 1;
        }
        isFollowing = !isFollowing; // Toggle the following state
      });

      // Perform Firebase operations afterward
      try {
        if (isFollowing) {
          await followRef.set({'added_at': FieldValue.serverTimestamp()});
        } else {
          await followRef.delete();
        }
        await storeRef.update({'follower_count': followerCount});
      } catch (e) {
        // If Firebase operations fail, revert the UI changes
        setState(() {
          if (isFollowing) {
            followerCount -= 1;
          } else {
            followerCount += 1;
          }
          isFollowing = !isFollowing; // Revert following state
        });

        // Optionally show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status. Please try again.')),
        );
      }

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFollowing ? 'You are now following the store!' : 'You have stopped following the store.')),
      );
    }
  }

  Future<List<DocumentSnapshot>> _fetchBundles() async {
    final snapshot = await _firestore.collection('bundles').where('sellerId', isEqualTo: widget.storeId).get();

    return snapshot.docs;
  }

  Widget _buildProductCarousel(List<DocumentSnapshot> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(
            "Products",
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            padEnds: true,
            viewportFraction: 0.4,
            enableInfiniteScroll: false,
            initialPage: 1,
          ),
          items: products.map((product) {
            final data = product.data() as Map<String, dynamic>;
            final productId = product.id;
            return _buildProductCard(data, productId, false, context);
          }).toList(),
        ),
      ],
    );
  }

  Future<List<DocumentSnapshot>> _fetchListedProducts() async {
    var batchesSnapshot = await _firestore.collection('batches').where('isListed', isEqualTo: true).get();
    List<String> productIds = batchesSnapshot.docs.map((doc) => doc['productId'] as String).toSet().toList();

    // get minimum prices for each product
    for (var batch in batchesSnapshot.docs) {
      Map tempData = (batch.data() as Map);
      String tempProductId = tempData['productId'];
      double tempPrice = tempData['price'].toDouble();
      if (!minPrices.containsKey(tempProductId) || tempPrice < minPrices[tempProductId]!) {
        minPrices[tempProductId] = tempPrice;
      }
    }

    if (productIds.isEmpty) return [];
    var productsSnapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: productIds)
        .where('sellerId', isEqualTo: widget.storeId)
        .get();

    return productsSnapshot.docs;
  }

  Widget _buildBundleDealsSection() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchBundles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final bundles = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                "Bundle Deals",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                padEnds: true,
                viewportFraction: 0.4,
                enableInfiniteScroll: false,
                initialPage: 1,
              ),
              items: bundles.map((bundle) {
                final data = bundle.data() as Map<String, dynamic>;
                final bundleId = bundle.id;
                return _buildProductCard(data, bundleId, true, context);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String productId, bool isBundle, BuildContext context) {
    return GestureDetector(
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
      child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: 140,
            clipBehavior: Clip.none,
            margin: const EdgeInsets.only(top: 10),
            // decoration: BoxDecoration(
            //   boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 1, offset: const Offset(0, 5))],
            // ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: data['mainImageUrl'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            alignment: WrapAlignment.start,
            children: [
              Text(
                data['name'],
                style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          if (isBundle)
            Text(
              "PHP ${data['price']!.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            )
          else
            Text(
              "PHP ${minPrices[productId]!.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
        ],
      )),
    );
  }

  // Widget _buildProductCard(Map<String, dynamic> productData, String productId, bool isBundle, BuildContext context) {
  //   return FutureBuilder<QuerySnapshot>(
  //     future: FirebaseFirestore.instance
  //         .collection('batches')
  //         .where('productId', isEqualTo: productId)
  //         .where('isListed', isEqualTo: true)
  //         .where('stock', isGreaterThan: 0)
  //         .get(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //         return const SizedBox.shrink();
  //       }

  //       var batch = snapshot.data!.docs.first; // Use the first batch as default.
  //       var batchData = batch.data() as Map<String, dynamic>;

  //       return GestureDetector(
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => ProductPage(productId: productId),
  //             ),
  //           );
  //         },
  //         child: Card(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(15.0),
  //             side: const BorderSide(color: Color(0xA7C957), width: 10),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Stack(
  //                 children: [
  //                   CachedNetworkImage(
  //                     imageUrl: productData['mainImageUrl'],
  //                     height: 100,
  //                     width: double.infinity,
  //                     fit: BoxFit.cover,
  //                   ),
  //                   if (productData['discount'] != null)
  //                     Positioned(
  //                       top: 8,
  //                       left: 8,
  //                       child: Container(
  //                         color: Colors.red,
  //                         padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
  //                         child: Text(
  //                           '${productData['discount']}% off',
  //                           style: const TextStyle(color: Colors.white, fontSize: 12),
  //                         ),
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: Text(
  //                   productData['name'],
  //                   style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //               Text(
  //                 '  PHP${batchData['price'].toStringAsFixed(2)}',
  //                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0AB68B)),
  //               ),
  //               // Text(
  //               //   '  ${batchData['quantity']} in stock',
  //               //   style: const TextStyle(fontSize: 12, color: Colors.grey),
  //               // ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        // title: const Text(
        //   'Store View',
        //   style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
        // ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFF0AB68B),
      ),
      body: Consumer<StoreViewModel>(
        builder: (context, storeViewModel, child) {
          if (storeViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (storeViewModel.errorMessage != null) {
            return Center(
              child: Text(storeViewModel.errorMessage!),
            );
          }

          if (storeViewModel.storeDetails == null) {
            return const Center(child: Text('No store data available'));
          }

          var storeDetails = storeViewModel.storeDetails!;
          followerCount = storeDetails.storeFollowers ?? 0;

          return FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchListedProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("This store currently has no listings."));
              }

              final products = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Header
                    Container(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10, bottom: 20.0),
                      color: const Color(0xFF0AB68B),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: CachedNetworkImageProvider(storeDetails.storeImageUrl ?? ''),
                          ),
                          const SizedBox(width: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeDetails.storeName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(
                                    width: 5.0,
                                  ),
                                  Text(
                                    '${storeDetails.storeRating?.toDouble().toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 15, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.add_reaction, color: Colors.amber, size: 16),
                                  const SizedBox(
                                    width: 5.0,
                                  ),
                                  Text(
                                    '${storeDetails.storeFollowers ?? 0}',
                                    style: const TextStyle(fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _toggleFollow,
                                icon: Icon(
                                  isFollowing ? Icons.favorite : Icons.favorite_border,
                                  color: isFollowing ? Colors.yellow : Colors.white,
                                  size: 28,
                                ),
                                tooltip: isFollowing ? 'Unfollow' : 'Follow',
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatView(
                                        receiverName: storeDetails.storeName,
                                        receiverUserID: widget.storeId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.yellow,
                                  size: 28,
                                ),
                                tooltip: 'Chat',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PreferredSize(
                      preferredSize: const Size.fromHeight(4.0),
                      child: Container(
                        color: const Color(0xFF92DE8B),
                        height: 6.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    // View in Maps
                    Row(
                      children: [
                        const SizedBox(width: 10.0),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreAddressView(
                                  latitude: storeDetails.storeLatitude,
                                  longitude: storeDetails.storeLongitude,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Location'),
                        ),
                        const SizedBox(width: 10.0),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreReviewsView(
                                  storeId: widget.storeId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Reviews'),
                        ),
                      ],
                    ),
                    _buildProductCarousel(products),
                    _buildBundleDealsSection(),
                    // Category Listings: Offers, Grocery, Fruits, Veggies, Baked
                    // for (var category in ['Offers', 'Grocery', 'Fruits', 'Vegetables', 'Baked Goods'])
                    //   StreamBuilder<QuerySnapshot>(
                    //     stream: FirebaseFirestore.instance
                    //         .collection('products')
                    //         .where('sellerId', isEqualTo: widget.storeId)
                    //         .where('category', isEqualTo: category)
                    //         .snapshots(),
                    //     builder: (context, snapshot) {
                    //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    //         return const SizedBox.shrink(); // Skip if no products
                    //       }
                    //       var productDocs = snapshot.data!.docs;
                    //       return Container(
                    //         height: 220,
                    //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               category.toUpperCase(),
                    //               style: const TextStyle(
                    //                 fontSize: 18,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: Color(0xFF0AB68B),
                    //               ),
                    //             ),
                    //             const SizedBox(height: 8.0),
                    //             Expanded(
                    //               child: ListView.builder(
                    //                 scrollDirection: Axis.horizontal,
                    //                 itemCount: productDocs.length,
                    //                 itemBuilder: (context, index) {
                    //                   var productData = productDocs[index].data() as Map<String, dynamic>;
                    //                   var productId = productDocs[index].id;
                    //                   var isBundle = productData['isBundle'] ?? false;

                    //                   return Container(
                    //                     width: 160,
                    //                     margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    //                     child: _buildProductCard(productData, productId, isBundle, context),
                    //                   );
                    //                 },
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       );
                    //     },
                    //   ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
