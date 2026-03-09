import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ServiceModel>> getServicesStream() {
    return _db
        .collection('services')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceModel.fromFirestore).toList());
  }

  Stream<List<ServiceModel>> getMyListingsStream(String userId) {
    return _db
        .collection('services')
        .where('createdBy', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceModel.fromFirestore).toList());
  }

  Future<void> createService(ServiceModel service) async {
    await _db.collection('services').add(service.toFirestore());
  }

  Future<void> updateService(ServiceModel service) async {
    await _db.collection('services').doc(service.id).update(service.toFirestore());
  }

  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  Stream<List<ReviewModel>> getReviewsStream(String serviceId) {
    return _db
        .collection('reviews')
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReviewModel.fromFirestore).toList());
  }

  Future<void> addReview(ReviewModel review) async {
    await _db.collection('reviews').add(review.toFirestore());
    final reviews = await _db
        .collection('reviews')
        .where('serviceId', isEqualTo: review.serviceId)
        .get();
    final total = reviews.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .fold(0.0, (a, b) => a + b);
    final avg = total / reviews.docs.length;
    await _db.collection('services').doc(review.serviceId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': reviews.docs.length,
    });
  }
}
