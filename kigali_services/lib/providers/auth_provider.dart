import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, unverified }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

 void _onAuthStateChanged(User? user) {
  _user = user;
  if (user == null) {
    _status = AuthStatus.unauthenticated;
  } else if (!user.emailVerified) {
    _status = AuthStatus.unverified;
  } else {
    _status = AuthStatus.authenticated;
  }
  notifyListeners();
}


  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signUp(email: email, password: password, displayName: displayName);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

Future<void> reloadUser() async {
  await _authService.reloadUser();
  final user = _authService.currentUser;
  _user = user;
  if (user == null) {
    _status = AuthStatus.unauthenticated;
  } else if (!user.emailVerified) {
    _status = AuthStatus.unverified;
  } else {
    _status = AuthStatus.authenticated;
  }
  notifyListeners();
}

Future<void> signOut() async {
  await _authService.signOut();
}


  String _mapError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
