import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'tflite_interpreter_service.dart';
import '../core/logger_service.dart';
import '../core/exceptions.dart';
import '../core/service_interfaces.dart';
import '../core/ml_config.dart';

class YOLODetectionResult {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final int classId;
  
  YOLODetectionResult({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.classId,
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
      'YOLODetection(box: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)}), conf: ${confidence.toStringAsFixed(3)})';
}

/// YOLOv8 object detection service using TFLite
class YOLODetectionServiceTFLite implements IDetectionService {
  final YOLOConfig _config;
  late TFLiteInterpreter _interpreter;

  // Set after loadModel — actual shape from the model file
  late List<int> _outputShape;   // e.g. [1, 84, 8400] or [1, 25200, 85]
  bool _isYolov8Format = false;  // true → [1, cols, anchors]; false → [1, anchors, cols]
  bool _initialized = false;

  YOLODetectionServiceTFLite({
    required YOLOConfig config,
    TFLiteInterpreter? interpreter,
  }) : _config = config {
    _interpreter = interpreter ?? TFLiteInterpreter(modelPath: config.modelPath);
  }
  
  /// Get input size from configuration.
  int get inputSize => _config.inputWidth;
  
  /// Get confidence threshold from configuration.
  double get confidenceThreshold => _config.confidenceThreshold;
  
  /// Get IoU threshold from configuration.
  double get iouThreshold => _config.iouThreshold;
  
  @override
  bool get isInitialized => _initialized;

  /// Initialize service, load model, detect output layout
  @override
  Future<void> initialize() async {
    try {
      await _interpreter.loadModel();
      _outputShape = _interpreter.getOutputShape();
      // YOLOv8 TFLite exports as [1, (4+classes), num_anchors]
      // YOLOv5 TFLite exports as [1, num_anchors, (5+classes)]
      // Distinguish by which dim is larger: anchors >> classes
      // typical anchors: 8400 (640px) or 25200; typical cols: 5-85
      final d1 = _outputShape[1]; // second dim
      final d2 = _outputShape[2]; // third  dim
      _isYolov8Format = d2 > d1;  // e.g. 8400 > 84 → YOLOv8
      LoggerService.ml('YOLO initialized — output: $_outputShape, '
            'format: ${_isYolov8Format ? "YOLOv8 [1,cols,anchors]" : "YOLOv5 [1,anchors,cols]"}');
      _initialized = true;
    } on ModelInitializationException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize YOLO', error: e, stackTrace: stackTrace);
      throw ModelInitializationException(
        'YOLO model initialization failed',
        modelPath: _config.modelPath,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Preprocess: resize to 640×640, normalize [0,1], return NHWC Float32List
  Float32List preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final input = Float32List(1 * inputSize * inputSize * 3);
    int i = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final px = resized.getPixelSafe(x, y);
        input[i++] = px.r.toInt() / 255.0;
        input[i++] = px.g.toInt() / 255.0;
        input[i++] = px.b.toInt() / 255.0;
      }
    }
    return input;
  }

  /// Reshape flat Float32List into [1][H][W][C] nested list
  List _reshapeInput(Float32List flat) {
    final outer = <List>[];
    for (int y = 0; y < inputSize; y++) {
      final row = <List>[];
      for (int x = 0; x < inputSize; x++) {
        final base = (y * inputSize + x) * 3;
        row.add([flat[base], flat[base + 1], flat[base + 2]]);
      }
      outer.add(row);
    }
    return [outer]; // [1, 640, 640, 3]
  }

  /// Run detection on image
  @override
  Future<List<DetectionResult>> detect(img.Image image) async {
    if (!_initialized) {
      throw ServiceNotInitializedException(
        'YOLO service not initialized. Call initialize() first.',
        serviceName: 'YOLODetectionServiceTFLite',
      );
    }
    
    try {
      LoggerService.ml('Running YOLO detection...', isDebug: true);

      final flatInput = preprocessImage(image);
      final input4d   = _reshapeInput(flatInput);

      // Allocate output matching the real model shape exactly
      final d1 = _outputShape[1];
      final d2 = _outputShape[2];
      final output = [
        List.generate(d1, (_) => List<double>.filled(d2, 0.0))
      ];

      _interpreter.run(input4d, output);

      final legacyResults = _postProcess(output[0], image.width, image.height);
      LoggerService.success('Detected ${legacyResults.length} objects');
      
      // Convert to interface type
      return legacyResults.map((r) => DetectionResult(
        x: r.x,
        y: r.y,
        width: r.width,
        height: r.height,
        confidence: r.confidence,
        classId: r.classId,
      )).toList();
    } on InferenceException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('Detection failed', error: e, stackTrace: stackTrace);
      throw InferenceException(
        'YOLO detection failed',
        modelName: 'YOLOv8',
        cause: e,
        stackTrace: stackTrace,
        context: {'imageWidth': image.width, 'imageHeight': image.height},
      );
    }
  }


  /// Post-process YOLO output — handles both YOLOv8 [cols,anchors] and YOLOv5 [anchors,cols]
  List<YOLODetectionResult> _postProcess(
    List<List<double>> raw,
    int originalWidth,
    int originalHeight,
  ) {
    final detections = <YOLODetectionResult>[];
    final scaleX = originalWidth  / inputSize;
    final scaleY = originalHeight / inputSize;

    if (_isYolov8Format) {
      // raw shape: [cols, num_anchors] → e.g. [84, 8400]
      // cols 0-3 = cx,cy,w,h; cols 4+ = class scores (no objectness)
      final numAnchors = raw[0].length;
      final numCols    = raw.length;
      final numClasses = numCols - 4;

      for (int a = 0; a < numAnchors; a++) {
        double maxClassScore = 0.0;
        int classId = 0;
        for (int c = 0; c < numClasses; c++) {
          final s = raw[4 + c][a];
          if (s > maxClassScore) { maxClassScore = s; classId = c; }
        }
        if (maxClassScore < confidenceThreshold) continue;

        final cx = raw[0][a];
        final cy = raw[1][a];
        final w  = raw[2][a];
        final h  = raw[3][a];

        detections.add(YOLODetectionResult(
          x: cx * scaleX, y: cy * scaleY,
          width: w * scaleX, height: h * scaleY,
          confidence: maxClassScore, classId: classId,
        ));
      }
    } else {
      // raw shape: [num_anchors, cols] → e.g. [25200, 85]
      // cols: cx, cy, w, h, objectness, class_0 … class_nc
      for (final row in raw) {
        if (row.length < 5) continue;
        final objectness = row[4];
        if (objectness < confidenceThreshold) continue;

        double maxClassProb = 0.0;
        int classId = 0;
        for (int c = 5; c < row.length; c++) {
          if (row[c] > maxClassProb) { maxClassProb = row[c]; classId = c - 5; }
        }
        final confidence = objectness * maxClassProb;
        if (confidence < confidenceThreshold) continue;

        detections.add(YOLODetectionResult(
          x: row[0] * scaleX, y: row[1] * scaleY,
          width: row[2] * scaleX, height: row[3] * scaleY,
          confidence: confidence, classId: classId,
        ));
      }
    }

    return _applyNMS(detections);
  }


  /// Non-Maximum Suppression to remove overlapping detections
  List<YOLODetectionResult> _applyNMS(List<YOLODetectionResult> detections) {
    if (detections.isEmpty) return [];
    
    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    List<YOLODetectionResult> result = [];
    
    for (final detection in detections) {
      bool shouldAdd = true;
      
      for (final kept in result) {
        final iou = _calculateIOU(detection, kept);
        if (iou > iouThreshold) {
          shouldAdd = false;
          break;
        }
      }
      
      if (shouldAdd) {
        result.add(detection);
      }
    }
    
    return result;
  }
  
  /// Calculate Intersection over Union (IoU) between two detections
  double _calculateIOU(YOLODetectionResult a, YOLODetectionResult b) {
    final bboxA = a.bbox;
    final bboxB = b.bbox;
    
    // Calculate intersection
    final x1 = (bboxA[0] > bboxB[0]) ? bboxA[0] : bboxB[0];
    final y1 = (bboxA[1] > bboxB[1]) ? bboxA[1] : bboxB[1];
    final x2 = (bboxA[2] < bboxB[2]) ? bboxA[2] : bboxB[2];
    final y2 = (bboxA[3] < bboxB[3]) ? bboxA[3] : bboxB[3];
    
    final interArea = (x2 - x1) * (y2 - y1);
    if (interArea <= 0) return 0.0;
    
    // Calculate union
    final areaA = (bboxA[2] - bboxA[0]) * (bboxA[3] - bboxA[1]);
    final areaB = (bboxB[2] - bboxB[0]) * (bboxB[3] - bboxB[1]);
    final unionArea = areaA + areaB - interArea;
    
    return interArea / unionArea;
  }
  
  /// Close model and free resources
  @override
  void dispose() {
    _interpreter.close();
    _initialized = false;
    LoggerService.ml('YOLO Detection Service disposed', isDebug: true);
  }
}
