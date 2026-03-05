import 'package:chestsense/core/service_locator.dart';
import 'package:chestsense/core/service_interfaces.dart';
import 'package:chestsense/core/app_config.dart';
import 'package:chestsense/core/service_lifecycle.dart';
import 'package:chestsense/services/yolo_detection_service_tflite.dart';
import 'package:chestsense/services/densenet_classification_service_tflite.dart';
import 'package:chestsense/services/ml_pipeline_service_tflite.dart';
import 'package:chestsense/core/logger_service.dart';

/// Register all application services with the service locator.
///
/// This should be called once during app initialization before [initializeServices].
/// Services are registered with metadata for enhanced lifecycle management.
void registerServices() {
  LoggerService.ml('Registering application services...');
  
  // Get ML configuration from ConfigService
  final mlConfig = ConfigService.instance.ml;
  
  // Register detection service with metadata
  registerService<IDetectionService>(
    YOLODetectionServiceTFLite(
      config: mlConfig.yolo,
    ),
    metadata: ServiceMetadata(
      type: IDetectionService,
      name: 'YOLO Detection Service',
      version: '1.0.0',
      description: 'YOLOv8 tumor detection using TFLite',
      scopeType: ServiceScopeType.singleton,
      tags: ['ml', 'detection', 'yolo', 'tflite'],
      dependencies: [], // TFLiteInterpreter is created internally
    ),
  );
  
  // Register classification service with metadata
  registerService<IClassificationService>(
    DenseNetClassificationServiceTFLite(
      config: mlConfig.densenet,
    ),
    metadata: ServiceMetadata(
      type: IClassificationService,
      name: 'DenseNet Classification Service',
      version: '1.0.0',
      description: 'DenseNet121 tumor classification using TFLite',
      scopeType: ServiceScopeType.singleton,
      tags: ['ml', 'classification', 'densenet', 'tflite'],
      dependencies: [], // GradCAM service is created internally
    ),
  );
  
  // Register ML pipeline service (lazy loaded) with metadata
  registerLazyService<IMLPipelineService>(
    () {
      return MLPipelineServiceTFLite(
        detectionService: getService<IDetectionService>(),
        classificationService: getService<IClassificationService>(),
      );
    },
    metadata: ServiceMetadata(
      type: IMLPipelineService,
      name: 'ML Pipeline Service',
      version: '1.0.0',
      description: 'Complete ML pipeline: detection + classification',
      scopeType: ServiceScopeType.singleton,
      tags: ['ml', 'pipeline', 'orchestration'],
      dependencies: [
        IDetectionService,
        IClassificationService,
      ],
    ),
  );
  
  final stats = ServiceLocator.instance.getStatistics();
  LoggerService.success('Services registered: ${stats['totalServices']} services');
  
  // Log initialization order based on dependencies
  final initOrder = ServiceLocator.instance.getInitializationOrder();
  LoggerService.ml('Initialization order: ${initOrder.map((t) => t.toString()).join(' → ')}', isDebug: true);
}

/// Initialize all ML services in dependency order.
///
/// Returns true if all services initialized successfully, false otherwise.
/// Uses dependency graph to initialize services in correct order.
Future<bool> initializeServices() async {
  try {
    LoggerService.ml('Initializing ML services...');
    
    // Get initialization order from dependency graph
    final initOrder = ServiceLocator.instance.getInitializationOrder();
    LoggerService.ml('Initialization order: ${initOrder.map((t) => t.toString().split('.').last).join(' → ')}');
    
    // Initialize services in order
    for (final type in initOrder) {
      if (type == IDetectionService) {
        await _initializeService<IDetectionService>('Detection');
      } else if (type == IClassificationService) {
        await _initializeService<IClassificationService>('Classification');
      } else if (type == IMLPipelineService) {
        await _initializeService<IMLPipelineService>('ML Pipeline');
      }
    }
    
    LoggerService.success('All ML services initialized successfully');
    
    // Print diagnostics in debug mode
    if (ConfigService.instance.config.enableDebugLogging) {
      ServiceLocator.instance.printDiagnostics();
    }
    
    return true;
  } catch (e, stackTrace) {
    LoggerService.error(
      'Service initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
    return false;
  }
}

/// Helper to initialize a single service.
Future<void> _initializeService<T extends Object>(String name) async {
  final locator = ServiceLocator.instance;
  final metadata = locator.getMetadata<T>();
  
  try {
    LoggerService.ml('Initializing $name service...', isDebug: true);
    
    // Mark as initializing
    metadata?.markInitializing();
    
    // Get service and initialize
    final service = getService<T>();
    
    // If service implements ILifecycleAware, call onInitialize
    if (service is ILifecycleAware) {
      await service.onInitialize();
    }
    
    // For ML services, call their initialize method
    if (service is IDetectionService || 
        service is IClassificationService || 
        service is IMLPipelineService) {
      // These interfaces have initialize() method
      await (service as dynamic).initialize();
    }
    
    // Mark as initialized in ServiceLocator
    locator.markInitialized<T>();
    
    LoggerService.ml('$name service ready', isDebug: true);
  } catch (e, stackTrace) {
    LoggerService.error('Failed to initialize $name service', error: e, stackTrace: stackTrace);
    
    // Mark as failed
    metadata?.markFailed(e);
    
    rethrow;
  }
}

/// Dispose all ML services in reverse dependency order.
void disposeServices() {
  try {
    LoggerService.ml('Disposing ML services...');
    
    // Get disposal order (reverse of initialization)
    final disposalOrder = ServiceLocator.instance.getDisposalOrder();
    LoggerService.ml('Disposal order: ${disposalOrder.map((t) => t.toString().split('.').last).join(' → ')}', isDebug: true);
    
    // Dispose services in order
    for (final type in disposalOrder) {
      if (type == IMLPipelineService && ServiceLocator.instance.isRegistered<IMLPipelineService>()) {
        _disposeService<IMLPipelineService>('ML Pipeline');
      } else if (type == IClassificationService && ServiceLocator.instance.isRegistered<IClassificationService>()) {
        _disposeService<IClassificationService>('Classification');
      } else if (type == IDetectionService && ServiceLocator.instance.isRegistered<IDetectionService>()) {
        _disposeService<IDetectionService>('Detection');
      }
    }
    
    LoggerService.success('All ML services disposed');
  } catch (e) {
    LoggerService.error('Error disposing services', error: e);
  }
}

/// Helper to dispose a single service.
void _disposeService<T extends Object>(String name) {
  try {
    final metadata = ServiceLocator.instance.getMetadata<T>();
    
    LoggerService.ml('Disposing $name service...', isDebug: true);
    
    // Mark as disposing
    metadata?.markDisposing();
    
    final service = getService<T>();
    
    // If service implements ILifecycleAware, call onDispose
    if (service is ILifecycleAware) {
      service.onDispose();
    }
    
    // For ML services, call their dispose method
    if (service is IDetectionService || 
        service is IClassificationService || 
        service is IMLPipelineService) {
      (service as dynamic).dispose();
    }
    
    // Mark as disposed
    metadata?.markDisposed();
    
    LoggerService.ml('$name service disposed', isDebug: true);
  } catch (e) {
    LoggerService.error('Error disposing $name service', error: e);
  }
}

/// Reset all services and clear the service locator.
void resetServices() {
  disposeServices();
  ServiceLocator.instance.reset();
  LoggerService.ml('Service locator reset');
}
