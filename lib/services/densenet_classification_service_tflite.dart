import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'tflite_interpreter_service.dart';

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

/// DenseNet classification service using TFLite
/// Classifies tumor regions as benign or malignant
class DenseNetClassificationServiceTFLite {
  static const String modelAsset = 'assets/models/densenet_final.tflite';
  static const int inputSize = 224;

  // ImageNet normalization constants
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std  = [0.229, 0.224, 0.225];

  late TFLiteInterpreter _interpreter;
  int _numClasses = 2;

  final Map<int, String> classLabels = {
    0: 'Benign',
    1: 'Malignant',
  };

  DenseNetClassificationServiceTFLite() {
    _interpreter = TFLiteInterpreter(modelPath: modelAsset);
  }

  /// Initialize service, load model, read actual output shape
  Future<void> initialize() async {
    try {
      await _interpreter.loadModel();
      final outShape = _interpreter.getOutputShape();
      // outShape is e.g. [1, 2] — last dim is num classes
      _numClasses = outShape.last;
      print('🔬 DenseNet initialized — classes: $_numClasses, output: $outShape');
    } catch (e) {
      print('❌ Failed to initialize DenseNet: $e');
      rethrow;
    }
  }

  /// Preprocess: resize → [0,1] → ImageNet normalize → NHWC Float32List [1,224,224,3]
  Float32List preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    final input = Float32List(1 * inputSize * inputSize * 3);
    int idx = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixelSafe(x, y);
        // [0,255] → [0,1] → ImageNet normalize
        input[idx++] = (pixel.r.toInt() / 255.0 - _mean[0]) / _std[0];
        input[idx++] = (pixel.g.toInt() / 255.0 - _mean[1]) / _std[1];
        input[idx++] = (pixel.b.toInt() / 255.0 - _mean[2]) / _std[2];
      }
    }

    return input;
  }

  /// Reshape flat Float32List into [1][H][W][C] nested list for tflite_flutter
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
    return [outer]; // shape [1, 224, 224, 3]
  }

  /// Classify image (tumor region)
  Future<ClassificationResult> classify(img.Image image) async {
    try {
      final flatInput = preprocessImage(image);
      final input4d  = _reshapeInput(flatInput);

      // Output: [1, numClasses]
      final output = [List<double>.filled(_numClasses, 0.0)];

      _interpreter.run(input4d, output);

      return _postProcess(output[0]);
    } catch (e) {
      print('❌ Classification failed: $e');
      rethrow;
    }
  }

  /// Apply softmax and return result
  ClassificationResult _postProcess(List<double> logits) {
    final probs = _softmax(logits);

    int maxIdx = 0;
    double maxProb = 0.0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    final scores = <String, double>{};
    for (int i = 0; i < probs.length; i++) {
      scores[classLabels[i] ?? 'Class$i'] = probs[i];
    }

    final label = classLabels[maxIdx] ?? 'Class$maxIdx';
    print('✅ Classification: $label (${maxProb.toStringAsFixed(3)})');

    return ClassificationResult(
      label: label,
      confidence: maxProb,
      classScores: scores,
    );
  }

  /// Numerically stable softmax using dart:math exp
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum  = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void dispose() {
    _interpreter.close();
    print('🧹 DenseNet Classification Service disposed');
  }
}
