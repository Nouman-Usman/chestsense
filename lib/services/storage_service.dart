import 'dart:io';
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
