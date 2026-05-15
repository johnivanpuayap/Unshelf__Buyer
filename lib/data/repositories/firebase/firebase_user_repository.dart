import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final snap = await _firestore.collection('users').doc(userId).get();
    return snap.data();
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> fields) {
    return _firestore.collection('users').doc(userId).update(fields);
  }

  @override
  Future<int> fetchFollowersCount(String userId) async {
    final snap = await _firestore.collection('users').doc(userId).collection('followers').get();
    return snap.size;
  }

  @override
  Future<void> upsertLocation({
    required String collection,
    required String userId,
    required double latitude,
    required double longitude,
  }) {
    return _firestore.collection(collection).doc(userId).set(
      {'latitude': latitude, 'longitude': longitude},
      SetOptions(merge: true),
    );
  }
}
