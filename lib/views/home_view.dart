import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/product_bundle_view.dart';
import 'package:unshelf_buyer/views/profile_favorites_view.dart';
import 'package:unshelf_buyer/views/search_view.dart';
import 'package:unshelf_buyer/components/category_row_widget.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
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
                // Search icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                Expanded(
                  child: Text(
                    "Search",
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: cs.outline,
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
                    borderRadius: BorderRadius.circular(12),
                    splashColor: cs.onSurface.withValues(alpha: 0.08),
                    splashFactory: InkRipple.splashFactory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Icon(Icons.favorite_border, color: cs.onSurface.withValues(alpha: 0.6)),
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
            color: cs.primary.withValues(alpha: 0.6),
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
            backgroundColor: cs.surface,
            child: Icon(Icons.shopping_basket_outlined, color: cs.onSurface.withValues(alpha: 0.6)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BasketView()),
              );
            },
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'message',
            backgroundColor: cs.surface,
            child: Icon(Icons.message_outlined, color: cs.onSurface.withValues(alpha: 0.6)),
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
              Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(),
              _buildProductCarousel(products),
              Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
              _buildBundleDealsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCarousel(List<DocumentSnapshot> products) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
          child: Text(
            "Hot Products",
            style: tt.titleLarge,
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
              "PHP ${(data['price']!.toDouble() * (1 - data['discount'] / 100).toDouble()).toStringAsFixed(2)}",
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
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                      ),
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
