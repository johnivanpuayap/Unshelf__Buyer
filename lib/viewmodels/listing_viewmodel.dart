// viewmodels/listing_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/bundle_model.dart';
import 'package:unshelf_buyer/models/item_model.dart';
import 'package:unshelf_buyer/models/product_model.dart';

part 'listing_viewmodel.g.dart';

class ListingState {
  const ListingState({
    this.items = const [],
    this.isLoading = true,
    this.showingProducts = true,
  });

  final List<ItemModel> items;
  final bool isLoading;
  final bool showingProducts;

  ListingState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    bool? showingProducts,
  }) {
    return ListingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      showingProducts: showingProducts ?? this.showingProducts,
    );
  }
}

@riverpod
class ListingViewModel extends _$ListingViewModel {
  @override
  ListingState build() {
    Future.microtask(() => _fetchItems());
    return const ListingState(isLoading: true);
  }

  Future<void> _fetchItems() async {
    state = state.copyWith(isLoading: true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(items: [], isLoading: false);
      return;
    }

    try {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      debugPrint('Mapping products');
      final products = productSnapshot.docs
          .map((doc) {
            try {
              return ProductModel.fromSnapshot(doc) as ItemModel?;
            } catch (e) {
              debugPrint('Error mapping product: $e');
              return null;
            }
          })
          .whereType<ItemModel>()
          .toList();

      final bundleSnapshot = await FirebaseFirestore.instance
          .collection('bundles')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      final bundles = bundleSnapshot.docs
          .map((doc) {
            try {
              return BundleModel.fromSnapshot(doc) as ItemModel?;
            } catch (e) {
              debugPrint('Error mapping bundle: $e');
              return null;
            }
          })
          .whereType<ItemModel>()
          .toList();

      state = state.copyWith(
        items: state.showingProducts ? products : bundles,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('_fetchItems failed: $e');
      state = state.copyWith(items: [], isLoading: false);
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await FirebaseFirestore.instance.collection('products').add(productData);
    await _fetchItems();
  }

  Future<void> addBundle(Map<String, dynamic> bundleData) async {
    await FirebaseFirestore.instance.collection('bundles').add(bundleData);
    await _fetchItems();
  }

  Future<void> deleteItem(String itemId, bool isProduct) async {
    final collection = isProduct ? 'products' : 'bundles';
    await FirebaseFirestore.instance.collection(collection).doc(itemId).delete();
    await _fetchItems();
  }

  void toggleView() {
    state = state.copyWith(showingProducts: !state.showingProducts);
    _fetchItems();
  }

  void refreshItems() {
    _fetchItems();
  }

  void clear() {
    state = const ListingState(items: [], isLoading: true);
  }
}
