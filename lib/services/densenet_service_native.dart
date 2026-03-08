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

  DensenetResult copyWith({
    String? diagnosis,
    double? confidence,
    Map<String, double>? classScores,
    Uint8List? heatmapBytes,
    String? errorMessage,
  }) {
    return DensenetResult(
      diagnosis: diagnosis ?? this.diagnosis,
      confidence: confidence ?? this.confidence,
      classScores: classScores ?? this.classScores,
      heatmapBytes: heatmapBytes ?? this.heatmapBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

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

      final rawImage = imageFile is img.Image ? imageFile : img.decodeImage(imageBytes);
      if (rawImage == null) return DensenetResult.error('Failed to decode image');

      final resized = img.copyResize(rawImage, width: inputSize, height: inputSize);
      final input = _prepareInput(resized);

      // Assuming model has 1 output: [1, 4] (new model classes)
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final numClasses = outputShape[1];
      final output =
          List.generate(1, (_) => List<double>.filled(numClasses, 0.0));

      _interpreter!.run(input, output);

      // Process scores
      final scores = output[0];
      final result = _processScores(scores);

      return DensenetResult(
        diagnosis: result['diagnosis'] as String,
        confidence: result['confidence'] as double,
        classScores: result['classScores'] as Map<String, double>,
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
      'Adenocarcinoma (Class A)',
      'Small Cell (Class B)',
      'Large Cell (Class E)',
      'Squamous Cell (Class G)'
    ];
    
    final classScores = <String, double>{};
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      classScores[labels[i]] = scores[i];
    }

    // Find max score
    var maxScore = -1.0;
    var diagnosis = 'Normal / Unclassified';
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
