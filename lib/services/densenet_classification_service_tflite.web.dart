import 'package:image/image.dart' as img;

class ClassificationResult {
  final String label;
  final double confidence;
  final Map<String, double> classScores;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.classScores,
  });

  @override
  String toString() => 'Classification($label: ${confidence.toStringAsFixed(3)})';
}

/// Web stub for DenseNet classification - FFI not available on web
class DenseNetClassificationServiceTFLite {
  static const String modelAsset = 'lib/ML/detection/densenet_model.tflite';
  static const int inputSize = 224;

  final Map<int, String> classLabels = {
    0: 'Adenocarcinoma (Class A)',
    1: 'Small Cell (Class B)',
    2: 'Large Cell (Class E)',
    3: 'Squamous Cell (Class G)',
  };

  DenseNetClassificationServiceTFLite();

  Future<void> initialize() async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform. '
      'DenseNet classification is only available on native platforms (Android, iOS, macOS, Linux, Windows).',
    );
  }

  Future<ClassificationResult> classify(img.Image image) async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  void dispose() {
    // No-op on web
  }
}
