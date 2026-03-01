import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'yolo_detection_service_tflite.dart';
import 'densenet_classification_service_tflite.dart';

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
  });
  
  /// Get bounding box as [x1, y1, x2, y2]
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

/// Unified on-device ML pipeline for tumor detection and classification
class MLPipelineServiceTFLite {
  late final YOLODetectionServiceTFLite _yoloService;
  late final DenseNetClassificationServiceTFLite _densenetService;
  
  bool _initialized = false;
  
  MLPipelineServiceTFLite() {
    _yoloService = YOLODetectionServiceTFLite();
    _densenetService = DenseNetClassificationServiceTFLite();
  }
  
  /// Initialize both models
  Future<void> initialize() async {
    try {
      print('🚀 Initializing ML Pipeline (TFLite)...');
      
      await Future.wait([
        _yoloService.initialize(),
        _densenetService.initialize(),
      ]);
      
      _initialized = true;
      print('✅ ML Pipeline initialized successfully');
    } catch (e) {
      print('❌ ML Pipeline initialization failed: $e');
      rethrow;
    }
  }
  
  /// Check if pipeline is ready
  bool get isInitialized => _initialized;
  
  /// Run complete analysis: Detection → Classification
  Future<TumorAnalysisResult> analyze(img.Image ctSlice) async {
    if (!_initialized) {
      throw StateError('ML Pipeline not initialized. Call initialize() first.');
    }
    
    try {
      final startTime = DateTime.now();
      
      print('📊 Starting complete tumor analysis...');
      
      // Step 1: Detect tumors
      print('📍 Step 1: Tumor detection with YOLO');
      final detections = await _yoloService.detect(ctSlice);
      
      if (detections.isEmpty) {
        print('⚠️  No tumors detected');
        return TumorAnalysisResult(
          totalDetected: 0,
          tumors: [],
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds.toDouble(),
        );
      }
      
      print('✅ Detection complete: ${detections.length} potential tumors');
      
      // Step 2: Classify each detected tumor
      print('🔬 Step 2: Classification of ${detections.length} detected regions');
      final tumors = <DetectedTumor>[];
      
      for (int i = 0; i < detections.length; i++) {
        final detection = detections[i];
        
        // Extract bounding box
        final bbox = detection.bbox;
        final x1 = bbox[0].toInt().clamp(0, ctSlice.width - 1);
        final y1 = bbox[1].toInt().clamp(0, ctSlice.height - 1);
        final x2 = bbox[2].toInt().clamp(0, ctSlice.width - 1);
        final y2 = bbox[3].toInt().clamp(0, ctSlice.height - 1);
        
        // Crop tumor region
        final croppedWidth = (x2 - x1).clamp(1, ctSlice.width);
        final croppedHeight = (y2 - y1).clamp(1, ctSlice.height);
        
        print('   • Tumor ${i + 1}/${detections.length}: cropping region...');
        
        final tumorRegion = img.copyCrop(
          ctSlice,
          x: x1.toInt(),
          y: y1.toInt(),
          width: croppedWidth.toInt(),
          height: croppedHeight.toInt(),
        );
        
        // Classify
        final classification = await _densenetService.classify(tumorRegion);
        
        tumors.add(DetectedTumor(
          index: i + 1,
          x: detection.x,
          y: detection.y,
          width: detection.width,
          height: detection.height,
          detectionConfidence: detection.confidence,
          classification: classification.label,
          classificationConfidence: classification.confidence,
          classScores: classification.classScores,
        ));
        
        print('     → ${classification.label} (${classification.confidence.toStringAsFixed(3)})');
      }
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds.toDouble();
      
      print('');
      print('═' * 60);
      print('✅ ANALYSIS COMPLETE');
      print('═' * 60);
      print('Total tumors: ${tumors.length}');
      print('Processing time: ${processingTime.toStringAsFixed(1)}ms');
      print('─' * 60);
      
      for (final tumor in tumors) {
        print('🔴 ${tumor.toString()}');
      }
      
      print('═' * 60);
      
      return TumorAnalysisResult(
        totalDetected: tumors.length,
        tumors: tumors,
        processingTimeMs: processingTime,
      );
    } catch (e) {
      print('❌ Analysis failed: $e');
      rethrow;
    }
  }
  
  /// Convenience: decode raw bytes then analyze
  Future<TumorAnalysisResult> analyzeImageBytes(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw ArgumentError('Could not decode image bytes');
    return analyze(decoded);
  }

  /// Dispose resources
  void dispose() {
    _yoloService.dispose();
    _densenetService.dispose();
    _initialized = false;
    print('🧹 ML Pipeline disposed');
  }
}
