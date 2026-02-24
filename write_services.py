"""Write all service files and new screens for ChestSense Firebase integration."""
import os

BASE = "/Users/noumanusman/Documents/Flutter App/chestsense/lib"
os.makedirs(f"{BASE}/services", exist_ok=True)
os.makedirs(f"{BASE}/models", exist_ok=True)
os.makedirs(f"{BASE}/screens/shared", exist_ok=True)

files = {}

# ── USER MODEL ─────────────────────────────────────────────────────────────────
files["models/app_user.dart"] = r"""class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'doctor' | 'patient'
  // Doctor-specific
  final String licenseNumber;
  final String specialization;
  // Patient-specific
  final String age;
  final String gender;
  final String bloodGroup;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.licenseNumber = '',
    this.specialization = '',
    this.age = '',
    this.gender = '',
    this.bloodGroup = '',
    this.photoUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] ?? 'patient',
        licenseNumber: m['licenseNumber'] ?? '',
        specialization: m['specialization'] ?? '',
        age: m['age'] ?? '',
        gender: m['gender'] ?? '',
        bloodGroup: m['bloodGroup'] ?? '',
        photoUrl: m['photoUrl'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'licenseNumber': licenseNumber,
        'specialization': specialization,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'photoUrl': photoUrl,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? age,
    String? gender,
    String? bloodGroup,
    String? licenseNumber,
    String? specialization,
    String? photoUrl,
  }) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        specialization: specialization ?? this.specialization,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
"""

# ── ANALYSIS RESULT MODEL ──────────────────────────────────────────────────────
files["models/analysis_result.dart"] = r"""class AnalysisResult {
  final String id;
  final String userId;
  final String imageUrl;
  final String? heatmapUrl;
  final String diagnosis;        // e.g. 'Pneumonia', 'Normal', 'COVID-19'
  final double confidence;       // 0.0 – 1.0
  final Map<String, double> classScores; // all class probabilities
  final DateTime createdAt;
  final String status;           // 'pending' | 'complete' | 'error'

  const AnalysisResult({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.heatmapUrl,
    required this.diagnosis,
    required this.confidence,
    required this.classScores,
    required this.createdAt,
    required this.status,
  });

  factory AnalysisResult.fromMap(String id, Map<String, dynamic> m) =>
      AnalysisResult(
        id: id,
        userId: m['userId'] ?? '',
        imageUrl: m['imageUrl'] ?? '',
        heatmapUrl: m['heatmapUrl'],
        diagnosis: m['diagnosis'] ?? '',
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0,
        classScores: Map<String, double>.from(
          (m['classScores'] as Map?)
                  ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
              {},
        ),
        createdAt: m['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
            : DateTime.now(),
        status: m['status'] ?? 'pending',
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'imageUrl': imageUrl,
        'heatmapUrl': heatmapUrl,
        'diagnosis': diagnosis,
        'confidence': confidence,
        'classScores': classScores,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'status': status,
      };
}
"""

# ── AUTH SERVICE ───────────────────────────────────────────────────────────────
files["services/auth_service.dart"] = r"""import 'package:firebase_auth/firebase_auth.dart';
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
"""

# ── FIRESTORE SERVICE ──────────────────────────────────────────────────────────
files["services/firestore_service.dart"] = r"""import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/analysis_result.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────────────
  Future<void> saveUser(AppUser user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> updateUser(AppUser user) =>
      _db.collection('users').doc(user.uid).update(user.toMap());

  // ── Analysis results ───────────────────────────────────────────────────────
  Future<String> saveResult(AnalysisResult result) async {
    final ref = await _db.collection('analyses').add(result.toMap());
    return ref.id;
  }

  Future<void> updateResult(String id, Map<String, dynamic> data) =>
      _db.collection('analyses').doc(id).update(data);

  Stream<List<AnalysisResult>> userAnalysesStream(String userId) =>
      _db
          .collection('analyses')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AnalysisResult.fromMap(d.id, d.data()))
              .toList());

  Future<List<AnalysisResult>> getUserAnalyses(String userId) async {
    final snap = await _db
        .collection('analyses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => AnalysisResult.fromMap(d.id, d.data()))
        .toList();
  }
}
"""

# ── STORAGE SERVICE ────────────────────────────────────────────────────────────
files["services/storage_service.dart"] = r"""import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an X-ray image and return the download URL.
  Future<String> uploadXray({
    required String userId,
    required dynamic file, // File on mobile, Uint8List on web
    String? existingPath,
  }) async {
    final path = existingPath ??
        'xrays/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(path);

    UploadTask task;
    if (kIsWeb) {
      task = ref.putData(file as Uint8List,
          SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(file as File);
    }

    await task;
    return await ref.getDownloadURL();
  }

  /// Delete a stored file by its URL.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
"""

# ── ML SERVICE ─────────────────────────────────────────────────────────────────
files["services/ml_service.dart"] = r"""import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

/// Change this to your ML backend URL.
const String kMlBaseUrl = 'https://your-ml-api.example.com';

class MLService {
  /// Submit a chest X-ray for classification.
  /// Expects the backend to respond with:
  /// {
  ///   "diagnosis": "Pneumonia",
  ///   "confidence": 0.94,
  ///   "class_scores": {"Normal": 0.04, "Pneumonia": 0.94, "COVID-19": 0.02},
  ///   "heatmap_url": "https://..."   // optional, for doctor view
  /// }
  Future<MLResponse> analyze({
    required dynamic file, // File on mobile, Uint8List on web
    required String imageUrl, // Already-uploaded Storage URL
    bool requestHeatmap = false,
  }) async {
    try {
      final uri = Uri.parse('$kMlBaseUrl/analyze');
      final request = http.MultipartRequest('POST', uri);
      request.fields['image_url'] = imageUrl;
      request.fields['heatmap'] = requestHeatmap.toString();

      if (kIsWeb) {
        final bytes = file as Uint8List;
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'xray.jpg'),
        );
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('file', (file as File).path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return MLResponse(
          diagnosis: json['diagnosis'] as String? ?? 'Unknown',
          confidence:
              (json['confidence'] as num?)?.toDouble() ?? 0.0,
          classScores: Map<String, double>.from(
            (json['class_scores'] as Map?)
                    ?.map((k, v) =>
                        MapEntry(k as String, (v as num).toDouble())) ??
                {},
          ),
          heatmapUrl: json['heatmap_url'] as String?,
          status: AnalysisStatus.complete,
        );
      } else {
        return MLResponse.error(
            'Server returned ${streamed.statusCode}. Check your ML endpoint.');
      }
    } on SocketException {
      return MLResponse.error(
          'Cannot reach ML server. Check your network or endpoint URL.');
    } catch (e) {
      return MLResponse.error(e.toString());
    }
  }
}

enum AnalysisStatus { complete, error }

class MLResponse {
  final String diagnosis;
  final double confidence;
  final Map<String, double> classScores;
  final String? heatmapUrl;
  final AnalysisStatus status;
  final String? errorMessage;

  const MLResponse({
    required this.diagnosis,
    required this.confidence,
    required this.classScores,
    this.heatmapUrl,
    required this.status,
    this.errorMessage,
  });

  factory MLResponse.error(String msg) => MLResponse(
        diagnosis: '',
        confidence: 0,
        classScores: {},
        status: AnalysisStatus.error,
        errorMessage: msg,
      );

  bool get isSuccess => status == AnalysisStatus.complete;
}
"""

for rel, content in files.items():
    path = f"{BASE}/{rel}"
    with open(path, "w") as f:
        f.write(content)
    print(f"  wrote {rel}")

print("\nService layer done!")
