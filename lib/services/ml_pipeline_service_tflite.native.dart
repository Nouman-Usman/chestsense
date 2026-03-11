import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../core/logger_service.dart';
import '../core/exceptions.dart';
import '../core/service_interfaces.dart';
import 'heatmap_generation_service.dart';

/// Unified on-device ML pipeline for tumor detection and classification
class MLPipelineServiceTFLite implements IMLPipelineService {
  final IDetectionService _yoloService;
  final IClassificationService _densenetService;
  
  bool _initialized = false;
  
  /// Constructor with dependency injection.
  /// 
  /// [detectionService] - YOLO detection service
  /// [classificationService] - DenseNet classification service
  MLPipelineServiceTFLite({
    required IDetectionService detectionService,
    required IClassificationService classificationService,
  }) : _yoloService = detectionService,
       _densenetService = classificationService;
  
  /// Initialize both models
  @override
  Future<void> initialize() async {
    try {
      LoggerService.ml('Initializing ML Pipeline (TFLite)...');
      
      await Future.wait([
        _yoloService.initialize(),
        _densenetService.initialize(),
      ]);
      
      _initialized = true;
      LoggerService.success('ML Pipeline initialized successfully');
    } on ModelInitializationException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('ML Pipeline initialization failed', error: e, stackTrace: stackTrace);
      throw ModelInitializationException(
        'ML Pipeline initialization failed',
        modelPath: 'multiple',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Check if pipeline is ready
  @override
  bool get isInitialized => _initialized;
  
  /// Run complete analysis: Detection → Classification
  @override
  Future<TumorAnalysisResult> analyze(img.Image ctSlice) async {
    if (!_initialized) {
      throw ServiceNotInitializedException(
        'ML Pipeline not initialized. Call initialize() first.',
        serviceName: 'MLPipelineService',
      );
    }
    
    try {
      final startTime = DateTime.now();
      
      LoggerService.ml('Starting complete tumor analysis...');
      
      // Step 1: Detect tumors
      LoggerService.ml('Step 1: Tumor detection with YOLO');
      final detections = await _yoloService.detect(ctSlice);
      
      if (detections.isEmpty) {
        LoggerService.warning('No tumors detected');
        return TumorAnalysisResult(
          totalDetected: 0,
          tumors: [],
          processingTimeMs: DateTime.now().difference(startTime).inMilliseconds.toDouble(),
        );
      }
      
      LoggerService.success('Detection complete: ${detections.length} potential tumors');
      
      // Step 2: Classify each detected tumor
      LoggerService.ml('Step 2: Classification of ${detections.length} detected regions');
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
        
        LoggerService.ml('Tumor ${i + 1}/${detections.length}: cropping region...', isDebug: true);
        
        final tumorRegion = img.copyCrop(
          ctSlice,
          x: x1.toInt(),
          y: y1.toInt(),
          width: croppedWidth.toInt(),
          height: croppedHeight.toInt(),
        );
        
        // Resize to standard size for classification
        final resizedRegion = img.copyResize(
          tumorRegion,
          width: 224,
          height: 224,
        );
        
        // Classify with Grad-CAM heatmap generation
        final classification = await _densenetService.classify(
          resizedRegion,
          generateGradCAM: true,
        );
        
        // Use Grad-CAM heatmap if available, otherwise fall back to saliency
        img.Image? blendedHeatmap;
        if (classification.gradcamHeatmap != null) {
          LoggerService.ml('Using Grad-CAM heatmap for ${classification.label}...', isDebug: true);
          blendedHeatmap = HeatmapGenerationService.blendHeatmapWithImage(
            resizedRegion,
            classification.gradcamHeatmap!,
            alpha: 0.6,
          );
        } else {
          LoggerService.ml('Generating fallback saliency heatmap for ${classification.label}...', isDebug: true);
          final heatmap = HeatmapGenerationService.generateGradCAMHeatmap(
            resizedRegion,
            classification.classScores,
            targetClass: classification.label,
          );
          blendedHeatmap = HeatmapGenerationService.blendHeatmapWithImage(
            resizedRegion,
            heatmap,
            alpha: 0.6,
          );
        }
        
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
          heatmapImage: blendedHeatmap,
          originalRegion: resizedRegion,
        ));
        
        LoggerService.ml('${classification.label} (${classification.confidence.toStringAsFixed(3)})', isDebug: true);
      }
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds.toDouble();
      
      LoggerService.success('ANALYSIS COMPLETE - Total tumors: ${tumors.length}, Processing time: ${processingTime.toStringAsFixed(1)}ms');
      
      for (final tumor in tumors) {
        LoggerService.ml(tumor.toString(), isDebug: true);
      }
      
      return TumorAnalysisResult(
        totalDetected: tumors.length,
        tumors: tumors,
        processingTimeMs: processingTime,
      );
    } on InferenceException {
      rethrow;
    } on ImageProcessingException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('Analysis failed', error: e, stackTrace: stackTrace);
      throw InferenceException(
        'Tumor analysis pipeline failed',
        modelName: 'ML Pipeline',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Convenience: decode raw bytes then analyze
  @override
  Future<TumorAnalysisResult> analyzeImageBytes(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw ArgumentError('Could not decode image bytes');
    return analyze(decoded);
  }

  /// Dispose resources
  @override
  void dispose() {
    _yoloService.dispose();
    _densenetService.dispose();
    _initialized = false;
    LoggerService.ml('ML Pipeline disposed', isDebug: true);
  }
}
