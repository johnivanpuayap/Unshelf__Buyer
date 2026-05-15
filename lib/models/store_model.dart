import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String userId;
  final String email;
  final String name;
  final String phoneNumber;
  final String storeName;
  final double storeLongitude;
  final double storeLatitude;
  // final Map<String, Map<String, String>>? storeSchedule;
  final String? storeImageUrl;
  double? storeRating;
  int? storeFollowers;

  StoreModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.storeName,
    // this.storeSchedule,
    required this.storeLongitude,
    required this.storeLatitude,
    this.storeImageUrl,
    this.storeRating,
    this.storeFollowers,
  });

  // Factory method to create StoreModel from raw user + store maps (Firebase-agnostic).
  factory StoreModel.fromMaps({
    required String userId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> storeData,
  }) {
    return StoreModel(
      userId: userId,
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      storeName: storeData['store_name'] ?? '',
      storeLongitude: (storeData['longitude'] as num?)?.toDouble() ?? 0.0,
      storeLatitude: (storeData['latitude'] as num?)?.toDouble() ?? 0.0,
      storeImageUrl: storeData['store_image_url'] ?? storeData['storeImageUrl'] ?? '',
      storeRating: storeData['rating'] != null ? storeData['rating'].toDouble() : 0.0,
      storeFollowers: storeData['follower_count'] ?? 0,
    );
  }

  // Factory method to create StoreModel from Firebase document snapshot (legacy)
  @Deprecated('Use StoreModel.fromMaps for new code; this couples the model to cloud_firestore.')
  factory StoreModel.fromSnapshot(DocumentSnapshot userDoc, DocumentSnapshot storeDoc) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    Map<String, dynamic> storeData = storeDoc.data() as Map<String, dynamic>;

    return StoreModel(
      userId: userDoc.id,
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      storeName: storeData['store_name'] ?? '',
      // storeSchedule: (storeData['store_schedule'] as Map<String, dynamic>?)?.map(
      //   (key, value) => MapEntry(
      //     key,
      //     (value as Map<String, dynamic>).map(
      //       (k, v) => MapEntry(k, v as String),
      //     ),
      //   ),
      // ),
      storeLongitude: (storeData['longitude'] as num?)!.toDouble(),
      storeLatitude: (storeData['latitude'] as num?)!.toDouble(),
      storeImageUrl: storeData['store_image_url'] ?? storeData['storeImageUrl'] ?? '',
      storeRating: storeData['rating'] != null ? storeData['rating'].toDouble() : 0.0,
      storeFollowers: storeData['follower_count'] ?? 0,
    );
  }
}
