import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_product_repository.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/viewmodels/home_viewmodel.dart';

class _MockProductRepository extends Mock implements ProductRepository {}

class _MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  group('HomeViewModel', () {
    late _MockProductRepository mockProducts;
    late _MockStorageRepository mockStorage;
    late HomeViewModel viewModel;

    setUp(() {
      mockProducts = _MockProductRepository();
      mockStorage = _MockStorageRepository();
      viewModel = HomeViewModel(productRepository: mockProducts, storageRepository: mockStorage);
    });

    group('fetchBannerUrls', () {
      test('populates bannerUrls on success', () async {
        when(() => mockStorage.listDownloadUrls('banner_images'))
            .thenAnswer((_) async => ['https://cdn/a.png', 'https://cdn/b.png']);

        await viewModel.fetchBannerUrls();

        expect(viewModel.bannerUrls, ['https://cdn/a.png', 'https://cdn/b.png']);
      });

      test('falls back to empty list on error', () async {
        when(() => mockStorage.listDownloadUrls('banner_images')).thenThrow(Exception('network'));

        await viewModel.fetchBannerUrls();

        expect(viewModel.bannerUrls, isEmpty);
      });

      test('notifies listeners exactly once', () async {
        when(() => mockStorage.listDownloadUrls(any())).thenAnswer((_) async => []);
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        await viewModel.fetchBannerUrls();

        expect(notifications, 1);
      });
    });

    group('performSearch', () {
      test('toggles isSearching true then false during the call', () async {
        final states = <bool>[];
        viewModel.addListener(() => states.add(viewModel.isSearching));
        when(() => mockProducts.searchByName(any())).thenAnswer((_) async => []);

        await viewModel.performSearch('apple');

        expect(states, containsAllInOrder([true, false]));
      });

      test('populates searchResults via FirebaseProductRepository against a fake Firestore', () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('products').add({'name': 'apple'});
        await fake.collection('products').add({'name': 'apricot'});
        final repo = FirebaseProductRepository(firestore: fake);
        final vm = HomeViewModel(productRepository: repo, storageRepository: mockStorage);

        await vm.performSearch('ap');

        expect(vm.searchResults, hasLength(2));
        expect(vm.isSearching, isFalse);
      });

      test('clears searchResults on error and still resets isSearching', () async {
        when(() => mockProducts.searchByName(any())).thenThrow(Exception('firestore down'));

        await viewModel.performSearch('apple');

        expect(viewModel.searchResults, isEmpty);
        expect(viewModel.isSearching, isFalse);
      });
    });
  });
}
