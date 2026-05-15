import 'package:firebase_storage/firebase_storage.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';

class FirebaseStorageRepository implements StorageRepository {
  FirebaseStorageRepository({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<List<String>> listDownloadUrls(String path) async {
    final ListResult result = await _storage.ref(path).listAll();
    return Future.wait(result.items.map((ref) => ref.getDownloadURL()));
  }
}
