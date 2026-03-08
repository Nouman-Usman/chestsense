import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'doctr_service.dart';
import 'densenet_service.dart';

class MLService {
  // Update this to your local machine IP (e.g., 192.168.1.x)
  // 10.0.2.2 is the special alias for your host machine in Android Emulator
  static const String _baseUrl = 'http://192.168.1.103:5001/'; 
  
  final DoctrService _doctrService = DoctrService();
  final DensenetService _densenetService = DensenetService();

  /// Full analysis using the backend AI API (gradH-CAM + Prediction)
  Future<CombinedAnalysisResult> analyzeWithBackend(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/analyze');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final densenetResult = DensenetResult(
          diagnosis: data['prediction'],
          confidence: (data['confidence'] as num).toDouble() / 100.0, // Scale to 0.0-1.0
          classScores: {}, // Backend doesn't return all scores in this format yet
          heatmapBytes: base64Decode(data['heatmap_image']),
        );

        return CombinedAnalysisResult(
          densenetResult: densenetResult,
          documentOCR: null,
          timestamp: DateTime.now(),
        );
      } else {
        final error = json.decode(response.body);
        return CombinedAnalysisResult.error(error['error'] ?? 'Backend analysis failed');
      }
    } catch (e) {
      debugPrint('Backend analysis error: $e');
      return CombinedAnalysisResult.error('Connection failed: Ensure backend is running.');
    }
  }

  /// Check if the API server is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health')).timeout(const Duration(seconds: 3));
      final data = json.decode(response.body);
      return data['status'] == 'healthy' && data['model_loaded'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Initialize all ML services
  Future<void> initialize() async {
    try {
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

  /// Doctr: Extract and recognize text from document
  Future<DocumentText> recognizeDocument({
    required dynamic imageFile,
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

  /// Combined analysis: Run DenseNet classification and OCR (Local Fallback)
  Future<CombinedAnalysisResult> analyzeChestXray({
    required dynamic imageFile,
    required int imageWidth,
    required int imageHeight,
    bool includeDocumentOCR = true,
  }) async {
    try {
      // 1. Run DenseNet Classification (Full Image)
      final densenetResult = await _densenetService.classify(imageFile: imageFile);

      // 2. Run OCR if requested
      DocumentText? ocrResult;
      if (includeDocumentOCR) {
        ocrResult = await recognizeDocument(imageFile: imageFile);
      }

      return CombinedAnalysisResult(
        densenetResult: densenetResult,
        documentOCR: ocrResult,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Combined analysis error: $e');
      return CombinedAnalysisResult.error('Analysis failed: $e');
    }
  }



  /// Clean up resources
  void dispose() {
    _densenetService.dispose();
    _doctrService.dispose();
  }
}



/// Combined result from DenseNet + Doctr OCR
class CombinedAnalysisResult {
  final DensenetResult? densenetResult;
  final DocumentText? documentOCR;
  final DateTime timestamp;
  final String? errorMessage;

  const CombinedAnalysisResult({
    this.densenetResult,
    this.documentOCR,
    required this.timestamp,
    this.errorMessage,
  });

  /// Get combined severity assessment
  String getCombinedSeverity() {
    if (errorMessage != null) return 'error';

    var severity = 'normal';
    final confidence = densenetResult?.confidence ?? 0.0;
    final diagnosis = densenetResult?.diagnosis.toLowerCase() ?? '';

    if (confidence > 0.7) {
      if (diagnosis.contains('adenocarcinoma') || diagnosis.contains('small cell')) {
        severity = 'critical';
      } else if (diagnosis.contains('large cell') || diagnosis.contains('squamous')) {
        severity = 'moderate';
      }
    } else if (confidence > 0.3) {
      severity = 'mild';
    }
    
    if (documentOCR != null && _containsCriticalKeywords(documentOCR!)) {
      if (severity != 'critical') severity = 'moderate';
    }

    return severity;
  }

  /// Check if document contains critical findings
  bool _containsCriticalKeywords(DocumentText doc) {
    const criticalTerms = [
      'adenocarcinoma',
      'small cell',
      'large cell',
      'squamous',
      'pneumonia',
      'fracture',
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

    // Classification Report
    if (densenetResult != null) {
      buffer.writeln('DENSENET CLASSIFICATION:');
      buffer.writeln('Diagnosis: ${densenetResult!.diagnosis}');
      buffer.writeln('Confidence: ${(densenetResult!.confidence * 100).toStringAsFixed(1)}%');
      
      if (densenetResult!.classScores.isNotEmpty) {
        buffer.writeln('\nDetailed Scores:');
        densenetResult!.classScores.forEach((label, score) {
          buffer.writeln('  - $label: ${(score * 100).toStringAsFixed(1)}%');
        });
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

    buffer.writeln('\n\nCOMBINED ASSESSMENT:');
    buffer.writeln('Overall Severity: ${getCombinedSeverity()}');

    return buffer.toString();
  }

  /// Serialize to map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'diagnosis': densenetResult?.diagnosis,
      'confidence': densenetResult?.confidence,
      'classScores': densenetResult?.classScores,
      'documentOCR': documentOCR?.toMap(),
      'combinedSeverity': getCombinedSeverity(),
    };
  }

  /// Error result
  factory CombinedAnalysisResult.error(String message) => CombinedAnalysisResult(
        densenetResult: null,
        documentOCR: null,
        timestamp: DateTime.now(),
        errorMessage: message,
      );

  bool get isSuccess =>
      errorMessage == null &&
      (densenetResult?.isSuccess ?? true);
}
