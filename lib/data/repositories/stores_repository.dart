abstract class StoresRepository {
  /// Returns the raw `stores/{storeId}` document data, or null if it does not exist.
  Future<Map<String, dynamic>?> fetchById(String storeId);

  /// Updates the named fields on `stores/{storeId}`. Throws if the document does not exist.
  Future<void> updateFields(String storeId, Map<String, dynamic> fields);

  /// Writes lat/lng under `stores/{storeId}` with merge semantics.
  /// Replaces the older `UserRepository.upsertLocation(collection: 'stores', ...)` leak.
  Future<void> upsertGeo({
    required String storeId,
    required double latitude,
    required double longitude,
  });
}
