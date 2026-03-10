import 'dart:convert';
import 'dart:io' as io;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MLService {
  static const String _baseUrl = 'http://192.168.1.103:5001'; 
  static const int _timeout = 120; // seconds

  final http.Client _client = http.Client();

  /// Check if the API server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// 1. Validate if uploaded image is a CT scan
  Future<ValidateCTResponse> validateCT(dynamic imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/validate-ct');
      final request = http.MultipartRequest('POST', uri);
      
      await _addFileToRequest(request, imageFile);
      
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        return ValidateCTResponse.fromJson(data);
      } else {
        final errorData = _safeDecode(response.body);
        return ValidateCTResponse(
          isCTScan: false,
          colorScore: 0,
          message: errorData['error'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return ValidateCTResponse(isCTScan: false, colorScore: 0, message: 'Validation timed out. Please check your network.');
    } on io.SocketException {
      return ValidateCTResponse(isCTScan: false, colorScore: 0, message: 'Cannot reach server. Ensure backend is running.');
    } catch (e) {
      return ValidateCTResponse(isCTScan: false, colorScore: 0, message: 'Validation failed: $e');
    }
  }

  /// 2. Full analysis using the backend AI API (YOLO + Classification + Grad-CAM)
  Future<AnalysisResponse> analyzeWithBackend(dynamic imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/analyze');
      final request = http.MultipartRequest('POST', uri);
      
      await _addFileToRequest(request, imageFile);

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: _timeout));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        return AnalysisResponse.fromJson(data);
      } else {
        final data = _safeDecode(response.body);
        return AnalysisResponse.error(data['error'] ?? 'Backend analysis failed (Error ${response.statusCode})');
      }
    } on TimeoutException {
      return AnalysisResponse.error('Analysis timed out. The image might be too large or the server is busy.');
    } on io.SocketException {
      return AnalysisResponse.error('Connection failed: Ensure backend is running at $_baseUrl.');
    } on FormatException {
      return AnalysisResponse.error('Invalid response format from server.');
    } catch (e) {
      debugPrint('Backend analysis error: $e');
      return AnalysisResponse.error('Unexpected error: $e');
    }
  }

  Future<void> _addFileToRequest(http.MultipartRequest request, dynamic imageFile) async {
    if (kIsWeb) {
      if (imageFile is Uint8List) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageFile,
            filename: 'scan.jpg',
          ),
        );
      }
    } else {
      if (imageFile is io.File) {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      } else if (imageFile is Uint8List) {
         request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageFile,
            filename: 'scan.jpg',
          ),
        );
      }
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      return json.decode(body);
    } catch (e) {
      debugPrint('JSON Decode Error: $e');
      return {'error': 'Failed to parse server response'};
    }
  }

  Future<void> initialize() async {
    debugPrint('ML Service (Cloud) ready');
  }

  void dispose() {
    _client.close();
  }
}


class ValidateCTResponse {
  final bool isCTScan;
  final double colorScore;
  final String message;

  ValidateCTResponse({
    required this.isCTScan,
    required this.colorScore,
    required this.message,
  });

  factory ValidateCTResponse.fromJson(Map<String, dynamic> json) {
    return ValidateCTResponse(
      isCTScan: json['is_ct_scan'] ?? false,
      colorScore: (json['color_score'] ?? 0).toDouble(),
      message: json['message'] ?? '',
    );
  }
}

class AnalysisResponse {
  final bool success;
  final int tumorsDetected;
  final List<TumorDetection> detections;
  final String detectionImage; // base64
  final String heatmapImage;   // base64
  final String? message;
  final String? errorMessage;

  AnalysisResponse({
    required this.success,
    required this.tumorsDetected,
    required this.detections,
    required this.detectionImage,
    required this.heatmapImage,
    this.message,
    this.errorMessage,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      success: json['success'] ?? false,
      tumorsDetected: json['tumors_detected'] ?? 0,
      detections: (json['detections'] as List? ?? [])
          .map((d) => TumorDetection.fromJson(d))
          .toList(),
      detectionImage: json['detection_image'] ?? '',
      heatmapImage: json['heatmap_image'] ?? '',
      message: json['message'],
    );
  }

  factory AnalysisResponse.error(String error) {
    return AnalysisResponse(
      success: false,
      tumorsDetected: 0,
      detections: [],
      detectionImage: '',
      heatmapImage: '',
      errorMessage: error,
    );
  }

  bool get isSuccess => success && errorMessage == null;

  String get diagnosis => detections.isNotEmpty 
      ? detections.first.prediction 
      : (tumorsDetected == 0 ? 'Normal / No Tumor Detected' : 'Tumor Detected');

  double get confidence => detections.isNotEmpty 
      ? detections.first.confidence / 100.0 
      : 0.0;
}

class TumorDetection {
  final int tumorId;
  final List<int> bbox;
  final List<int> bboxWithPadding;
  final String prediction;
  final double confidence;
  final Map<String, double> allConfidences;
  final String cropImage;     // base64
  final String heatmapImage;  // base64

  TumorDetection({
    required this.tumorId,
    required this.bbox,
    required this.bboxWithPadding,
    required this.prediction,
    required this.confidence,
    required this.allConfidences,
    required this.cropImage,
    required this.heatmapImage,
  });

  factory TumorDetection.fromJson(Map<String, dynamic> json) {
    return TumorDetection(
      tumorId: json['tumor_id'] ?? 0,
      bbox: List<int>.from(json['bbox'] ?? []),
      bboxWithPadding: List<int>.from(json['bbox_with_padding'] ?? []),
      prediction: json['prediction'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      allConfidences: Map<String, double>.from(
        (json['all_confidences'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      cropImage: json['crop_image'] ?? '',
      heatmapImage: json['heatmap_image'] ?? '',
    );
  }
}
