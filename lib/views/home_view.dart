import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/profile_favorites_view.dart';
import 'package:unshelf_buyer/views/search_view.dart';
import 'package:unshelf_buyer/widgets/category_row_widget.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/widgets/custom_navigation_bar.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, double> minPrices = {};

  Future<List<DocumentSnapshot>> _fetchListedProducts() async {
    var batchesSnapshot = await _firestore.collection('batches').where('isListed', isEqualTo: true).get();
    List<String> productIds = batchesSnapshot.docs.map((doc) => doc['productId'] as String).toSet().toList();

    // get minimum prices for each product
    for (var batch in batchesSnapshot.docs) {
      Map tempData = (batch.data() as Map);
      double discount = tempData['discount'].toDouble();
      String tempProductId = tempData['productId'];
      double tempPrice = tempData['price'].toDouble() * ((1 - discount / 100).toDouble());
      if (!minPrices.containsKey(tempProductId) || tempPrice < minPrices[tempProductId]!) {
        minPrices[tempProductId] = tempPrice;
      }
    }

    if (productIds.isEmpty) return [];
    var productsSnapshot = await _firestore.collection('products').where(FieldPath.documentId, whereIn: productIds).get();

    return productsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0AB68B),
        elevation: 0,
        toolbarHeight: 80,
        title: GestureDetector(
          onTap: () {
            // Navigate to SearchView on tap
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                  return SearchView();
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 0),
                )
              ],
            ),
            child: Row(
              children: [
                // Search icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.search, color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    "Search",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey[300],
                ),
                // Favorites icon with ripple effect
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigate to Favorites Page
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
                            return const FavoritesView();
                          },
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    splashColor: Colors.grey.withOpacity(0.3),
                    splashFactory: InkRipple.splashFactory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Icon(Icons.favorite_border, color: Colors.grey[600]),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color(0xFF92DE8B),
            height: 4.0,
          ),
        ),
      ),

      body: _buildHomeContent(),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'basket',
            backgroundColor: Colors.white,
            child: Icon(Icons.shopping_basket_outlined, color: Colors.grey[600]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BasketView()),
              );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'message',
            backgroundColor: Colors.white,
            child: Icon(Icons.message_outlined, color: Colors.grey[600]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNavigationBar(
        currentIndex: 0, // Set the active tab index
      ),
    );
  }

  Widget _buildHomeContent() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchListedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products available."));
        }

        final products = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: [
              CategoryIconsRow(),
              _buildCarouselBanner(),
              Divider(color: Colors.grey[200]),
              const SizedBox(),
              _buildProductCarousel(products),
              Divider(color: Colors.grey[200]),
              _buildBundleDealsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCarousel(List<DocumentSnapshot> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(
            "Hot Products",
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            padEnds: true,
            viewportFraction: 0.4,
            enableInfiniteScroll: true,
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
              "PHP ${(data['price']!.toDouble() * (1 - data['discount'] / 100).toDouble()).toStringAsFixed(2)}",
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

  Widget _buildCarouselBanner() {
    return FutureBuilder<List<String>>(
      future: _getBannerImageUrls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No banners available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CarouselSlider(
            options: CarouselOptions(height: 150.0, autoPlay: true),
            items: snapshot.data!.map((url) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<List<String>> _getBannerImageUrls() async {
    try {
      final ListResult result = await _storage.ref('banner_images').listAll();
      final List<String> imageUrls = await Future.wait(
        result.items.map((Reference ref) => ref.getDownloadURL()).toList(),
      );
      return imageUrls;
    } catch (e) {
      print('Error fetching banner images: $e');
      return [];
    }
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
                enableInfiniteScroll: true,
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

  Future<List<DocumentSnapshot>> _fetchBundles() async {
    final snapshot = await _firestore.collection('bundles').get();

    return snapshot.docs;
  }
}
