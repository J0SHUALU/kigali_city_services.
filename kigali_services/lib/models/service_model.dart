import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String createdBy;
  final DateTime timestamp;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.createdBy,
    required this.timestamp,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'address': address,
      'phone': phone,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdBy': createdBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  ServiceModel copyWith({
    String? name,
    String? category,
    String? address,
    String? phone,
    String? description,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdBy: createdBy,
      timestamp: timestamp,
    );
  }
}
