import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/models/user_model.dart';
import 'package:unshelf_buyer/viewmodels/user_profile_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserProfileViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockUserRepository mockUsers;
    late UserProfileViewModel viewModel;

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockUsers = _MockUserRepository();
      viewModel = UserProfileViewModel(authRepository: mockAuth, userRepository: mockUsers);
    });

    group('loadUserProfile', () {
      test('populates userProfile from repository data', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenAnswer(
          (_) async => {'name': 'Ivan', 'email': 'ivan@example.com', 'phoneNumber': '+639...'},
        );

        await viewModel.loadUserProfile();

        expect(viewModel.userProfile.name, 'Ivan');
        expect(viewModel.userProfile.email, 'ivan@example.com');
        expect(viewModel.userProfile.phoneNumber, '+639...');
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      });

      test('sets errorMessage when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);

        await viewModel.loadUserProfile();

        expect(viewModel.errorMessage, 'Failed to load user profile');
        expect(viewModel.isLoading, isFalse);
        verifyNever(() => mockUsers.fetchProfile(any()));
      });

      test('sets errorMessage when fetch throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenThrow(Exception('firestore down'));

        await viewModel.loadUserProfile();

        expect(viewModel.errorMessage, 'Failed to load user profile');
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('updateUserProfile', () {
      final newProfile = UserProfileModel(name: 'New', email: 'n@e.com', phoneNumber: '123');

      test('updates profile fields when password is null', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.updateProfile(any(), any())).thenAnswer((_) async {});

        await viewModel.updateUserProfile(newProfile);

        verify(() => mockUsers.updateProfile('uid-1', {
              'name': 'New',
              'email': 'n@e.com',
              'phoneNumber': '123',
            })).called(1);
        verifyNever(() => mockAuth.updatePassword(any()));
        expect(viewModel.userProfile, newProfile);
        expect(viewModel.errorMessage, isNull);
      });

      test('updates password when password is provided', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockAuth.updatePassword(any())).thenAnswer((_) async {});
        when(() => mockUsers.updateProfile(any(), any())).thenAnswer((_) async {});
        final withPassword = UserProfileModel(name: 'X', email: 'x@e.com', phoneNumber: '1', password: 'secret');

        await viewModel.updateUserProfile(withPassword);

        verify(() => mockAuth.updatePassword('secret')).called(1);
        expect(viewModel.userProfile, withPassword);
        expect(viewModel.errorMessage, isNull);
      });

      test('errors when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);

        await viewModel.updateUserProfile(newProfile);

        expect(viewModel.errorMessage, 'Failed to update user profile');
        verifyNever(() => mockUsers.updateProfile(any(), any()));
        verifyNever(() => mockAuth.updatePassword(any()));
      });

      test('sets errorMessage when update throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.updateProfile(any(), any())).thenThrow(Exception('permission denied'));

        await viewModel.updateUserProfile(newProfile);

        expect(viewModel.errorMessage, 'Failed to update user profile');
        expect(viewModel.isLoading, isFalse);
      });
    });
  });
}
