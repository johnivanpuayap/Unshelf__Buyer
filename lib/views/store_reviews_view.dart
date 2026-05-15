import 'package:unshelf_buyer/utils/colors.dart';
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

  Widget _buildProductCard(Map<String, dynamic> data, String sellerId) {
    final ValueNotifier<int> _rating = ValueNotifier<int>(data['rating']);

    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
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
                                color: value > index ? Colors.amber : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Text(
                      //   data['name'], // Product Name
                      //   style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black),
                      // ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['description']}",
                        style: const TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   storeName ?? "Unknown Store", // Store Name
                      //   style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      // ),
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
    final reviewsRef = FirebaseFirestore.instance.collection('stores').doc(widget.storeId).collection('reviews');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Reviews",
          style: TextStyle(color: Colors.white, fontSize: 25),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: AppColors.lightColor,
              height: 6.0,
            )),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("This store doesn't have any reviews yet."));
          }

          // Extract product IDs from favorites
          List<String> reviewIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reviewDoc = snapshot.data!.docs[index];
              final reviewId = reviewDoc.id; // This is also the order ID

              // Use the provided card styling
              return _buildProductCard(reviewDoc.data() as Map<String, dynamic>, reviewId);
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
