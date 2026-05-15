import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_product_repository.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/providers.dart';
import 'package:unshelf_buyer/viewmodels/home_viewmodel.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

class _MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  group('HomeViewModel', () {
    late _MockProductRepository mockProducts;
    late _MockStorageRepository mockStorage;

    setUp(() {
      mockProducts = _MockProductRepository();
      mockStorage = _MockStorageRepository();
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        productRepositoryProvider.overrideWithValue(mockProducts),
        storageRepositoryProvider.overrideWithValue(mockStorage),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    group('fetchBannerUrls', () {
      test('populates bannerUrls on success', () async {
        when(() => mockStorage.listDownloadUrls('banner_images'))
            .thenAnswer((_) async => ['https://cdn/a.png', 'https://cdn/b.png']);
        final container = makeContainer();

        await container.read(homeViewModelProvider.notifier).fetchBannerUrls();

        expect(container.read(homeViewModelProvider).bannerUrls, ['https://cdn/a.png', 'https://cdn/b.png']);
      });

      test('falls back to empty list on error', () async {
        when(() => mockStorage.listDownloadUrls('banner_images')).thenThrow(Exception('network'));
        final container = makeContainer();

        await container.read(homeViewModelProvider.notifier).fetchBannerUrls();

        expect(container.read(homeViewModelProvider).bannerUrls, isEmpty);
      });

      test('notifies listeners exactly once', () async {
        when(() => mockStorage.listDownloadUrls(any())).thenAnswer((_) async => []);
        final container = makeContainer();
        var notifications = 0;
        container.listen(homeViewModelProvider, (_, __) => notifications++);

        await container.read(homeViewModelProvider.notifier).fetchBannerUrls();

        expect(notifications, 1);
      });
    });

    group('performSearch', () {
      test('toggles isSearching true then false during the call', () async {
        final states = <bool>[];
        when(() => mockProducts.searchByName(any())).thenAnswer((_) async => []);
        final container = makeContainer();
        container.listen(
          homeViewModelProvider.select((s) => s.isSearching),
          (_, next) => states.add(next),
        );

        await container.read(homeViewModelProvider.notifier).performSearch('apple');

        expect(states, containsAllInOrder([true, false]));
      });

      test('populates searchResults via FirebaseProductRepository against a fake Firestore', () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('products').add({'name': 'apple'});
        await fake.collection('products').add({'name': 'apricot'});
        final repo = FirebaseProductRepository(firestore: fake);
        final container = ProviderContainer(overrides: [
          productRepositoryProvider.overrideWithValue(repo),
          storageRepositoryProvider.overrideWithValue(mockStorage),
        ]);
        addTearDown(container.dispose);

        await container.read(homeViewModelProvider.notifier).performSearch('ap');

        final state = container.read(homeViewModelProvider);
        expect(state.searchResults, hasLength(2));
        expect(state.isSearching, isFalse);
      });

      test('clears searchResults on error and still resets isSearching', () async {
        when(() => mockProducts.searchByName(any())).thenThrow(Exception('firestore down'));
        final container = makeContainer();

        await container.read(homeViewModelProvider.notifier).performSearch('apple');

        final state = container.read(homeViewModelProvider);
        expect(state.searchResults, isEmpty);
        expect(state.isSearching, isFalse);
      });
    });
  });
}
