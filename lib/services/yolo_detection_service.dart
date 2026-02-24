import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Represents a single detection from YOLO model
class YoloDetection {
  final double x;
  final double y;
  final double width;
  final double height;
  final String className;
  final double confidence;
  final List<double> classScores;

  YoloDetection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.className,
    required this.confidence,
    required this.classScores,
  });

  /// Convert to map for serialization
  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'className': className,
    'confidence': confidence,
    'classScores': classScores,
  };

  /// Get bounding box corners
  Map<String, double> getBounds() => {
    'left': (x - width / 2).clamp(0, double.infinity),
    'top': (y - height / 2).clamp(0, double.infinity),
    'right': (x + width / 2),
    'bottom': (y + height / 2),
  };
}

/// Represents full YOLO detection result for an image
class YoloDetectionResult {
  final List<YoloDetection> detections;
  final String anomalySeverity; // 'critical', 'moderate', 'mild', 'normal'
  final double anomalyScore; // 0.0 to 1.0
  final String primaryAnomaly; // Most prominent detection
  final int frameWidth;
  final int frameHeight;
  final int processingTimeMs;
  final String? errorMessage;

  const YoloDetectionResult({
    required this.detections,
    required this.anomalySeverity,
    required this.anomalyScore,
    required this.primaryAnomaly,
    required this.frameWidth,
    required this.frameHeight,
    required this.processingTimeMs,
    this.errorMessage,
  });

  /// Get sorted detections by confidence
  List<YoloDetection> getSortedByConfidence() {
    final sorted = List<YoloDetection>.from(detections);
    sorted.sort((a, b) => b.confidence.compareTo(a.confidence));
    return sorted;
  }

  /// Check if result indicates anomaly
  bool get hasAnomalies => detections.isNotEmpty && anomalyScore > 0.3;

  /// Get human-readable severity description
  String getSeverityDescription() {
    switch (anomalySeverity) {
      case 'critical':
        return 'Critical - Immediate attention required';
      case 'moderate':
        return 'Moderate - Requires follow-up';
      case 'mild':
        return 'Mild - Monitor condition';
      case 'normal':
        return 'Normal - No significant findings';
      default:
        return 'Unknown severity';
    }
  }

  /// Serialize to map
  Map<String, dynamic> toMap() => {
    'detections': detections.map((d) => d.toMap()).toList(),
    'anomalySeverity': anomalySeverity,
    'anomalyScore': anomalyScore,
    'primaryAnomaly': primaryAnomaly,
    'frameWidth': frameWidth,
    'frameHeight': frameHeight,
    'processingTimeMs': processingTimeMs,
    'hasAnomalies': hasAnomalies,
  };

  /// Error result
  factory YoloDetectionResult.error(String message) => YoloDetectionResult(
    detections: [],
    anomalySeverity: 'unknown',
    anomalyScore: 0.0,
    primaryAnomaly: 'unknown',
    frameWidth: 0,
    frameHeight: 0,
    processingTimeMs: 0,
    errorMessage: message,
  );

  bool get isSuccess => errorMessage == null;
}

/// YOLO Detection Service using TensorFlow Lite
class YoloDetectionService {
  static const String modelPath = 'assets/ml/yolo/best.tflite';
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize YOLO model
  /// Note: Model should be converted from PyTorch .pt to .tflite format
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Load TensorFlow Lite interpreter
      // Note: You need to convert your best.pt to .tflite format first
      // Use: python -m tf2onnx.convert --saved-model path_to_saved_model --output-file best.onnx
      // Then use ONNX to TFLite converter
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isInitialized = true;
      debugPrint('YOLO model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load YOLO model: $e');
      throw Exception('Failed to initialize YOLO model: $e');
    }
  }

  /// Detect objects in image
  Future<YoloDetectionResult> detectObjects({
    required dynamic imageFile, // File on mobile, Uint8List on web
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final startTime = DateTime.now();

    try {
      if (_interpreter == null) {
        return YoloDetectionResult.error('YOLO model not initialized');
      }

      // Convert image to bytes
      Uint8List imageBytes;
      if (imageFile is File) {
        imageBytes = await imageFile.readAsBytes();
      } else if (imageFile is Uint8List) {
        imageBytes = imageFile;
      } else {
        return YoloDetectionResult.error('Invalid image format');
      }

      // Decode image
      final rawImage = img.decodeImage(imageBytes);
      if (rawImage == null) {
        return YoloDetectionResult.error('Failed to decode image');
      }

      // Preprocess: resize to model input size
      final resized = img.copyResize(
        rawImage,
        width: inputSize,
        height: inputSize,
        maintainAspect: false,
      );

      // Prepare input buffer
      final input = _prepareInput(resized);

      // Run inference
      final output = List.generate(1, (_) => List<double>.filled(25200, 0.0));
      _interpreter!.run(input, output);

      // Process outputs
      final detections = _processOutput(
        output[0],
        imageWidth.toDouble(),
        imageHeight.toDouble(),
      );

      // Calculate anomaly severity
      final severityResult = _calculateSeverity(detections);

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      return YoloDetectionResult(
        detections: detections,
        anomalySeverity: severityResult['severity'] as String,
        anomalyScore: severityResult['score'] as double,
        primaryAnomaly: severityResult['primary'] as String,
        frameWidth: imageWidth,
        frameHeight: imageHeight,
        processingTimeMs: processingTime,
      );
    } catch (e) {
      debugPrint('Detection error: $e');
      return YoloDetectionResult.error('Detection failed: $e');
    }
  }

  /// Prepare input tensor for model
  List<List<List<List<double>>>> _prepareInput(img.Image image) {
    // Convert to batch of normalized float32 values
    final input = List<List<List<List<double>>>>.generate(
      1,
      (_) => List<List<List<double>>>.generate(
        inputSize,
        (y) => List<List<double>>.generate(
          inputSize,
          (x) => List<double>.filled(3, 0.0),
        ),
      ),
    );

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixelSafe(x, y);
        // Normalize RGB values to 0-1 range
        input[0][y][x][0] = pixel.r.toDouble() / 255.0;
        input[0][y][x][1] = pixel.g.toDouble() / 255.0;
        input[0][y][x][2] = pixel.b.toDouble() / 255.0;
      }
    }

    return input;
  }

  /// Process model output to get detections
  List<YoloDetection> _processOutput(
    List<double> output,
    double imageWidth,
    double imageHeight,
  ) {
    final detections = <YoloDetection>[];
    const stride = 5; // 4 coordinates + 1 class

    for (var i = 0; i < output.length; i += stride) {
      final confidence = output[i + 4];

      if (confidence < confidenceThreshold) continue;

      // Get class scores (assuming binary classification for demo)
      final classScores = [output[i + 4]]; // In real YOLO, there would be multiple class scores

      // Scale coordinates from 640x640 to actual image size
      final centerX = (output[i] / inputSize) * imageWidth;
      final centerY = (output[i + 1] / inputSize) * imageHeight;
      final width = (output[i + 2] / inputSize) * imageWidth;
      final height = (output[i + 3] / inputSize) * imageHeight;

      detections.add(
        YoloDetection(
          x: centerX,
          y: centerY,
          width: width,
          height: height,
          className: _getClassName(classScores),
          confidence: confidence,
          classScores: classScores,
        ),
      );
    }

    // Apply NMS (Non-Maximum Suppression)
    return _applyNMS(detections);
  }

  /// Apply Non-Maximum Suppression
  List<YoloDetection> _applyNMS(List<YoloDetection> detections) {
    final sorted = List<YoloDetection>.from(detections);
    sorted.sort((a, b) => b.confidence.compareTo(a.confidence));

    final filtered = <YoloDetection>[];

    for (final detection in sorted) {
      bool isSupressed = false;

      for (final existing in filtered) {
        final iou = _calculateIOU(detection, existing);
        if (iou > iouThreshold) {
          isSupressed = true;
          break;
        }
      }

      if (!isSupressed) {
        filtered.add(detection);
      }
    }

    return filtered;
  }

  /// Calculate Intersection over Union
  double _calculateIOU(YoloDetection box1, YoloDetection box2) {
    final box1Bounds = box1.getBounds();
    final box2Bounds = box2.getBounds();

    final left = (box1Bounds['left']! < box2Bounds['left']!)
        ? box1Bounds['left']!
        : box2Bounds['left']!;
    final top = (box1Bounds['top']! < box2Bounds['top']!)
        ? box1Bounds['top']!
        : box2Bounds['top']!;
    final right = (box1Bounds['right']! > box2Bounds['right']!)
        ? box1Bounds['right']!
        : box2Bounds['right']!;
    final bottom = (box1Bounds['bottom']! > box2Bounds['bottom']!)
        ? box1Bounds['bottom']!
        : box2Bounds['bottom']!;

    if (left >= right || top >= bottom) return 0;

    final intersection = (right - left) * (bottom - top);
    final union =
        (box1.width * box1.height) + (box2.width * box2.height) - intersection;

    return intersection / union;
  }

  /// Get class name from scores
  String _getClassName(List<double> classScores) {
    if (classScores.isEmpty) return 'unknown';
    final maxIndex = classScores.indexOf(classScores.reduce((a, b) => a > b ? a : b));
    
    // Customize class names based on your YOLO model
    const classNames = ['pneumonia', 'fracture', 'nodule', 'infiltrate'];
    
    return maxIndex < classNames.length ? classNames[maxIndex] : 'unknown';
  }

  /// Calculate anomaly severity based on detections
  Map<String, dynamic> _calculateSeverity(List<YoloDetection> detections) {
    if (detections.isEmpty) {
      return {
        'severity': 'normal',
        'score': 0.0,
        'primary': 'none',
      };
    }

    // Sort by confidence
    final sorted = List<YoloDetection>.from(detections);
    sorted.sort((a, b) => b.confidence.compareTo(a.confidence));

    final maxConfidence = sorted.first.confidence;
    final primary = sorted.first.className;

    // Calculate severity based on confidence score and number of detections
    final detectionCount = detections.length;
    final severityScore = (maxConfidence + (detectionCount * 0.1)).clamp(0.0, 1.0);

    String severity;
    if (severityScore > 0.8) {
      severity = 'critical';
    } else if (severityScore > 0.6) {
      severity = 'moderate';
    } else if (severityScore > 0.3) {
      severity = 'mild';
    } else {
      severity = 'normal';
    }

    return {
      'severity': severity,
      'score': severityScore,
      'primary': primary,
    };
  }

  /// Release model resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
