import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/product_model.dart';

part 'product_viewmodel.g.dart';

class ProductState {
  ProductState({
    this.productId,
    this.isLoading = false,
    this.errorFound = false,
    this.mainImageData,
    List<Uint8List?>? additionalImageDataList,
    List<bool>? isAdditionalImageNewList,
    this.isMainImageNew = false,
    // Text field values stored as plain strings for testability
    this.name = '',
    this.price = '',
    this.quantity = '',
    this.expiryDate = '',
    this.description = '',
    this.discount = '',
  })  : additionalImageDataList = additionalImageDataList ?? List.generate(4, (_) => null),
        isAdditionalImageNewList = isAdditionalImageNewList ?? List.generate(4, (_) => false);

  final String? productId;
  final bool isLoading;
  final bool errorFound;
  final Uint8List? mainImageData;
  final List<Uint8List?> additionalImageDataList;
  final List<bool> isAdditionalImageNewList;
  final bool isMainImageNew;
  final String name;
  final String price;
  final String quantity;
  final String expiryDate;
  final String description;
  final String discount;

  ProductState copyWith({
    String? productId,
    bool? isLoading,
    bool? errorFound,
    Uint8List? mainImageData,
    bool clearMainImage = false,
    List<Uint8List?>? additionalImageDataList,
    List<bool>? isAdditionalImageNewList,
    bool? isMainImageNew,
    String? name,
    String? price,
    String? quantity,
    String? expiryDate,
    String? description,
    String? discount,
  }) {
    return ProductState(
      productId: productId ?? this.productId,
      isLoading: isLoading ?? this.isLoading,
      errorFound: errorFound ?? this.errorFound,
      mainImageData: clearMainImage ? null : mainImageData ?? this.mainImageData,
      additionalImageDataList: additionalImageDataList ?? this.additionalImageDataList,
      isAdditionalImageNewList: isAdditionalImageNewList ?? this.isAdditionalImageNewList,
      isMainImageNew: isMainImageNew ?? this.isMainImageNew,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
      discount: discount ?? this.discount,
    );
  }
}

@riverpod
class ProductViewModel extends _$ProductViewModel {
  final ImagePicker _picker = ImagePicker();

  @override
  ProductState build({String? productId}) {
    if (productId != null) {
      Future.microtask(() => fetchProductData(productId));
    }
    return ProductState(productId: productId);
  }

  Future<void> fetchProductData(String productId) async {
    state = state.copyWith(isLoading: true);

    try {
      final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productDoc.exists) {
        final product = ProductModel.fromSnapshot(productDoc);
        final additionalImages = List<Uint8List?>.generate(4, (_) => null);
        final additionalNew = List<bool>.generate(4, (_) => false);

        Uint8List? mainImg;
        if (product.mainImageUrl.isNotEmpty) {
          mainImg = await _loadImageFromUrl(product.mainImageUrl);
        }

        if (product.additionalImageUrls != null) {
          for (int i = 0; i < product.additionalImageUrls!.length && i < 4; i++) {
            additionalImages[i] = await _loadImageFromUrl(product.additionalImageUrls![i]);
          }
        }

        state = state.copyWith(
          isLoading: false,
          name: product.name,
          price: product.price.toString(),
          quantity: product.stock.toString(),
          expiryDate: product.expiryDate.toString(),
          description: product.description,
          discount: product.discount.toString(),
          mainImageData: mainImg,
          additionalImageDataList: additionalImages,
          isAdditionalImageNewList: additionalNew,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('fetchProductData failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Uint8List?> _loadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      debugPrint('_loadImageFromUrl failed: $e');
    }
    return null;
  }

  Future<void> pickImage(bool isMainImage, {int? index}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      if (isMainImage) {
        state = state.copyWith(mainImageData: imageData, isMainImageNew: true);
      } else if (index != null) {
        final updated = List<Uint8List?>.from(state.additionalImageDataList);
        final updatedNew = List<bool>.from(state.isAdditionalImageNewList);
        updated[index] = imageData;
        updatedNew[index] = true;
        state = state.copyWith(
          additionalImageDataList: updated,
          isAdditionalImageNewList: updatedNew,
        );
      }
    }
  }

  Future<List<String>> uploadImages() async {
    final List<String> downloadUrls = [];

    if (state.mainImageData != null && state.isMainImageNew) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('product_images/main_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(state.mainImageData!);
        downloadUrls.add(await ref.getDownloadURL());
      } catch (e) {
        debugPrint('uploadImages (main) failed: $e');
      }
    }

    for (int i = 0; i < state.additionalImageDataList.length; i++) {
      if (state.additionalImageDataList[i] != null && state.isAdditionalImageNewList[i]) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('product_images/additional_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          await ref.putData(state.additionalImageDataList[i]!);
          downloadUrls.add(await ref.getDownloadURL());
        } catch (e) {
          debugPrint('uploadImages (additional $i) failed: $e');
        }
      }
    }

    return downloadUrls;
  }

  Future<void> addOrUpdateProduct(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (state.productId == null) {
          final images = await uploadImages();
          await FirebaseFirestore.instance.collection('products').add({
            'sellerId': user.uid,
            'name': state.name,
            'description': state.description,
            'price': double.parse(state.price),
            'stock': int.parse(state.quantity),
            'expiryDate': DateTime.parse(state.expiryDate),
            'discount': int.parse(state.discount),
            'mainImageUrl': images.isNotEmpty ? images[0] : '',
            'additionalImageUrls': images.length > 1 ? images.sublist(1).take(10).toList() : [],
            'isListed': true,
          });
        } else {
          await FirebaseFirestore.instance.collection('products').doc(state.productId).update({
            'name': state.name,
            'description': state.description,
            'price': double.parse(state.price),
            'stock': int.parse(state.quantity),
            'expiryDate': DateTime.parse(state.expiryDate),
            'discount': int.parse(state.discount),
            'mainImageUrl': '',
            'additionalImageUrls': [],
          });
        }
      }
    } catch (e) {
      debugPrint('addOrUpdateProduct failed: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void deleteMainImage() {
    state = state.copyWith(clearMainImage: true, isMainImageNew: false);
  }

  void deleteAdditionalImage(int index) {
    final updated = List<Uint8List?>.from(state.additionalImageDataList);
    final updatedNew = List<bool>.from(state.isAdditionalImageNewList);
    updated[index] = null;
    updatedNew[index] = false;
    state = state.copyWith(
      additionalImageDataList: updated,
      isAdditionalImageNewList: updatedNew,
    );
  }

  Future<void> selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      state = state.copyWith(expiryDate: "${picked.toLocal()}".split(' ')[0]);
    }
  }

  void updateField({
    String? name,
    String? price,
    String? quantity,
    String? expiryDate,
    String? description,
    String? discount,
  }) {
    state = state.copyWith(
      name: name,
      price: price,
      quantity: quantity,
      expiryDate: expiryDate,
      description: description,
      discount: discount,
    );
  }
}
