import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/data/repositories/stores_repository.dart';

class FirebaseStoresRepository implements StoresRepository {
  FirebaseStoresRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> fetchById(String storeId) async {
    final snap = await _firestore.collection('stores').doc(storeId).get();
    return snap.data();
  }

  @override
  Future<void> updateFields(String storeId, Map<String, dynamic> fields) {
    return _firestore.collection('stores').doc(storeId).update(fields);
  }

  @override
  Future<void> upsertGeo({
    required String storeId,
    required double latitude,
    required double longitude,
  }) {
    return _firestore.collection('stores').doc(storeId).set(
      {'latitude': latitude, 'longitude': longitude},
      SetOptions(merge: true),
    );
  }
}
