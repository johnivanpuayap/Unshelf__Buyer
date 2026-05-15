import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/providers.dart';

part 'home_viewmodel.g.dart';

class HomeState {
  const HomeState({
    this.searchResults = const [],
    this.bannerUrls = const [],
    this.isSearching = false,
  });

  final List<DocumentSnapshot> searchResults;
  final List<String> bannerUrls;
  final bool isSearching;

  HomeState copyWith({
    List<DocumentSnapshot>? searchResults,
    List<String>? bannerUrls,
    bool? isSearching,
  }) {
    return HomeState(
      searchResults: searchResults ?? this.searchResults,
      bannerUrls: bannerUrls ?? this.bannerUrls,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  HomeState build() => const HomeState();

  ProductRepository get _productRepository => ref.read(productRepositoryProvider);
  StorageRepository get _storageRepository => ref.read(storageRepositoryProvider);

  Future<void> fetchBannerUrls() async {
    try {
      final urls = await _storageRepository.listDownloadUrls('banner_images');
      state = state.copyWith(bannerUrls: urls);
    } catch (e) {
      debugPrint('fetchBannerUrls failed: $e');
      state = state.copyWith(bannerUrls: []);
    }
  }

  Future<void> performSearch(String query) async {
    state = state.copyWith(isSearching: true);
    try {
      final results = await _productRepository.searchByName(query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      debugPrint('performSearch failed: $e');
      state = state.copyWith(searchResults: [], isSearching: false);
    }
  }

  Stream<QuerySnapshot> getProducts() => _productRepository.watchProducts();
  Stream<QuerySnapshot> getBundles() => _productRepository.watchBundles();
}
