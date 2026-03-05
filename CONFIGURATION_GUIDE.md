# Configuration Management Guide

## Overview

The ChestSense application uses a centralized configuration management system that provides environment-specific settings, ML model parameters, and feature flags. This guide explains how to use and extend the configuration system.

## Architecture

### Configuration Hierarchy

```
AppConfig (Root)
├── Environment (dev/staging/prod)
├── MLConfig (Machine Learning)
│   ├── YOLOConfig (Detection)
│   ├── DenseNetConfig (Classification)
│   ├── GradCAMConfig (Visualization)
│   └── InferenceConfig (General)
├── FirebaseConfig
├── ApiConfig
└── FeatureFlags
```

### Key Components

1. **ConfigService** - Singleton service for accessing configuration
2. **AppConfig** - Main configuration container
3. **MLConfig** - ML-specific configuration
4. **Environment** - Environment enum (development/staging/production)

## Usage

### Initialization

Configuration must be initialized before any services are registered:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize configuration (defaults to debug mode environment)
  ConfigService.initialize();
  
  // Or specify environment explicitly
  ConfigService.initialize(environment: Environment.production);
  
  // Register services (they will use ConfigService internally)
  registerServices();
  await initializeServices();
  
  runApp(MyApp());
}
```

### Accessing Configuration

```dart
// Get configuration service instance
final config = ConfigService.instance;

// Access environment
if (config.environment.isDevelopment) {
  print('Running in development mode');
}

// Access ML configuration
final yoloPath = config.ml.yolo.modelPath;
final confidenceThreshold = config.ml.yolo.confidenceThreshold;

// Access feature flags
if (config.features.enableGradCAM) {
  // Generate Grad-CAM visualization
}

// Access API configuration
final apiUrl = config.api.baseUrl;
final timeout = config.api.timeout;
```

## Environment-Specific Settings

### Development Environment

- **YOLO Confidence**: 0.25 (relaxed for testing)
- **DenseNet Confidence**: 0.3
- **Debug Logging**: Enabled
- **Performance Monitoring**: Enabled
- **Analytics**: Disabled
- **Experimental Features**: Enabled

### Staging Environment

- **YOLO Confidence**: 0.35
- **DenseNet Confidence**: 0.5
- **Debug Logging**: Enabled
- **Performance Monitoring**: Enabled
- **Analytics**: Enabled
- **Experimental Features**: Enabled

### Production Environment

- **YOLO Confidence**: 0.4 (higher for accuracy)
- **DenseNet Confidence**: 0.6
- **Debug Logging**: Disabled
- **Performance Monitoring**: Enabled
- **Analytics**: Enabled
- **Experimental Features**: Disabled

## ML Configuration

### YOLO Detection Configuration

```dart
class YOLOConfig {
  final String modelPath;              // Model file path
  final int inputWidth;                // Input image width (640)
  final int inputHeight;               // Input image height (640)
  final double confidenceThreshold;    // Detection threshold (0.0-1.0)
  final double iouThreshold;           // NMS IoU threshold (0.45)
  final int maxDetections;             // Max detections to return
  final int numClasses;                // Number of classes (1)
  final List<String> classNames;       // Class names ['tumor']
}
```

### DenseNet Classification Configuration

```dart
class DenseNetConfig {
  final String modelPath;              // Model file path
  final int inputWidth;                // Input width (224)
  final int inputHeight;               // Input height (224)
  final int numClasses;                // Number of classes (4)
  final List<String> classNames;       // Cancer type names
  final List<double> meanValues;       // ImageNet mean [R,G,B]
  final List<double> stdValues;        // ImageNet std [R,G,B]
  final double confidenceThreshold;    // Classification threshold
}
```

### Grad-CAM Configuration

```dart
class GradCAMConfig {
  final bool enabled;                  // Enable Grad-CAM
  final String targetLayer;            // Target layer name
  final double opacity;                // Heatmap opacity (0.0-1.0)
  final GradCAMColormap colormap;      // Colormap (jet/viridis/etc)
  final int heatmapResolution;         // Heatmap resolution (224)
}
```

### Inference Configuration

```dart
class InferenceConfig {
  final int numThreads;                // TFLite threads (4)
  final bool useGpuAcceleration;       // Enable GPU acceleration
  final bool useNnapi;                 // Enable NNAPI (Android)
  final bool useMetal;                 // Enable Metal (iOS)
  final int batchSize;                 // Batch size (1)
  final bool enableModelCaching;       // Enable model caching
  final int initializationTimeout;     // Init timeout (seconds)
  final int inferenceTimeout;          // Inference timeout (seconds)
}
```

## Feature Flags

Feature flags allow conditional enabling/disabling of features:

```dart
class FeatureFlags {
  final bool enableGradCAM;            // Enable Grad-CAM visualization
  final bool enableBatchProcessing;    // Enable batch image processing
  final bool enableCloudSync;          // Enable cloud synchronization
  final bool enableOfflineMode;        // Enable offline mode
  final bool enableExperimentalFeatures; // Enable experimental features
}

// Usage
if (ConfigService.instance.features.enableBatchProcessing) {
  // Show batch processing option
}
```

## Service Integration

Services automatically receive configuration via dependency injection:

```dart
class YOLODetectionServiceTFLite implements IDetectionService {
  final YOLOConfig _config;
  
  YOLODetectionServiceTFLite({required YOLOConfig config})
      : _config = config;
      
  // Access configuration values
  int get inputSize => _config.inputWidth;
  double get confidenceThreshold => _config.confidenceThreshold;
}

// Services are registered with configuration in service_registration.dart
void registerServices() {
  final mlConfig = ConfigService.instance.ml;
  
  registerService<IDetectionService>(
    YOLODetectionServiceTFLite(config: mlConfig.yolo),
  );
}
```

## Hot Reload (Development Only)

Configuration can be updated at runtime in debug mode:

```dart
if (kDebugMode) {
  // Create new configuration
  final newConfig = AppConfig.development().copyWith(
    ml: MLConfig.development().copyWith(
      yolo: YOLOConfig(
        confidenceThreshold: 0.15, // Lower threshold for testing
        // ... other settings
      ),
    ),
  );
  
  // Update configuration
  ConfigService.instance.updateConfig(newConfig);
  
  // Note: Services must be re-registered and re-initialized to pick up changes
}
```

## Testing

For testing, reset the configuration service between tests:

```dart
void main() {
  setUp(() {
    ConfigService.initialize(environment: Environment.development);
    registerServices();
  });
  
  tearDown(() {
    ConfigService.reset();
    ServiceLocator.instance.reset();
  });
  
  test('ML service uses correct configuration', () async {
    final config = ConfigService.instance.ml;
    final detector = getService<IDetectionService>();
    
    // Verify configuration is applied
    expect(detector.confidenceThreshold, config.yolo.confidenceThreshold);
  });
}
```

## Extending Configuration

### Adding New ML Model Configuration

1. **Create configuration class** in `ml_config.dart`:

```dart
class NewModelConfig {
  final String modelPath;
  final double threshold;
  
  const NewModelConfig({
    required this.modelPath,
    required this.threshold,
  });
  
  factory NewModelConfig.development() {
    return const NewModelConfig(
      modelPath: 'assets/models/new_model.tflite',
      threshold: 0.3,
    );
  }
  
  factory NewModelConfig.production() {
    return const NewModelConfig(
      modelPath: 'assets/models/new_model.tflite',
      threshold: 0.5,
    );
  }
}
```

2. **Add to MLConfig**:

```dart
class MLConfig {
  final NewModelConfig newModel;
  
  const MLConfig({
    // ... existing configs
    required this.newModel,
  });
  
  factory MLConfig.development() {
    return MLConfig(
      // ... existing configs
      newModel: NewModelConfig.development(),
    );
  }
}
```

3. **Use in service**:

```dart
class NewModelService {
  final NewModelConfig _config;
  
  NewModelService({required NewModelConfig config})
      : _config = config;
}
```

### Adding New Feature Flag

1. **Add to FeatureFlags** in `app_config.dart`:

```dart
class FeatureFlags {
  final bool enableNewFeature;
  
  const FeatureFlags({
    // ... existing flags
    this.enableNewFeature = false,
  });
  
  factory FeatureFlags.development() {
    return const FeatureFlags(
      // ... existing flags
      enableNewFeature: true,
    );
  }
}
```

2. **Use in application**:

```dart
if (ConfigService.instance.features.enableNewFeature) {
  // Show new feature UI
}
```

## Best Practices

1. **Centralize all configuration** - Don't hardcode values in services
2. **Use environment-specific values** - Different thresholds for dev/prod
3. **Document configuration changes** - Explain why values were changed
4. **Test with different environments** - Ensure app works in all environments
5. **Use feature flags** - For gradual rollout of new features
6. **Avoid runtime configuration updates in production** - Only for development

## Configuration Files Reference

- `lib/core/app_config.dart` - Main configuration and ConfigService
- `lib/core/ml_config.dart` - ML-specific configuration
- `lib/core/service_registration.dart` - Service registration with config
- `lib/main.dart` - Configuration initialization

## Troubleshooting

### ConfigService not initialized error

**Error**: `StateError: ConfigService not initialized`

**Solution**: Call `ConfigService.initialize()` before accessing `ConfigService.instance`:

```dart
void main() async {
  ConfigService.initialize(); // Add this
  runApp(MyApp());
}
```

### Services not using updated configuration

**Problem**: Changed configuration but services still use old values

**Solution**: After updating configuration, re-register and re-initialize services:

```dart
ConfigService.instance.updateConfig(newConfig);
ServiceLocator.instance.reset();
registerServices();
await initializeServices();
```

### Model not found error

**Problem**: TFLite model file not found

**Solution**: Verify model path in configuration matches asset path in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/yolo_v8_int8.tflite
    - assets/models/densenet_int8.tflite
```

## Summary

The configuration management system provides:

- ✅ **Centralized configuration** for all services
- ✅ **Environment-specific settings** (dev/staging/prod)
- ✅ **ML model configuration** (paths, thresholds, parameters)
- ✅ **Feature flags** for conditional features
- ✅ **Type-safe access** via ConfigService
- ✅ **Dependency injection** integration
- ✅ **Hot-reload support** in development
- ✅ **Easy testing** with reset capability
