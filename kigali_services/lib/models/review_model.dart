import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String serviceId;
  final String userId;
  final String author;
  final double rating;
  final String comment;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.author,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      serviceId: data['serviceId'] ?? '',
      userId: data['userId'] ?? '',
      author: data['author'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceId': serviceId,
      'userId': userId,
      'author': author,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
