import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/models/store_model.dart';

part 'store_viewmodel.g.dart';

class StoreState {
  const StoreState({
    this.storeDetails,
    this.isLoading = true,
    this.errorMessage,
  });

  final StoreModel? storeDetails;
  final bool isLoading;
  final String? errorMessage;

  StoreState copyWith({
    StoreModel? storeDetails,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearStoreDetails = false,
  }) {
    return StoreState(
      storeDetails: clearStoreDetails ? null : storeDetails ?? this.storeDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class StoreViewModel extends _$StoreViewModel {
  @override
  StoreState build(String storeId) {
    // Kick off data load immediately, just like the old constructor did.
    Future.microtask(() => fetchStoreDetails(storeId));
    return const StoreState(isLoading: true);
  }

  Future<void> fetchStoreDetails(String storeId) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      state = state.copyWith(errorMessage: 'User is not logged in', isLoading: false, clearStoreDetails: true);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();

      if (!userDoc.exists || !storeDoc.exists) {
        state = state.copyWith(
          errorMessage: 'User profile or store not found',
          isLoading: false,
          clearStoreDetails: true,
        );
      } else {
        state = state.copyWith(
          storeDetails: StoreModel.fromSnapshot(userDoc, storeDoc),
          isLoading: false,
          clearError: true,
        );
      }
    } catch (e) {
      debugPrint('fetchStoreDetails failed: $e');
      state = state.copyWith(
        errorMessage: 'Error fetching user profile: ${e.toString()}',
        isLoading: false,
        clearStoreDetails: true,
      );
    }
  }

  Future<int> fetchStoreFollowers() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      state = state.copyWith(errorMessage: 'User is not logged in', isLoading: false);
      return 0;
    }

    try {
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .get();
      return followersSnapshot.size;
    } catch (e) {
      debugPrint('fetchStoreFollowers failed: $e');
      state = state.copyWith(errorMessage: 'Error fetching store followers', isLoading: false);
      return 0;
    }
  }

  void clear() {
    state = const StoreState(storeDetails: null, isLoading: false, errorMessage: null);
  }
}
