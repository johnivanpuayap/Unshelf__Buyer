import 'package:flutter/foundation.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/models/user_model.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  UserProfileModel _userProfile = UserProfileModel();
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final userId = _authRepository.currentUserId;
    if (userId == null) {
      _errorMessage = 'Failed to load user profile';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _userRepository.fetchProfile(userId);
      if (data != null) {
        _userProfile = UserProfileModel(
          name: data['name'],
          email: data['email'],
          phoneNumber: data['phoneNumber'],
        );
      }
    } catch (e) {
      debugPrint('loadUserProfile failed: $e');
      _errorMessage = 'Failed to load user profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserProfileModel newProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final userId = _authRepository.currentUserId;
    if (userId == null) {
      _errorMessage = 'Failed to update user profile';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      if (newProfile.password != null && newProfile.password!.isNotEmpty) {
        await _authRepository.updatePassword(newProfile.password!);
      }
      await _userRepository.updateProfile(userId, {
        'name': newProfile.name,
        'email': newProfile.email,
        'phoneNumber': newProfile.phoneNumber,
      });
      _userProfile = newProfile;
    } catch (e) {
      debugPrint('updateUserProfile failed: $e');
      _errorMessage = 'Failed to update user profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
