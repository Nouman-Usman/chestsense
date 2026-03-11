import 'package:image/image.dart' as img;
import 'package:chestsense/core/ml_config.dart';

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

/// Web stub for YOLO detection - FFI not available on web
class YOLODetectionServiceTFLite {
  static const String modelAsset = 'lib/ML/yolo/best_float16.tflite';
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.3;
  static const double iouThreshold = 0.5;

  YOLODetectionServiceTFLite({required YOLOConfig config});

  Future<void> initialize() async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform. '
      'YOLO detection is only available on native platforms (Android, iOS, macOS, Linux, Windows).',
    );
  }

  Future<List<YOLODetectionResult>> detect(img.Image image) async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  void dispose() {
    // No-op on web
  }
}
