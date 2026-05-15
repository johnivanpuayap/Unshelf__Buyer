import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/data/repositories/stores_repository.dart';
import 'package:unshelf_buyer/models/store_model.dart';
import 'package:unshelf_buyer/services/image_picker_service.dart';

class EditStoreProfileViewModel extends ChangeNotifier {
  EditStoreProfileViewModel({
    required StoreModel storeDetails,
    required AuthRepository authRepository,
    required StoresRepository storesRepository,
    required StorageRepository storageRepository,
    required ImagePickerService imagePickerService,
  })  : storeId = storeDetails.userId,
        _authRepository = authRepository,
        _storesRepository = storesRepository,
        _storageRepository = storageRepository,
        _imagePickerService = imagePickerService {
    _nameController = TextEditingController(text: storeDetails.storeName);
  }

  final String storeId;
  final AuthRepository _authRepository;
  final StoresRepository _storesRepository;
  final StorageRepository _storageRepository;
  final ImagePickerService _imagePickerService;

  late TextEditingController _nameController;
  Uint8List? _profileImage;
  bool _loading = false;

  TextEditingController get nameController => _nameController;
  Uint8List? get profileImage => _profileImage;
  bool get isLoading => _loading;

  Future<void> pickImage() async {
    final bytes = await _imagePickerService.pickImageFromGallery();
    if (bytes != null) {
      _profileImage = bytes;
      notifyListeners();
    }
  }

  Future<void> updateStoreProfile() async {
    if (_nameController.text.isEmpty) return;

    _loading = true;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{'store_name': _nameController.text};

      if (_profileImage != null) {
        final imageUrl = await _uploadImage(_profileImage!);
        updateData['store_image_url'] = imageUrl;
      }

      await _storesRepository.updateFields(storeId, updateData);
    } catch (e) {
      debugPrint('updateStoreProfile failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadImage(Uint8List bytes) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      throw StateError('No signed-in user');
    }
    return _storageRepository.uploadBytes(
      path: 'user_avatars/$userId.jpg',
      bytes: bytes,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
