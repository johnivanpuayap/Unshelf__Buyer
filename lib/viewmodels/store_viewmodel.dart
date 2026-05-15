import 'package:flutter/foundation.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/stores_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/models/store_model.dart';

class StoreViewModel extends ChangeNotifier {
  StoreViewModel({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required StoresRepository storesRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        _storesRepository = storesRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final StoresRepository _storesRepository;

  StoreModel? storeDetails;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchStoreDetails(String storeId) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      errorMessage = 'User is not logged in';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final userData = await _userRepository.fetchProfile(userId);
      final storeData = await _storesRepository.fetchById(storeId);

      if (userData == null || storeData == null) {
        errorMessage = 'User profile or store not found';
        storeDetails = null;
      } else {
        storeDetails = StoreModel.fromMaps(
          userId: userId,
          userData: userData,
          storeData: storeData,
        );
        errorMessage = null;
      }
    } catch (e) {
      debugPrint('fetchStoreDetails failed: $e');
      errorMessage = 'Error fetching user profile: $e';
      storeDetails = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// NOTE: queries the signed-in user's followers (`users/{currentUserId}/followers`),
  /// not the viewed store's. Preserved from legacy code — likely a bug; revisit when
  /// the followers feature gets product-defined.
  Future<int> fetchStoreFollowers() async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      errorMessage = 'User is not logged in';
      notifyListeners();
      return 0;
    }

    try {
      return await _userRepository.fetchFollowersCount(userId);
    } catch (e) {
      debugPrint('fetchStoreFollowers failed: $e');
      errorMessage = 'Error fetching store followers';
      return 0;
    } finally {
      notifyListeners();
    }
  }

  void clear() {
    storeDetails = null;
    errorMessage = null;
    notifyListeners();
  }
}
