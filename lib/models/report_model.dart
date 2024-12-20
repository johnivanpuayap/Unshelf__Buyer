import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;

  ReportModel({
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': 'Pending',
    };
  }
}
