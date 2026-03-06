import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:chestsense/core/service_interfaces.dart';

class TumorAnalysisResult {
  final int totalDetected;
  final List<DetectedTumor> tumors;
  final double processingTimeMs;
  
  TumorAnalysisResult({
    required this.totalDetected,
    required this.tumors,
    required this.processingTimeMs,
  });
  
  @override
  String toString() => 'Analysis: $totalDetected tumors detected in ${processingTimeMs.toStringAsFixed(1)}ms';
}

class DetectedTumor {
  final int index;
  final double x;
  final double y;
  final double width;
  final double height;
  final double detectionConfidence;
  final String classification;
  final double classificationConfidence;
  final Map<String, double> classScores;
  final img.Image? heatmapImage;
  final img.Image? originalRegion;
  
  DetectedTumor({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.detectionConfidence,
    required this.classification,
    required this.classificationConfidence,
    required this.classScores,
    this.heatmapImage,
    this.originalRegion,
  });
  
  List<double> get bbox => [
    x - width / 2,
    y - height / 2,
    x + width / 2,
    y + height / 2,
  ];
  
  @override
  String toString() => 
    'Tumor #$index: $classification (det: ${detectionConfidence.toStringAsFixed(3)}, cls: ${classificationConfidence.toStringAsFixed(3)})';
}

/// Web stub for ML Pipeline - FFI not available on web
class MLPipelineServiceTFLite {
  bool _initialized = false;

  MLPipelineServiceTFLite({
    required IDetectionService detectionService,
    required IClassificationService classificationService,
  });

  Future<void> initialize() async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform. '
      'ML inference features are only available on native platforms (Android, iOS, macOS, Linux, Windows).',
    );
  }

  bool get isInitialized => _initialized;

  Future<TumorAnalysisResult> analyze(img.Image ctSlice) async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  Future<TumorAnalysisResult> analyzeImageBytes(Uint8List bytes) async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  void dispose() {
    _initialized = false;
  }
}
