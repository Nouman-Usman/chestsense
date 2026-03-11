import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'tflite_interpreter_service.dart';
import 'gradcam_service.dart';
import '../core/logger_service.dart';
import '../core/exceptions.dart';
import '../core/service_interfaces.dart';
import '../core/ml_config.dart';

/// DenseNet classification service using TFLite
/// Classifies tumor regions into 4 cancer types: Adenocarcinoma, Small Cell, Large Cell, Squamous Cell
class DenseNetClassificationServiceTFLite implements IClassificationService {
  final DenseNetConfig _config;
  late TFLiteInterpreter _interpreter;
  int _numClasses = 4;
  late GradCAMService _gradcamService;
  bool _initialized = false;

  DenseNetClassificationServiceTFLite({
    required DenseNetConfig config,
    TFLiteInterpreter? interpreter,
    GradCAMService? gradcamService,
  }) : _config = config {
    _interpreter = interpreter ?? TFLiteInterpreter(modelPath: config.modelPath);
    if (gradcamService != null) {
      _gradcamService = gradcamService;
    }
  }
  
  /// Get input size from configuration.
  int get inputSize => _config.inputWidth;
  
  /// Get class labels from configuration.
  Map<int, String> get classLabels => {
    for (int i = 0; i < _config.classNames.length; i++)
      i: _config.classNames[i],
  };
  
  @override
  bool get isInitialized => _initialized;

  /// Initialize service, load model, read actual output shape
  @override
  Future<void> initialize() async {
    try {
      await _interpreter.loadModel();
      final outShape = _interpreter.getOutputShape();
      // outShape is e.g. [1, 2] — last dim is num classes
      _numClasses = outShape.last;
      
      // Initialize Grad-CAM service
      _gradcamService = GradCAMService(_interpreter);
      await _gradcamService.initialize();
      
      LoggerService.ml('DenseNet initialized — classes: $_numClasses, output: $outShape');
      _initialized = true;
    } on ModelInitializationException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('Failed to initialize DenseNet', error: e, stackTrace: stackTrace);
      throw ModelInitializationException(
        'DenseNet model initialization failed',
        modelPath: _config.modelPath,
        cause: e,
        stackTrace: stackTrace,
      );
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
        input[idx++] = (pixel.r.toInt() / 255.0 - _config.meanValues[0]) / _config.stdValues[0];
        input[idx++] = (pixel.g.toInt() / 255.0 - _config.meanValues[1]) / _config.stdValues[1];
        input[idx++] = (pixel.b.toInt() / 255.0 - _config.meanValues[2]) / _config.stdValues[2];
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
  @override
  Future<ClassificationResult> classify(img.Image image, {bool generateGradCAM = false}) async {
    if (!_initialized) {
      throw ServiceNotInitializedException(
        'DenseNet service not initialized. Call initialize() first.',
        serviceName: 'DenseNetClassificationServiceTFLite',
      );
    }
    
    try {
      final flatInput = preprocessImage(image);
      final input4d  = _reshapeInput(flatInput);

      // Output: [1, numClasses]
      final output = [List<double>.filled(_numClasses, 0.0)];

      _interpreter.run(input4d, output);

      // Generate Grad-CAM if requested
      img.Image? gradcamHeatmap;
      if (generateGradCAM) {
        try {
          final result = _postProcess(output[0], gradcamHeatmap: null);
          final targetClassIndex = _getClassIndex(result.label);
          
          final gradcamResult = await _gradcamService.generateGradCAM(
            image,
            targetClassIndex,
            classLabels,
          );
          
          gradcamHeatmap = gradcamResult.heatmap;
        } on GradCAMException catch (e) {
          // Grad-CAM failure is recoverable - log and continue without heatmap
          LoggerService.warning('Grad-CAM generation failed, continuing without heatmap', context: {'error': e.toString()});
          gradcamHeatmap = null;
        } catch (e) {
          LoggerService.warning('Grad-CAM generation failed', context: {'error': e.toString()});
          gradcamHeatmap = null;
        }
      }

      return _postProcess(output[0], gradcamHeatmap: gradcamHeatmap);
    } on InferenceException {
      rethrow;
    } catch (e, stackTrace) {
      LoggerService.error('Classification failed', error: e, stackTrace: stackTrace);
      throw InferenceException(
        'DenseNet classification failed',
        modelName: 'DenseNet121',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get class index from label
  int _getClassIndex(String label) {
    for (var entry in classLabels.entries) {
      if (entry.value == label) {
        return entry.key;
      }
    }
    return 0; // Default to first class
  }

  /// Apply softmax and return result
  ClassificationResult _postProcess(List<double> logits, {img.Image? gradcamHeatmap}) {
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
    LoggerService.success('Classification: $label (${maxProb.toStringAsFixed(3)})');

    return ClassificationResult(
      label: label,
      confidence: maxProb,
      classScores: scores,
      gradcamHeatmap: gradcamHeatmap,
    );
  }

  /// Numerically stable softmax using dart:math exp
  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum  = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  @override
  void dispose() {
    _interpreter.close();
    _initialized = false;
    LoggerService.ml('DenseNet Classification Service disposed', isDebug: true);
  }
}
