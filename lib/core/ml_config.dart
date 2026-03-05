/// Machine Learning model configuration.
///
/// Centralizes all ML-related settings including model paths, thresholds,
/// input sizes, and inference parameters.
library;

/// ML-specific configuration for object detection and classification.
class MLConfig {
  /// YOLO detection model configuration.
  final YOLOConfig yolo;

  /// DenseNet classification model configuration.
  final DenseNetConfig densenet;

  /// Grad-CAM visualization configuration.
  final GradCAMConfig gradcam;

  /// General ML inference settings.
  final InferenceConfig inference;

  const MLConfig({
    required this.yolo,
    required this.densenet,
    required this.gradcam,
    required this.inference,
  });

  /// Development configuration with relaxed thresholds for testing.
  factory MLConfig.development() {
    return MLConfig(
      yolo: YOLOConfig.development(),
      densenet: DenseNetConfig.development(),
      gradcam: GradCAMConfig.development(),
      inference: InferenceConfig.development(),
    );
  }

  /// Staging configuration with production-like settings.
  factory MLConfig.staging() {
    return MLConfig(
      yolo: YOLOConfig.staging(),
      densenet: DenseNetConfig.staging(),
      gradcam: GradCAMConfig.staging(),
      inference: InferenceConfig.staging(),
    );
  }

  /// Production configuration with optimized settings.
  factory MLConfig.production() {
    return MLConfig(
      yolo: YOLOConfig.production(),
      densenet: DenseNetConfig.production(),
      gradcam: GradCAMConfig.production(),
      inference: InferenceConfig.production(),
    );
  }
}

/// YOLO detection model configuration.
class YOLOConfig {
  /// Path to the YOLO model file.
  final String modelPath;

  /// Input image width for YOLO model.
  final int inputWidth;

  /// Input image height for YOLO model.
  final int inputHeight;

  /// Confidence threshold for detections (0.0 to 1.0).
  final double confidenceThreshold;

  /// IoU (Intersection over Union) threshold for NMS.
  final double iouThreshold;

  /// Maximum number of detections to return.
  final int maxDetections;

  /// Number of classes the model can detect.
  final int numClasses;

  /// Class names for detected objects.
  final List<String> classNames;

  const YOLOConfig({
    required this.modelPath,
    required this.inputWidth,
    required this.inputHeight,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.maxDetections,
    required this.numClasses,
    required this.classNames,
  });

  factory YOLOConfig.development() {
    return const YOLOConfig(
      modelPath: 'assets/models/yolo_v8_int8.tflite',
      inputWidth: 640,
      inputHeight: 640,
      confidenceThreshold: 0.25, // Relaxed for testing
      iouThreshold: 0.45,
      maxDetections: 100,
      numClasses: 1,
      classNames: ['tumor'],
    );
  }

  factory YOLOConfig.staging() {
    return const YOLOConfig(
      modelPath: 'assets/models/yolo_v8_int8.tflite',
      inputWidth: 640,
      inputHeight: 640,
      confidenceThreshold: 0.35,
      iouThreshold: 0.45,
      maxDetections: 50,
      numClasses: 1,
      classNames: ['tumor'],
    );
  }

  factory YOLOConfig.production() {
    return const YOLOConfig(
      modelPath: 'assets/models/yolo_v8_int8.tflite',
      inputWidth: 640,
      inputHeight: 640,
      confidenceThreshold: 0.4, // Higher threshold for production
      iouThreshold: 0.45,
      maxDetections: 50,
      numClasses: 1,
      classNames: ['tumor'],
    );
  }
}

/// DenseNet classification model configuration.
class DenseNetConfig {
  /// Path to the DenseNet model file.
  final String modelPath;

  /// Input image width for DenseNet model.
  final int inputWidth;

  /// Input image height for DenseNet model.
  final int inputHeight;

  /// Number of classes for classification.
  final int numClasses;

  /// Class names in order.
  final List<String> classNames;

  /// Mean values for normalization [R, G, B].
  final List<double> meanValues;

  /// Standard deviation values for normalization [R, G, B].
  final List<double> stdValues;

  /// Minimum confidence threshold for classification.
  final double confidenceThreshold;

  const DenseNetConfig({
    required this.modelPath,
    required this.inputWidth,
    required this.inputHeight,
    required this.numClasses,
    required this.classNames,
    required this.meanValues,
    required this.stdValues,
    required this.confidenceThreshold,
  });

  factory DenseNetConfig.development() {
    return const DenseNetConfig(
      modelPath: 'assets/models/densenet_int8.tflite',
      inputWidth: 224,
      inputHeight: 224,
      numClasses: 4,
      classNames: [
        'adenocarcinoma',
        'large_cell_carcinoma',
        'normal',
        'squamous_cell_carcinoma',
      ],
      meanValues: [0.485, 0.456, 0.406],
      stdValues: [0.229, 0.224, 0.225],
      confidenceThreshold: 0.3, // Lower for development
    );
  }

  factory DenseNetConfig.staging() {
    return const DenseNetConfig(
      modelPath: 'assets/models/densenet_int8.tflite',
      inputWidth: 224,
      inputHeight: 224,
      numClasses: 4,
      classNames: [
        'adenocarcinoma',
        'large_cell_carcinoma',
        'normal',
        'squamous_cell_carcinoma',
      ],
      meanValues: [0.485, 0.456, 0.406],
      stdValues: [0.229, 0.224, 0.225],
      confidenceThreshold: 0.5,
    );
  }

  factory DenseNetConfig.production() {
    return const DenseNetConfig(
      modelPath: 'assets/models/densenet_int8.tflite',
      inputWidth: 224,
      inputHeight: 224,
      numClasses: 4,
      classNames: [
        'adenocarcinoma',
        'large_cell_carcinoma',
        'normal',
        'squamous_cell_carcinoma',
      ],
      meanValues: [0.485, 0.456, 0.406],
      stdValues: [0.229, 0.224, 0.225],
      confidenceThreshold: 0.6, // Higher confidence for production
    );
  }
}

/// Grad-CAM visualization configuration.
class GradCAMConfig {
  /// Enable Grad-CAM generation.
  final bool enabled;

  /// Target layer name for Grad-CAM.
  final String targetLayer;

  /// Heatmap opacity (0.0 to 1.0).
  final double opacity;

  /// Colormap for heatmap visualization.
  final GradCAMColormap colormap;

  /// Resolution for heatmap overlay.
  final int heatmapResolution;

  const GradCAMConfig({
    required this.enabled,
    required this.targetLayer,
    required this.opacity,
    required this.colormap,
    required this.heatmapResolution,
  });

  factory GradCAMConfig.development() {
    return const GradCAMConfig(
      enabled: true,
      targetLayer: 'conv5_block16_concat',
      opacity: 0.5,
      colormap: GradCAMColormap.jet,
      heatmapResolution: 224,
    );
  }

  factory GradCAMConfig.staging() {
    return const GradCAMConfig(
      enabled: true,
      targetLayer: 'conv5_block16_concat',
      opacity: 0.5,
      colormap: GradCAMColormap.jet,
      heatmapResolution: 224,
    );
  }

  factory GradCAMConfig.production() {
    return const GradCAMConfig(
      enabled: true,
      targetLayer: 'conv5_block16_concat',
      opacity: 0.5,
      colormap: GradCAMColormap.jet,
      heatmapResolution: 224,
    );
  }
}

/// Colormap options for Grad-CAM visualization.
enum GradCAMColormap {
  jet,
  viridis,
  plasma,
  inferno,
  magma,
}

/// General inference configuration.
class InferenceConfig {
  /// Number of threads for TFLite inference.
  final int numThreads;

  /// Enable GPU acceleration if available.
  final bool useGpuAcceleration;

  /// Enable NNAPI acceleration (Android).
  final bool useNnapi;

  /// Enable Metal acceleration (iOS).
  final bool useMetal;

  /// Batch size for batch inference.
  final int batchSize;

  /// Enable model caching.
  final bool enableModelCaching;

  /// Timeout for model initialization (in seconds).
  final int initializationTimeout;

  /// Timeout for inference (in seconds).
  final int inferenceTimeout;

  const InferenceConfig({
    required this.numThreads,
    required this.useGpuAcceleration,
    required this.useNnapi,
    required this.useMetal,
    required this.batchSize,
    required this.enableModelCaching,
    required this.initializationTimeout,
    required this.inferenceTimeout,
  });

  factory InferenceConfig.development() {
    return const InferenceConfig(
      numThreads: 4,
      useGpuAcceleration: false, // Disable for consistent debugging
      useNnapi: false,
      useMetal: false,
      batchSize: 1,
      enableModelCaching: true,
      initializationTimeout: 60,
      inferenceTimeout: 30,
    );
  }

  factory InferenceConfig.staging() {
    return const InferenceConfig(
      numThreads: 4,
      useGpuAcceleration: true,
      useNnapi: true,
      useMetal: true,
      batchSize: 1,
      enableModelCaching: true,
      initializationTimeout: 30,
      inferenceTimeout: 15,
    );
  }

  factory InferenceConfig.production() {
    return const InferenceConfig(
      numThreads: 4,
      useGpuAcceleration: true,
      useNnapi: true,
      useMetal: true,
      batchSize: 1,
      enableModelCaching: true,
      initializationTimeout: 30,
      inferenceTimeout: 10,
    );
  }
}

/// Helper extension for accessing ML config from ConfigService.
extension MLConfigExtension on MLConfig {
  /// Get YOLO model path.
  String get yoloModelPath => yolo.modelPath;

  /// Get DenseNet model path.
  String get densenetModelPath => densenet.modelPath;

  /// Get YOLO confidence threshold.
  double get yoloConfidence => yolo.confidenceThreshold;

  /// Get DenseNet confidence threshold.
  double get densenetConfidence => densenet.confidenceThreshold;
}
