import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required ProductRepository productRepository,
    required StorageRepository storageRepository,
  })  : _productRepository = productRepository,
        _storageRepository = storageRepository;

  final ProductRepository _productRepository;
  final StorageRepository _storageRepository;

  List<DocumentSnapshot> _searchResults = [];
  List<String> _bannerUrls = [];
  bool _isSearching = false;

  List<DocumentSnapshot> get searchResults => _searchResults;
  List<String> get bannerUrls => _bannerUrls;
  bool get isSearching => _isSearching;

  Future<void> fetchBannerUrls() async {
    try {
      _bannerUrls = await _storageRepository.listDownloadUrls('banner_images');
    } catch (e) {
      debugPrint('fetchBannerUrls failed: $e');
      _bannerUrls = [];
    }
    notifyListeners();
  }

  Future<void> performSearch(String query) async {
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _productRepository.searchByName(query);
    } catch (e) {
      debugPrint('performSearch failed: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot> getProducts() => _productRepository.watchProducts();
  Stream<QuerySnapshot> getBundles() => _productRepository.watchBundles();
}
