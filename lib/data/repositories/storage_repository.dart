import 'dart:typed_data';

/// Abstraction over the binary blob store (Firebase Storage today).
abstract class StorageRepository {
  /// Returns download URLs for every item under [path].
  Future<List<String>> listDownloadUrls(String path);

  /// Uploads [bytes] to [path] and returns the resulting download URL.
  Future<String> uploadBytes({required String path, required Uint8List bytes});
}
