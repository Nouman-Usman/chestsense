// ⚠️  DEPRECATED: This file is kept for backward compatibility only.
// The old ONNX-based services have been removed.
// 
// MIGRATION TO TFLITE:
// All models have been migrated to TensorFlow Lite format
// Import and use: lib/services/ml_pipeline_service_tflite.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// ⚠️  DEPRECATED - Use MLPipelineServiceTFLite instead
class MLService {
  
  Future<void> initialize() async {
    debugPrint('[MLService] ⚠️  DEPRECATED - Use MLPipelineServiceTFLite');
    debugPrint('[MLService] All ONNX models removed, migrated to TFLite');
  }

  void dispose() {
    // No-op
  }
}

/// Legacy result class - kept for backward compatibility
class YoloDetectionResult {
  final List<YoloDetection> detections;
  final String anomalySeverity;
  final double anomalyScore;
  final String primaryAnomaly;
  final int frameWidth;
  final int frameHeight;

  YoloDetectionResult({
    required this.detections,
    required this.anomalySeverity,
    required this.anomalyScore,
    required this.primaryAnomaly,
    required this.frameWidth,
    required this.frameHeight,
  });
}

class YoloDetection {
  final double x;
  final double y;
  final double width;
  final double height;
  final String className;
  final double confidence;
  final Map<String, double> classScores;

  YoloDetection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.className,
    required this.confidence,
    required this.classScores,
  });
}

class DiagnosisCombinedResult {
  final YoloDetectionResult yoloDetection;
  final DenseNetClassificationResult denseNetClassification;
  final double processingTime;

  DiagnosisCombinedResult({
    required this.yoloDetection,
    required this.denseNetClassification,
    required this.processingTime,
  });
}

class DenseNetClassificationResult {
  final String classification;
  final double confidence;
  final Map<String, double> classScores;

  DenseNetClassificationResult({
    required this.classification,
    required this.confidence,
    required this.classScores,
  });
}
