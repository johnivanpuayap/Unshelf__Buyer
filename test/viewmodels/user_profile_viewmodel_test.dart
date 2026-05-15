import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/models/user_model.dart';
import 'package:unshelf_buyer/providers.dart';
import 'package:unshelf_buyer/viewmodels/user_profile_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserProfileViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockUserRepository mockUsers;

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockUsers = _MockUserRepository();
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
        userRepositoryProvider.overrideWithValue(mockUsers),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    group('loadUserProfile', () {
      test('populates userProfile from repository data', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenAnswer(
          (_) async => {'name': 'Ivan', 'email': 'ivan@example.com', 'phoneNumber': '+639...'},
        );
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).loadUserProfile();

        final state = container.read(userProfileViewModelProvider);
        expect(state.userProfile.name, 'Ivan');
        expect(state.userProfile.email, 'ivan@example.com');
        expect(state.userProfile.phoneNumber, '+639...');
        expect(state.errorMessage, isNull);
        expect(state.isLoading, isFalse);
      });

      test('sets errorMessage when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).loadUserProfile();

        final state = container.read(userProfileViewModelProvider);
        expect(state.errorMessage, 'Failed to load user profile');
        expect(state.isLoading, isFalse);
        verifyNever(() => mockUsers.fetchProfile(any()));
      });

      test('sets errorMessage when fetch throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenThrow(Exception('firestore down'));
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).loadUserProfile();

        final state = container.read(userProfileViewModelProvider);
        expect(state.errorMessage, 'Failed to load user profile');
        expect(state.isLoading, isFalse);
      });
    });

    group('updateUserProfile', () {
      final newProfile = UserProfileModel(name: 'New', email: 'n@e.com', phoneNumber: '123');

      test('updates profile fields when password is null', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.updateProfile(any(), any())).thenAnswer((_) async {});
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).updateUserProfile(newProfile);

        verify(() => mockUsers.updateProfile('uid-1', {
              'name': 'New',
              'email': 'n@e.com',
              'phoneNumber': '123',
            })).called(1);
        verifyNever(() => mockAuth.updatePassword(any()));
        final state = container.read(userProfileViewModelProvider);
        expect(state.userProfile, newProfile);
        expect(state.errorMessage, isNull);
      });

      test('updates password when password is provided', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockAuth.updatePassword(any())).thenAnswer((_) async {});
        when(() => mockUsers.updateProfile(any(), any())).thenAnswer((_) async {});
        final withPassword = UserProfileModel(name: 'X', email: 'x@e.com', phoneNumber: '1', password: 'secret');
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).updateUserProfile(withPassword);

        verify(() => mockAuth.updatePassword('secret')).called(1);
        final state = container.read(userProfileViewModelProvider);
        expect(state.userProfile, withPassword);
        expect(state.errorMessage, isNull);
      });

      test('errors when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).updateUserProfile(newProfile);

        final state = container.read(userProfileViewModelProvider);
        expect(state.errorMessage, 'Failed to update user profile');
        verifyNever(() => mockUsers.updateProfile(any(), any()));
        verifyNever(() => mockAuth.updatePassword(any()));
      });

      test('sets errorMessage when update throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.updateProfile(any(), any())).thenThrow(Exception('permission denied'));
        final container = makeContainer();

        await container.read(userProfileViewModelProvider.notifier).updateUserProfile(newProfile);

        final state = container.read(userProfileViewModelProvider);
        expect(state.errorMessage, 'Failed to update user profile');
        expect(state.isLoading, isFalse);
      });
    });
  });
}
