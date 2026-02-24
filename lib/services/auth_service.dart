import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../models/app_user.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _db = FirestoreService();

  User? get firebaseUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      _appUser = await _db.getUser(user.uid);
    } else {
      _appUser = null;
    }
    notifyListeners();
  }

  /// Sign in with email + password. Returns null on success, error string on failure.
  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      _appUser = await _db.getUser(cred.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  /// Register doctor.
  Future<String?> registerDoctor({
    required String name,
    required String licenseNumber,
    required String specialization,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name);
      final user = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email.trim(),
        phone: phone,
        role: 'doctor',
        licenseNumber: licenseNumber,
        specialization: specialization,
      );
      await _db.saveUser(user);
      _appUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  /// Register patient.
  Future<String?> registerPatient({
    required String name,
    required String age,
    required String gender,
    required String bloodGroup,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name);
      final user = AppUser(
        uid: cred.user!.uid,
        name: name,
        email: email.trim(),
        phone: phone,
        role: 'patient',
        age: age,
        gender: gender,
        bloodGroup: bloodGroup,
      );
      await _db.saveUser(user);
      _appUser = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _appUser = null;
    notifyListeners();
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
