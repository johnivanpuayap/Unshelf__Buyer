import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ProductRepository {
  Future<List<DocumentSnapshot>> searchByName(String query);
  Stream<QuerySnapshot> watchProducts();
  Stream<QuerySnapshot> watchBundles();
}
