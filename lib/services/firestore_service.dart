import 'package:cloud_firestore/cloud_firestore.dart';
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
