import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/stores_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _MockStoresRepository extends Mock implements StoresRepository {}

void main() {
  group('StoreViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockUserRepository mockUsers;
    late _MockStoresRepository mockStores;
    late StoreViewModel viewModel;

    final goodStoreData = {
      'store_name': 'Cebu Greens',
      'longitude': 123.8854,
      'latitude': 10.3157,
      'store_image_url': 'https://cdn/x.png',
      'rating': 4.5,
      'follower_count': 42,
    };
    final goodUserData = {
      'email': 'owner@example.com',
      'name': 'Owner',
      'phone_number': '+639...',
    };

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockUsers = _MockUserRepository();
      mockStores = _MockStoresRepository();
      viewModel = StoreViewModel(
        authRepository: mockAuth,
        userRepository: mockUsers,
        storesRepository: mockStores,
      );
    });

    group('fetchStoreDetails', () {
      test('populates storeDetails on success', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenAnswer((_) async => goodUserData);
        when(() => mockStores.fetchById('store-1')).thenAnswer((_) async => goodStoreData);

        await viewModel.fetchStoreDetails('store-1');

        expect(viewModel.storeDetails, isNotNull);
        expect(viewModel.storeDetails!.storeName, 'Cebu Greens');
        expect(viewModel.storeDetails!.email, 'owner@example.com');
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.isLoading, isFalse);
      });

      test('sets errorMessage when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);

        await viewModel.fetchStoreDetails('store-1');

        expect(viewModel.errorMessage, 'User is not logged in');
        expect(viewModel.isLoading, isFalse);
        verifyNever(() => mockUsers.fetchProfile(any()));
        verifyNever(() => mockStores.fetchById(any()));
      });

      test('sets errorMessage when user profile is missing', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenAnswer((_) async => null);
        when(() => mockStores.fetchById('store-1')).thenAnswer((_) async => goodStoreData);

        await viewModel.fetchStoreDetails('store-1');

        expect(viewModel.errorMessage, contains('not found'));
        expect(viewModel.storeDetails, isNull);
      });

      test('sets errorMessage when store is missing', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenAnswer((_) async => goodUserData);
        when(() => mockStores.fetchById('store-1')).thenAnswer((_) async => null);

        await viewModel.fetchStoreDetails('store-1');

        expect(viewModel.errorMessage, contains('not found'));
        expect(viewModel.storeDetails, isNull);
      });

      test('sets errorMessage when fetch throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchProfile('uid-1')).thenThrow(Exception('firestore down'));

        await viewModel.fetchStoreDetails('store-1');

        expect(viewModel.errorMessage, contains('Error fetching'));
        expect(viewModel.storeDetails, isNull);
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('fetchStoreFollowers', () {
      test('returns count from repository', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchFollowersCount('uid-1')).thenAnswer((_) async => 17);

        final count = await viewModel.fetchStoreFollowers();

        expect(count, 17);
      });

      test('returns 0 and sets errorMessage when no user is signed in', () async {
        when(() => mockAuth.currentUserId).thenReturn(null);

        final count = await viewModel.fetchStoreFollowers();

        expect(count, 0);
        expect(viewModel.errorMessage, 'User is not logged in');
        verifyNever(() => mockUsers.fetchFollowersCount(any()));
      });

      test('returns 0 and sets errorMessage when repository throws', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockUsers.fetchFollowersCount('uid-1')).thenThrow(Exception('network'));

        final count = await viewModel.fetchStoreFollowers();

        expect(count, 0);
        expect(viewModel.errorMessage, contains('Error fetching store followers'));
      });
    });

    test('clear resets storeDetails and errorMessage', () async {
      when(() => mockAuth.currentUserId).thenReturn('uid-1');
      when(() => mockUsers.fetchProfile(any())).thenAnswer((_) async => goodUserData);
      when(() => mockStores.fetchById(any())).thenAnswer((_) async => goodStoreData);
      await viewModel.fetchStoreDetails('store-1');

      viewModel.clear();

      expect(viewModel.storeDetails, isNull);
      expect(viewModel.errorMessage, isNull);
    });
  });
}
