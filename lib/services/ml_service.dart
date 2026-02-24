import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
