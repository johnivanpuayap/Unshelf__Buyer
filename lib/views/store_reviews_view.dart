import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/store_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/components/custom_navigation_bar.dart';

class StoreReviewsView extends StatefulWidget {
  final String storeId;
  StoreReviewsView({required this.storeId});
  @override
  _StoreReviewsViewState createState() => _StoreReviewsViewState();
}

class _StoreReviewsViewState extends State<StoreReviewsView> {
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
  }

  Future<Map<String, String>> _fetchStoreDetails() async {
    final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
    if (storeSnapshot.exists) {
      final storeData = storeSnapshot.data();
      return {
        'storeName': storeData?['store_name'] ?? 'No Store Name',
        'storeImageUrl': storeData?['store_image_url'] ?? '',
      };
    }
    return {'storeName': 'No Store Name', 'storeImageUrl': ''};
  }

  Widget _buildReviewCard(Map<String, dynamic> data, String sellerId) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ValueNotifier<int> _rating = ValueNotifier<int>(data['rating']);

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            enableFeedback: false,
                            onPressed: () => {},
                            icon: ValueListenableBuilder<int>(
                              valueListenable: _rating,
                              builder: (context, value, _) => Icon(
                                Icons.star,
                                color: value > index ? Colors.amber : cs.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['description']}",
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Divider(
          thickness: 0.5,
          height: 1,
          color: cs.outline.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final reviewsRef = FirebaseFirestore.instance.collection('stores').doc(widget.storeId).collection('reviews');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          "Reviews",
          style: tt.headlineSmall?.copyWith(color: cs.onPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: cs.primary.withValues(alpha: 0.6),
            height: 4.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "This store doesn't have any reviews yet.",
                style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            );
          }

          // Extract product IDs from favorites
          List<String> reviewIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reviewDoc = snapshot.data!.docs[index];
              final reviewId = reviewDoc.id; // This is also the order ID

              // Use the provided card styling
              return _buildReviewCard(reviewDoc.data() as Map<String, dynamic>, reviewId);
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
