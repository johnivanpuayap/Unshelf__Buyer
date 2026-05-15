abstract class AuthRepository {
  /// Currently signed-in user's UID, or null if no one is signed in.
  String? get currentUserId;

  /// Updates the signed-in user's password.
  ///
  /// Throws if no user is signed in or the underlying provider rejects.
  Future<void> updatePassword(String newPassword);
}
