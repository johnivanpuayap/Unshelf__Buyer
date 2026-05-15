import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/bundle_model.dart';
import 'package:unshelf_buyer/models/product_model.dart';

part 'bundle_viewmodel.g.dart';

class BundleState {
  BundleState({
    this.products = const [],
    Set<String>? selectedProductIds,
    this.maxStock = 0,
    this.mainImageData,
    this.suggestions = const [],
    this.bundleName = '',
    this.bundlePrice = '',
    this.bundleStock = '',
    this.bundleDiscount = '',
  }) : selectedProductIds = selectedProductIds ?? {};

  final List<ProductModel> products;
  final Set<String> selectedProductIds;
  final int maxStock;
  final Uint8List? mainImageData;
  final List<BundleModel> suggestions;
  final String bundleName;
  final String bundlePrice;
  final String bundleStock;
  final String bundleDiscount;

  BundleState copyWith({
    List<ProductModel>? products,
    Set<String>? selectedProductIds,
    int? maxStock,
    Uint8List? mainImageData,
    bool clearMainImage = false,
    List<BundleModel>? suggestions,
    String? bundleName,
    String? bundlePrice,
    String? bundleStock,
    String? bundleDiscount,
  }) {
    return BundleState(
      products: products ?? this.products,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      maxStock: maxStock ?? this.maxStock,
      mainImageData: clearMainImage ? null : mainImageData ?? this.mainImageData,
      suggestions: suggestions ?? this.suggestions,
      bundleName: bundleName ?? this.bundleName,
      bundlePrice: bundlePrice ?? this.bundlePrice,
      bundleStock: bundleStock ?? this.bundleStock,
      bundleDiscount: bundleDiscount ?? this.bundleDiscount,
    );
  }
}

@riverpod
class BundleViewModel extends _$BundleViewModel {
  final ImagePicker _picker = ImagePicker();
  Future<void>? _fetchSuggestionsFuture;

  @override
  BundleState build() {
    Future.microtask(_fetchProducts);
    return BundleState();
  }

  Future<void> _fetchProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .get();

    final products = snapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
    debugPrint('Products: $products');
    state = state.copyWith(products: products);
  }

  void initializeFromBundle(BundleModel bundle) {
    final selected = bundle.productIds.toSet();
    state = state.copyWith(
      bundleName: bundle.name,
      bundlePrice: bundle.price.toString(),
      bundleStock: bundle.stock.toString(),
      bundleDiscount: bundle.discount.toString(),
      selectedProductIds: selected,
    );
    _updateBundleStock(selected);
  }

  void updateField({
    String? bundleName,
    String? bundlePrice,
    String? bundleStock,
    String? bundleDiscount,
  }) {
    state = state.copyWith(
      bundleName: bundleName,
      bundlePrice: bundlePrice,
      bundleStock: bundleStock,
      bundleDiscount: bundleDiscount,
    );
  }

  void addProductToBundle(String productId) {
    final updated = {...state.selectedProductIds, productId};
    state = state.copyWith(selectedProductIds: updated);
    _updateBundleStock(updated);
  }

  void removeProductFromBundle(String productId) {
    final updated = Set<String>.from(state.selectedProductIds)..remove(productId);
    state = state.copyWith(selectedProductIds: updated);
    _updateBundleStock(updated);
  }

  void _updateBundleStock(Set<String> selected) {
    if (selected.isEmpty) {
      state = state.copyWith(maxStock: 0);
      return;
    }
    final selectedProducts = state.products.where((p) => selected.contains(p.id)).toList();
    if (selectedProducts.isEmpty) {
      state = state.copyWith(maxStock: 0);
      return;
    }
    final minStock = selectedProducts.map((p) => p.stock).reduce((min, s) => s < min ? s : min);
    state = state.copyWith(maxStock: minStock);
  }

  Future<void> createBundle() async {
    try {
      if (state.bundleName.isEmpty || state.selectedProductIds.isEmpty) {
        throw Exception('Bundle name or selected products cannot be empty');
      }
      if (state.mainImageData == null) {
        throw Exception('Bundle image is required');
      }

      final user = FirebaseAuth.instance.currentUser!;
      final bundlePrice = double.tryParse(state.bundlePrice) ?? 0.0;
      final bundleStock = int.tryParse(state.bundleStock) ?? 0;
      final bundleDiscount = double.tryParse(state.bundleDiscount) ?? 0.0;

      final imageRef = FirebaseStorage.instance
          .ref()
          .child('bundle_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await imageRef.putData(state.mainImageData!);
      final imageUrl = await imageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('bundles').add({
        'name': state.bundleName,
        'productIds': state.selectedProductIds.toList(),
        'price': bundlePrice,
        'stock': bundleStock,
        'discount': bundleDiscount,
        'mainImageUrl': imageUrl,
        'sellerId': user.uid,
      });
    } catch (e) {
      debugPrint('createBundle failed: $e');
    }
  }

  Future<void> loadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        state = state.copyWith(mainImageData: response.bodyBytes);
      }
    } catch (e) {
      debugPrint('loadImageFromUrl failed: $e');
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      state = state.copyWith(mainImageData: imageData);
    }
  }

  void deleteMainImage() {
    state = state.copyWith(clearMainImage: true);
  }

  Future<void> fetchSuggestions() async {
    const url = 'http://localhost:8000/api/recommend-bundles/';
    final body = json.encode(state.products.map((p) => p.toJson()).toList());
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Suggestions: $data');
        final suggestions = (data['bundles'] as List)
            .map<BundleModel>((b) => BundleModel.fromJson(b))
            .toList();
        state = state.copyWith(suggestions: suggestions);
      } else {
        debugPrint('fetchSuggestions error: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('fetchSuggestions exception: $e');
    }
  }

  Future<void> getSuggestions() {
    _fetchSuggestionsFuture ??= fetchSuggestions();
    return _fetchSuggestionsFuture!;
  }
}
