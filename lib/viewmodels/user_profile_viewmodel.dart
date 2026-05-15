import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/models/user_model.dart';
import 'package:unshelf_buyer/providers.dart';

part 'user_profile_viewmodel.g.dart';

class UserProfileState {
  UserProfileState({
    UserProfileModel? userProfile,
    this.isLoading = false,
    this.errorMessage,
  }) : userProfile = userProfile ?? UserProfileModel();

  final UserProfileModel userProfile;
  final bool isLoading;
  final String? errorMessage;

  UserProfileState copyWith({
    UserProfileModel? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserProfileState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class UserProfileViewModel extends _$UserProfileViewModel {
  @override
  UserProfileState build() => UserProfileState();

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  UserRepository get _userRepository => ref.read(userRepositoryProvider);

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final userId = _authRepository.currentUserId;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user profile',
      );
      return;
    }

    try {
      final data = await _userRepository.fetchProfile(userId);
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          userProfile: UserProfileModel(
            name: data['name'],
            email: data['email'],
            phoneNumber: data['phoneNumber'],
          ),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('loadUserProfile failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user profile',
      );
    }
  }

  Future<void> updateUserProfile(UserProfileModel newProfile) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final userId = _authRepository.currentUserId;
    if (userId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update user profile',
      );
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
      state = state.copyWith(isLoading: false, userProfile: newProfile);
    } catch (e) {
      debugPrint('updateUserProfile failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update user profile',
      );
    }
  }
}
