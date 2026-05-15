import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';

class FirebaseProductRepository implements ProductRepository {
  FirebaseProductRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<DocumentSnapshot>> searchByName(String query) async {
    // U+F8FF (Unicode Private Use Area) is the high end of a Firestore prefix-range query.
    final result = await _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '${query}')
        .get();
    return result.docs;
  }

  @override
  Stream<QuerySnapshot> watchProducts() => _firestore.collection('products').snapshots();

  @override
  Stream<QuerySnapshot> watchBundles() => _firestore.collection('bundles').snapshots();
}
