import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'yolo_detection_service.dart';
import 'doctr_service.dart';
import 'densenet_service.dart';

/// Change this to your ML backend URL.
const String kMlBaseUrl = 'https://your-ml-api.example.com';

class MLService {
  final YoloDetectionService _yoloService = YoloDetectionService();
  final DoctrService _doctrService = DoctrService();
  final DensenetService _densenetService = DensenetService();

  /// Initialize all ML services
  Future<void> initialize() async {
    try {
      await _yoloService.initialize();
      await _densenetService.initialize();
      debugPrint('ML Services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ML services: $e');
    }
  }

  /// DenseNet Classification: Diagnose chest X-ray
  Future<DensenetResult> classifyXray({
    required dynamic imageFile,
  }) async {
    try {
      return await _densenetService.classify(imageFile: imageFile);
    } catch (e) {
      debugPrint('Classification error: $e');
      return DensenetResult.error('Classification failed: $e');
    }
  }

  /// YOLO Detection: Detect anomalies in chest X-ray
  /// Returns detection objects with confidence scores
  Future<YoloDetectionResult> detectAnomalies({
    required dynamic imageFile, // File on mobile, Uint8List on web
    required int imageWidth,
    required int imageHeight,
  }) async {
    try {
      return await _yoloService.detectObjects(
        imageFile: imageFile,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
    } catch (e) {
      debugPrint('Detection error: $e');
      return YoloDetectionResult.error('Detection failed: $e');
    }
  }

  /// Doctr: Extract and recognize text from document
  /// Useful for analyzing reports, prescriptions, notes
  Future<DocumentText> recognizeDocument({
    required dynamic imageFile, // File on mobile, Uint8List on web
  }) async {
    try {
      return await _doctrService.recognizeDocument(imageFile: imageFile);
    } catch (e) {
      debugPrint('Document recognition error: $e');
      return DocumentText(
        fullText: '',
        blocks: [],
        confidence: 0.0,
        charactersCount: 0,
        keywordsDetected: [],
      );
    }
  }

  /// Extract metadata from recognized document
  Map<String, String> getDocumentMetadata(DocumentText document) {
    return _doctrService.extractDocumentMetadata(document);
  }

  /// Check document quality
  double getDocumentQuality(DocumentText document) {
    return _doctrService.getDocumentQualityScore(document);
  }

  /// Combined analysis: Run YOLO detection, DenseNet classification, and OCR
  /// Returns comprehensive analysis of chest X-ray
  Future<CombinedAnalysisResult> analyzeChestXray({
    required dynamic imageFile, // File on mobile, Uint8List on web
    required String imageUrl, // Already-uploaded Storage URL
    required int imageWidth,
    required int imageHeight,
    bool includeDocumentOCR = true,
    bool useBackendAPI = false,
  }) async {
    try {
      // 1. Run YOLO detection
      final yoloResult = await detectAnomalies(
        imageFile: imageFile,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

      // 2. Run DenseNet classification
      final densenetResult = await classifyXray(imageFile: imageFile);

      // 3. Run OCR if requested
      DocumentText? ocrResult;
      if (includeDocumentOCR) {
        ocrResult = await recognizeDocument(imageFile: imageFile);
      }

      // 4. Optionally use backend API
      MLResponse? backendResult;
      if (useBackendAPI) {
        backendResult = await analyze(
          file: imageFile,
          imageUrl: imageUrl,
          requestHeatmap: false,
        );
      }

      return CombinedAnalysisResult(
        yoloDetection: yoloResult,
        densenetResult: densenetResult,
        documentOCR: ocrResult,
        backendAnalysis: backendResult,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Combined analysis error: $e');
      return CombinedAnalysisResult.error('Analysis failed: $e');
    }
  }

  /// Submit a chest X-ray for classification (Backend API).
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

  /// Clean up resources
  void dispose() {
    _yoloService.dispose();
    _doctrService.dispose();
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

/// Combined result from YOLO detection + DenseNet + Doctr OCR
class CombinedAnalysisResult {
  final YoloDetectionResult yoloDetection;
  final DensenetResult? densenetResult;
  final DocumentText? documentOCR;
  final MLResponse? backendAnalysis;
  final DateTime timestamp;
  final String? errorMessage;

  const CombinedAnalysisResult({
    required this.yoloDetection,
    this.densenetResult,
    this.documentOCR,
    this.backendAnalysis,
    required this.timestamp,
    this.errorMessage,
  });

  /// Get combined severity assessment
  String getCombinedSeverity() {
    if (errorMessage != null) return 'error';

    // Combine YOLO severity with DenseNet findings
    var severity = yoloDetection.anomalySeverity;

    if (densenetResult != null && densenetResult!.confidence > 0.7) {
      if (densenetResult!.diagnosis.toLowerCase().contains('pneumonia') ||
          densenetResult!.diagnosis.toLowerCase().contains('covid')) {
        if (severity != 'critical') severity = 'moderate';
      }
    }
    
    if (documentOCR != null && _containsCriticalKeywords(documentOCR!)) {
      if (severity != 'critical') {
        severity = 'moderate';
      }
    }

    return severity;
  }

  /// Check if document contains critical findings
  bool _containsCriticalKeywords(DocumentText doc) {
    const criticalTerms = [
      'pneumonia',
      'tuberculosis',
      'fracture',
      'nodule',
      'critical',
      'severe',
    ];

    final text = doc.fullText.toLowerCase();
    return criticalTerms.any((term) => text.contains(term));
  }

  /// Generate comprehensive report
  String generateReport() {
    final buffer = StringBuffer();

    buffer.writeln('=== CHEST X-RAY ANALYSIS REPORT ===\n');
    buffer.writeln('Timestamp: $timestamp\n');

    // YOLO Detection Report
    buffer.writeln('YOLO DETECTION ANALYSIS:');
    buffer.writeln('Severity: ${yoloDetection.anomalySeverity}');
    buffer.writeln('Anomaly Score: ${(yoloDetection.anomalyScore * 100).toStringAsFixed(1)}%');
    buffer.writeln('Primary Finding: ${yoloDetection.primaryAnomaly}');
    buffer.writeln('Detections Found: ${yoloDetection.detections.length}');
    
    if (yoloDetection.detections.isNotEmpty) {
      buffer.writeln('\nDetailed Detections:');
      for (final detection in yoloDetection.getSortedByConfidence()) {
        buffer.writeln(
          '  - ${detection.className}: ${(detection.confidence * 100).toStringAsFixed(1)}%',
        );
      }
    }

    // OCR Report
    if (documentOCR != null) {
      buffer.writeln('\n\nDOCUMENT OCR ANALYSIS:');
      buffer.writeln('Characters Recognized: ${documentOCR!.charactersCount}');
      buffer.writeln('OCR Confidence: ${(documentOCR!.confidence * 100).toStringAsFixed(1)}%');
      
      if (documentOCR!.keywordsDetected.isNotEmpty) {
        buffer.writeln('Medical Keywords Found:');
        for (final keyword in documentOCR!.keywordsDetected) {
          buffer.writeln('  - $keyword');
        }
      }
    }

    // Backend Analysis
    if (backendAnalysis != null && backendAnalysis!.isSuccess) {
      buffer.writeln('\n\nBACKEND ANALYSIS:');
      buffer.writeln('Diagnosis: ${backendAnalysis!.diagnosis}');
      buffer.writeln('Confidence: ${(backendAnalysis!.confidence * 100).toStringAsFixed(1)}%');
    }

    buffer.writeln('\n\nCOMBINED ASSESSMENT:');
    buffer.writeln('Overall Severity: ${getCombinedSeverity()}');
    buffer.writeln(yoloDetection.getSeverityDescription());

    return buffer.toString();
  }

  /// Serialize to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'yoloDetection': yoloDetection.toMap(),
      'documentOCR': documentOCR?.toMap(),
      'backendAnalysis': backendAnalysis != null
          ? {
              'diagnosis': backendAnalysis!.diagnosis,
              'confidence': backendAnalysis!.confidence,
              'classScores': backendAnalysis!.classScores,
            }
          : null,
      'combinedSeverity': getCombinedSeverity(),
    };
  }

  /// Error result
  factory CombinedAnalysisResult.error(String message) => CombinedAnalysisResult(
        yoloDetection: YoloDetectionResult.error(message),
        densenetResult: null,
        documentOCR: null,
        backendAnalysis: null,
        timestamp: DateTime.now(),
        errorMessage: message,
      );

  bool get isSuccess =>
      errorMessage == null &&
      yoloDetection.isSuccess &&
      (densenetResult?.isSuccess ?? true);
}
