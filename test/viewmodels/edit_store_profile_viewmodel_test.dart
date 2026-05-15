import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/data/repositories/stores_repository.dart';
import 'package:unshelf_buyer/models/store_model.dart';
import 'package:unshelf_buyer/services/image_picker_service.dart';
import 'package:unshelf_buyer/viewmodels/edit_store_profile_viewmodel.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockStoresRepository extends Mock implements StoresRepository {}

class _MockStorageRepository extends Mock implements StorageRepository {}

class _MockImagePickerService extends Mock implements ImagePickerService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('EditStoreProfileViewModel', () {
    late _MockAuthRepository mockAuth;
    late _MockStoresRepository mockStores;
    late _MockStorageRepository mockStorage;
    late _MockImagePickerService mockPicker;
    late EditStoreProfileViewModel viewModel;

    StoreModel buildStore() => StoreModel(
          userId: 'uid-1',
          email: 'owner@example.com',
          name: 'Owner',
          phoneNumber: '+639...',
          storeName: 'Cebu Greens',
          storeLongitude: 123.8854,
          storeLatitude: 10.3157,
        );

    setUp(() {
      mockAuth = _MockAuthRepository();
      mockStores = _MockStoresRepository();
      mockStorage = _MockStorageRepository();
      mockPicker = _MockImagePickerService();
      viewModel = EditStoreProfileViewModel(
        storeDetails: buildStore(),
        authRepository: mockAuth,
        storesRepository: mockStores,
        storageRepository: mockStorage,
        imagePickerService: mockPicker,
      );
    });

    tearDown(() => viewModel.dispose());

    test('constructor seeds nameController with storeName', () {
      expect(viewModel.nameController.text, 'Cebu Greens');
      expect(viewModel.profileImage, isNull);
      expect(viewModel.storeId, 'uid-1');
      expect(viewModel.isLoading, isFalse);
    });

    group('pickImage', () {
      test('stores bytes and notifies when picker returns data', () async {
        final bytes = Uint8List.fromList([1, 2, 3]);
        when(() => mockPicker.pickImageFromGallery()).thenAnswer((_) async => bytes);
        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.pickImage();

        expect(viewModel.profileImage, bytes);
        expect(notified, isTrue);
      });

      test('does nothing when picker returns null', () async {
        when(() => mockPicker.pickImageFromGallery()).thenAnswer((_) async => null);
        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.pickImage();

        expect(viewModel.profileImage, isNull);
        expect(notified, isFalse);
      });
    });

    group('updateStoreProfile', () {
      test('does nothing when name is empty', () async {
        viewModel.nameController.text = '';

        await viewModel.updateStoreProfile();

        verifyNever(() => mockStores.updateFields(any(), any()));
        verifyNever(() => mockStorage.uploadBytes(path: any(named: 'path'), bytes: any(named: 'bytes')));
      });

      test('updates store_name only when no image is selected', () async {
        when(() => mockStores.updateFields(any(), any())).thenAnswer((_) async {});
        viewModel.nameController.text = 'Renamed Store';

        await viewModel.updateStoreProfile();

        verify(() => mockStores.updateFields('uid-1', {'store_name': 'Renamed Store'})).called(1);
        verifyNever(() => mockStorage.uploadBytes(path: any(named: 'path'), bytes: any(named: 'bytes')));
      });

      test('uploads image first and includes store_image_url when image is set', () async {
        when(() => mockAuth.currentUserId).thenReturn('uid-1');
        when(() => mockStorage.uploadBytes(path: any(named: 'path'), bytes: any(named: 'bytes')))
            .thenAnswer((_) async => 'https://cdn/avatars/uid-1.jpg');
        when(() => mockStores.updateFields(any(), any())).thenAnswer((_) async {});
        final bytes = Uint8List.fromList([9, 9, 9]);
        when(() => mockPicker.pickImageFromGallery()).thenAnswer((_) async => bytes);
        await viewModel.pickImage();

        await viewModel.updateStoreProfile();

        verify(() => mockStorage.uploadBytes(path: 'user_avatars/uid-1.jpg', bytes: bytes)).called(1);
        verify(() => mockStores.updateFields('uid-1', {
              'store_name': 'Cebu Greens',
              'store_image_url': 'https://cdn/avatars/uid-1.jpg',
            })).called(1);
      });

      test('swallows update errors and clears loading', () async {
        when(() => mockStores.updateFields(any(), any())).thenThrow(Exception('permission denied'));

        await viewModel.updateStoreProfile();

        expect(viewModel.isLoading, isFalse);
      });
    });
  });
}
