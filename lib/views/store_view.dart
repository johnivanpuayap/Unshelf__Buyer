import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';
import 'package:unshelf_buyer/views/chat_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_address_view.dart';
import 'package:unshelf_buyer/views/store_reviews_view.dart';

class StoreView extends ConsumerStatefulWidget {
  final String storeId;
  StoreView({required this.storeId});
  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends ConsumerState<StoreView> {
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
    // fetchStoreDetails is triggered automatically by the family provider build().
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
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(
            "Products",
            style: tt.titleLarge,
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
    final tt = Theme.of(context).textTheme;
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: Text(
                "Bundle Deals",
                style: tt.titleLarge,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
            margin: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: data['mainImageUrl'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.start,
            children: [
              Text(
                data['name'],
                style: tt.titleSmall?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
          if (isBundle)
            Text(
              "PHP ${data['price']!.toStringAsFixed(2)}",
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            )
          else
            Text(
              "PHP ${minPrices[productId]!.toStringAsFixed(2)}",
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: cs.primary,
      ),
      body: Builder(
        builder: (context) {
          final storeState = ref.watch(storeViewModelProvider(widget.storeId));

          if (storeState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (storeState.errorMessage != null) {
            return Center(
              child: Text(storeState.errorMessage!),
            );
          }

          if (storeState.storeDetails == null) {
            return const Center(child: Text('No store data available'));
          }

          var storeDetails = storeState.storeDetails!;
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
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8, bottom: 20.0),
                      color: cs.primary,
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
                                style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${storeDetails.storeRating?.toDouble().toStringAsFixed(2)}',
                                    style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.add_reaction, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${storeDetails.storeFollowers ?? 0}',
                                    style: tt.bodyMedium?.copyWith(color: cs.onPrimary),
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
                                  color: isFollowing ? Colors.amber : cs.onPrimary,
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
                                icon: Icon(
                                  Icons.chat,
                                  color: cs.onPrimary,
                                  size: 28,
                                ),
                                tooltip: 'Chat',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: cs.primary.withValues(alpha: 0.6),
                      height: 4.0,
                    ),
                    const SizedBox(height: 8.0),
                    // View in Maps
                    Row(
                      children: [
                        const SizedBox(width: 8.0),
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
                        const SizedBox(width: 8.0),
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
