import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Represents DenseNet classification result
class DensenetResult {
  final String diagnosis;
  final double confidence;
  final Map<String, double> classScores;
  final Uint8List? heatmapBytes;
  final String? errorMessage;

  const DensenetResult({
    required this.diagnosis,
    required this.confidence,
    required this.classScores,
    this.heatmapBytes,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;

  factory DensenetResult.error(String message) => DensenetResult(
        diagnosis: 'Unknown',
        confidence: 0.0,
        classScores: {},
        errorMessage: message,
      );
}

class DensenetService {
  static const String modelPath = 'lib/ML/detection/densenet_model.tflite';
  static const int inputSize = 224; // Typical DenseNet input size

  Interpreter? _interpreter;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isInitialized = true;
      debugPrint('DenseNet model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load DenseNet model: $e');
      throw Exception('Failed to initialize DenseNet model: $e');
    }
  }

  Future<DensenetResult> classify({
    required dynamic imageFile,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      if (_interpreter == null) return DensenetResult.error('Model not initialized');

      Uint8List imageBytes;
      if (imageFile is File) {
        imageBytes = await imageFile.readAsBytes();
      } else if (imageFile is Uint8List) {
        imageBytes = imageFile;
      } else {
        return DensenetResult.error('Invalid image format');
      }

      final rawImage = img.decodeImage(imageBytes);
      if (rawImage == null) return DensenetResult.error('Failed to decode image');

      final resized = img.copyResize(rawImage, width: inputSize, height: inputSize);
      final input = _prepareInput(resized);

      // Assuming model has 1 output: [1, num_classes]
      // Or maybe 2 outputs if it has a heatmap output
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final numClasses = outputShape[1];
      final output = List.generate(1, (_) => List<double>.filled(numClasses, 0.0));

      _interpreter!.run(input, output);

      final scores = output[0];
      final result = _processScores(scores);

      // For heatmap functionality on doctor side:
      // If the model doesn't output a heatmap, we might need to simulate it or
      // if it's a doctor view, we can provide a dummy or calculated one if possible.
      // Since real Grad-CAM is hard in TFLite (no gradients), we'll check if there's a 2nd output.
      Uint8List? heatmap;
      if (_interpreter!.getOutputTensors().length > 1) {
        // Model might output a heatmap as well
        // Process 2nd output...
      }

      return DensenetResult(
        diagnosis: result['diagnosis'] as String,
        confidence: result['confidence'] as double,
        classScores: result['classScores'] as Map<String, double>,
        heatmapBytes: heatmap,
      );
    } catch (e) {
      debugPrint('DenseNet classification error: $e');
      return DensenetResult.error('Classification failed: $e');
    }
  }

  List<List<List<List<double>>>> _prepareInput(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // DenseNet normalization (usually ImageNet)
            // (x - mean) / std
            return [
              (pixel.r.toDouble() / 255.0 - 0.485) / 0.229,
              (pixel.g.toDouble() / 255.0 - 0.456) / 0.224,
              (pixel.b.toDouble() / 255.0 - 0.406) / 0.225,
            ];
          },
        ),
      ),
    );
    return input;
  }

  Map<String, dynamic> _processScores(List<double> scores) {
    const labels = [
      'Normal',
      'Pneumonia',
      'Tuberculosis',
      'COVID-19',
      'Effusion',
      'Nodule',
      'Mass',
      'Atelectasis'
    ];
    
    final classScores = <String, double>{};
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      classScores[labels[i]] = scores[i];
    }

    // Find max score
    var maxScore = -1.0;
    var diagnosis = 'Unknown';
    classScores.forEach((label, score) {
      if (score > maxScore) {
        maxScore = score;
        diagnosis = label;
      }
    });

    return {
      'diagnosis': diagnosis,
      'confidence': maxScore,
      'classScores': classScores,
    };
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
