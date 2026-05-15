import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/store_model.dart';

part 'store_profile_viewmodel.g.dart';

class StoreProfileState {
  StoreProfileState({
    this.storeName = '',
    this.profileImage,
    this.isLoading = false,
  });

  final String storeName;
  final Uint8List? profileImage;
  final bool isLoading;

  StoreProfileState copyWith({
    String? storeName,
    Uint8List? profileImage,
    bool? isLoading,
    bool clearImage = false,
  }) {
    return StoreProfileState(
      storeName: storeName ?? this.storeName,
      profileImage: clearImage ? null : profileImage ?? this.profileImage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class StoreProfileViewModel extends _$StoreProfileViewModel {
  final ImagePicker _picker = ImagePicker();

  @override
  StoreProfileState build(StoreModel storeDetails) {
    return StoreProfileState(storeName: storeDetails.storeName);
  }

  void updateStoreName(String name) {
    state = state.copyWith(storeName: name);
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      state = state.copyWith(profileImage: imageData);
    }
  }

  Future<void> updateStoreProfile() async {
    if (state.storeName.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      final storeRef = FirebaseFirestore.instance
          .collection('stores')
          .doc(storeDetails.userId);
      final updateData = <String, dynamic>{
        'store_name': state.storeName,
      };

      if (state.profileImage != null) {
        final imageUrl = await _uploadImage(state.profileImage!);
        updateData['store_image_url'] = imageUrl;
      }

      await storeRef.update(updateData);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('updateStoreProfile failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String> _uploadImage(Uint8List image) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref().child('user_avatars/$userId.jpg');
    await ref.putData(image);
    return ref.getDownloadURL();
  }
}
