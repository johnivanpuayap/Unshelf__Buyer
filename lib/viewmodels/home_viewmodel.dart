import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<DocumentSnapshot> _searchResults = [];
  List<String> _bannerUrls = [];
  bool _isSearching = false;

  List<DocumentSnapshot> get searchResults => _searchResults;
  List<String> get bannerUrls => _bannerUrls;
  bool get isSearching => _isSearching;

  // Fetch Banner URLs from Firebase Storage
  Future<void> fetchBannerUrls() async {
    try {
      final ListResult result = await _storage.ref('banner_images').listAll();
      _bannerUrls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()).toList(),
      );
    } catch (e) {
      print('Error fetching banners: $e');
      _bannerUrls = [];
    }
    notifyListeners();
  }

  // Perform Product Search
  Future<void> performSearch(String query) async {
    _isSearching = true;
    notifyListeners();
    try {
      final searchResults = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      _searchResults = searchResults.docs;
    } catch (e) {
      print('Search error: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> getBundles() {
    return _firestore.collection('bundles').snapshots();
  }

  Stream<QuerySnapshot> getProducts() {
    return _firestore.collection('products').snapshots();
  }
}
