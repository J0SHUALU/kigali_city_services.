import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

enum LoadingState { idle, loading, success, error }

class ServicesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // ── All-services state (Directory tab) ─────────────────────────────────────
  List<ServiceModel> _allServices = [];
  List<ServiceModel> _filteredServices = [];
  String _searchQuery = '';
  String _selectedCategory = '';
  LoadingState _state = LoadingState.idle;
  String? _errorMessage;
  StreamSubscription<List<ServiceModel>>? _servicesSub;

  // ── My-listings state (My Listings tab) ────────────────────────────────────
  List<ServiceModel> _myListings = [];
  LoadingState _myListingsState = LoadingState.idle;
  StreamSubscription<List<ServiceModel>>? _myListingsSub;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<ServiceModel> get services =>
      _searchQuery.isEmpty && _selectedCategory.isEmpty
          ? _allServices
          : _filteredServices;

  List<ServiceModel> get myListings => _myListings;

  LoadingState get state => _state;
  LoadingState get myListingsState => _myListingsState;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  // ── Stream listeners ───────────────────────────────────────────────────────

  /// Starts listening to all services. Safe to call multiple times —
  /// only creates one subscription.
  void listenToServices() {
    if (_servicesSub != null) return;
    _state = LoadingState.loading;
    notifyListeners();
    _servicesSub = _firestoreService.getServicesStream().listen(
      (services) {
        _allServices = services;
        _applyFilter();
        _state = LoadingState.success;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _state = LoadingState.error;
        notifyListeners();
      },
    );
  }

  /// Starts listening to the authenticated user's own listings via the
  /// Provider state — UI reads [myListings], never a raw Firestore stream.
  void listenToMyListings(String userId) {
    _myListingsSub?.cancel();
    _myListingsState = LoadingState.loading;
    notifyListeners();
    _myListingsSub = _firestoreService.getMyListingsStream(userId).listen(
      (listings) {
        _myListings = listings;
        _myListingsState = LoadingState.success;
        notifyListeners();
      },
      onError: (_) {
        _myListingsState = LoadingState.error;
        notifyListeners();
      },
    );
  }

  /// Stops all Firestore subscriptions and resets state (called on sign-out).
  void stopListening() {
    _servicesSub?.cancel();
    _servicesSub = null;
    _myListingsSub?.cancel();
    _myListingsSub = null;
    _myListings = [];
    _allServices = [];
    _filteredServices = [];
    _state = LoadingState.idle;
    _myListingsState = LoadingState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _servicesSub?.cancel();
    _myListingsSub?.cancel();
    super.dispose();
  }

  // ── Search & filter ────────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category == _selectedCategory ? '' : category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredServices = _allServices.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery) ||
          s.description.toLowerCase().contains(_searchQuery) ||
          s.address.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedCategory.isEmpty || s.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ── CRUD (delegated to service layer) ─────────────────────────────────────
  Future<void> createService(ServiceModel service) async =>
      await _firestoreService.createService(service);

  Future<void> updateService(ServiceModel service) async =>
      await _firestoreService.updateService(service);

  Future<void> deleteService(String serviceId) async =>
      await _firestoreService.deleteService(serviceId);

  // ── Reviews (pass-through to service layer) ───────────────────────────────
  Stream<List<ReviewModel>> getReviewsStream(String serviceId) =>
      _firestoreService.getReviewsStream(serviceId);

  Future<void> addReview(ReviewModel review) async =>
      await _firestoreService.addReview(review);
}
