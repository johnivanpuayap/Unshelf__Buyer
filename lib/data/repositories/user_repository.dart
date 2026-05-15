abstract class UserRepository {
  /// Returns the raw `users/{userId}` document data, or null if it does not exist.
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// Updates the named fields on `users/{userId}`. Throws if the document does not exist.
  Future<void> updateProfile(String userId, Map<String, dynamic> fields);

  /// Writes lat/lng under [collection]/{userId} with merge semantics.
  /// Kept generic because the buyer app currently writes addresses into
  /// `stores/{uid}` — see AddressViewmodel. Likely a candidate for a dedicated
  /// `StoresRepository.upsertGeo` in a follow-up cleanup.
  Future<void> upsertLocation({
    required String collection,
    required String userId,
    required double latitude,
    required double longitude,
  });
}
