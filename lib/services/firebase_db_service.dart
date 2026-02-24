import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Create user document
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String role, // 'doctor' or 'patient'
    required String displayName,
    required String phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Stream user data
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Create patient profile
  Future<void> createPatientProfile({
    required String uid,
    required String age,
    required String gender,
    String? medicalHistory,
  }) async {
    try {
      await _firestore.collection('patients').doc(uid).set({
        'uid': uid,
        'age': age,
        'gender': gender,
        'medicalHistory': medicalHistory ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Create doctor profile
  Future<void> createDoctorProfile({
    required String uid,
    required String specialization,
    required String licenseNumber,
    String? hospitalAffiliation,
  }) async {
    try {
      await _firestore.collection('doctors').doc(uid).set({
        'uid': uid,
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'hospitalAffiliation': hospitalAffiliation ?? '',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Store ECG data (for patients)
  Future<void> storeECGData({
    required String patientUid,
    required List<double> ecgValues,
    required String heartRate,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientUid)
          .collection('ecgData')
          .add({
        'ecgValues': ecgValues,
        'heartRate': heartRate,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get patient's ECG data
  Stream<QuerySnapshot<Map<String, dynamic>>> getPatientECGDataStream(
    String patientUid,
  ) {
    return _firestore
        .collection('patients')
        .doc(patientUid)
        .collection('ecgData')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add patient-doctor connection
  Future<void> addPatientDoctorConnection({
    required String patientUid,
    required String doctorUid,
  }) async {
    try {
      // Add doctor reference to patient's connections
      await _firestore
          .collection('patients')
          .doc(patientUid)
          .update({
        'associatedDoctors': FieldValue.arrayUnion([doctorUid]),
      });

      // Add patient reference to doctor's patients
      await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .update({
        'patients': FieldValue.arrayUnion([patientUid]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove patient-doctor connection
  Future<void> removePatientDoctorConnection({
    required String patientUid,
    required String doctorUid,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientUid)
          .update({
        'associatedDoctors': FieldValue.arrayRemove([doctorUid]),
      });

      await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .update({
        'patients': FieldValue.arrayRemove([patientUid]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get doctor's patients list
  Future<List<Map<String, dynamic>>> getDoctorPatients(String doctorUid) async {
    try {
      final doc = await _firestore.collection('doctors').doc(doctorUid).get();
      final patientIds = List<String>.from(doc.data()?['patients'] ?? []);

      if (patientIds.isEmpty) return [];

      final patients = await Future.wait(
        patientIds.map((id) => getUserData(id)),
      );

      return patients.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create notification
  Future<void> createNotification({
    required String recipientUid,
    required String title,
    required String message,
    String? relatedDocId,
  }) async {
    try {
      await _firestore
          .collection('notifications')
          .add({
        'recipientUid': recipientUid,
        'title': title,
        'message': message,
        'relatedDocId': relatedDocId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user notifications
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(
    String uid,
  ) {
    return _firestore
        .collection('notifications')
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // ── X-Ray Analysis ─────────────────────────────────────────────────────────

  /// Persist an analysis result under the patient's subcollection.
  Future<String> saveAnalysisResult({
    required String patientUid,
    required String imageUrl,
    required String diagnosis,
    required double confidence,
    required Map<String, double> classScores,
    String? heatmapUrl,
  }) async {
    final ref = await _firestore
        .collection('patients')
        .doc(patientUid)
        .collection('analyses')
        .add({
      'patientUid': patientUid,
      'imageUrl': imageUrl,
      'heatmapUrl': heatmapUrl,
      'diagnosis': diagnosis,
      'confidence': confidence,
      'classScores': classScores,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream all analyses for a patient (latest first).
  Stream<QuerySnapshot<Map<String, dynamic>>> getAnalysesStream(
      String patientUid) {
    return _firestore
        .collection('patients')
        .doc(patientUid)
        .collection('analyses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// One-shot fetch for doctor viewing a patient's analyses.
  Future<List<Map<String, dynamic>>> getPatientAnalyses(
      String patientUid) async {
    final snap = await _firestore
        .collection('patients')
        .doc(patientUid)
        .collection('analyses')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // Get user role (doctor or patient)
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      rethrow;
    }
  }
}
