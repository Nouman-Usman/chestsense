# Service Registry Enhancements - Phase 6

## Overview

Phase 6 enhances the ServiceLocator with enterprise-grade features for service lifecycle management, health monitoring, dependency tracking, and advanced diagnostics. This provides comprehensive visibility and control over all services in the application.

## New Features

### 1. Service Lifecycle Management

Services now have explicit lifecycle states that are tracked and managed:

```dart
enum ServiceLifecycle {
  registered,    // Service is registered but not initialized
  initializing,  // Service is currently initializing
  ready,         // Service is initialized and ready to use
  disposing,     // Service is currently being disposed
  disposed,      // Service has been disposed
  failed;        // Service initialization or operation failed
}
```

**Usage:**
```dart
// Check service lifecycle
final metadata = ServiceLocator.instance.getMetadata<IDetectionService>();
if (metadata?.lifecycle.isReady ?? false) {
  // Service is ready to use
}

// Services automatically transition through lifecycle states
// during initialization and disposal
```

### 2. Service Health Checks

Services can implement health check capabilities for monitoring:

```dart
abstract class IHealthCheckable {
  Future<HealthCheckResult> checkHealth();
}

enum HealthStatus {
  healthy,    // Service is functioning normally
  degraded,   // Service is operational but experiencing issues  
  unhealthy,  // Service is not functioning
  unknown;    // Health status is unknown
}
```

**Implementing Health Checks:**
```dart
class YOLODetectionServiceTFLite implements IDetectionService, IHealthCheckable {
  @override
  Future<HealthCheckResult> checkHealth() async {
    if (!_initialized) {
      return HealthCheckResult.unhealthy('Service not initialized');
    }
    
    try {
      // Perform health check (e.g., test inference)
      // ...
      return HealthCheckResult.healthy('Model loaded and ready');
    } catch (e) {
      return HealthCheckResult.degraded('Health check failed', details: {'error': e.toString()});
    }
  }
}
```

**Checking Service Health:**
```dart
// Check single service
final result = await ServiceLocator.instance.checkServiceHealth<IDetectionService>();
print('Health: ${result.status.name} - ${result.message}');

// Check all services
final results = await ServiceLocator.instance.checkAllHealths();
for (final entry in results.entries) {
  print('${entry.key}: ${entry.value.status.name}');
}

// Start periodic health checks
ServiceLocator.instance.startPeriodicHealthChecks(
  interval: Duration(minutes: 5),
);
```

### 3. Service Metadata

Every service now has rich metadata for tracking and management:

```dart
class ServiceMetadata {
  final Type type;
  final String name;              // Human-readable name
  final String version;           // Service version
  final String? description;      // Service description
  final ServiceScopeType scopeType; // Singleton, transient, scoped
  final List<String> tags;        // Tags for categorization
  final List<Type> dependencies;  // Service dependencies
  final ServiceLifecycle lifecycle; // Current lifecycle state
  DateTime? initializedAt;        // Initialization timestamp
  HealthCheckResult? lastHealthCheck; // Last health check result
}
```

**Registering with Metadata:**
```dart
registerService<IDetectionService>(
  YOLODetectionServiceTFLite(config: mlConfig.yolo),
  metadata: ServiceMetadata(
    type: IDetectionService,
    name: 'YOLO Detection Service',
    version: '1.0.0',
    description: 'YOLOv8 tumor detection using TFLite',
    scopeType: ServiceScopeType.singleton,
    tags: ['ml', 'detection', 'yolo', 'tflite'],
    dependencies: [],
  ),
);
```

**Accessing Metadata:**
```dart
// Get metadata for specific service
final meta = ServiceLocator.instance.getMetadata<IDetectionService>();
print('Service: ${meta?.name} v${meta?.version}');
print('Status: ${meta?.lifecycle.name}');
print('Uptime: ${meta?.uptime}');

// Get all service metadata
final allMeta = ServiceLocator.instance.getAllMetadata();
for (final meta in allMeta) {
  print('${meta.name}: ${meta.lifecycle.name}');
}

// Query services by tag
final mlServices = ServiceLocator.instance.getServicesByTag('ml');
print('ML Services: ${mlServices.length}');

// Get unhealthy services
final unhealthy = ServiceLocator.instance.getUnhealthyServices();
if (unhealthy.isNotEmpty) {
  print('Warning: ${unhealthy.length} services are unhealthy');
}
```

### 4. Dependency Graph

The service locator now tracks service dependencies and calculates initialization/disposal order:

```dart
// Get initialization order (topological sort)
final initOrder = ServiceLocator.instance.getInitializationOrder();
print('Init order: ${initOrder.map((t) => t.toString()).join(' → ')}');
// Output: IDetectionService → IClassificationService → IMLPipelineService

// Get disposal order (reverse of initialization)
final disposalOrder = ServiceLocator.instance.getDisposalOrder();
print('Disposal order: ${disposalOrder.map((t) => t.toString()).join(' → ')}');
// Output: IMLPipelineService → IClassificationService → IDetectionService

// Access dependency graph
final graph = ServiceLocator.instance.dependencyGraph;
final deps = graph.getAllDependencies(IMLPipelineService);
print('Dependencies: $deps');

// Check for circular dependencies
if (graph.hasCircularDependencies()) {
  print('Warning: Circular dependencies detected!');
}
```

### 5. Service Events

Listen to service lifecycle events:

```dart
enum ServiceEventType {
  registered,
  initializing,
  initialized,
  healthCheckPerformed,
  failed,
  disposing,
  disposed,
}

// Add event listener
ServiceLocator.instance.addEventListener((event) {
  print('Service Event: ${event.type.name} - ${event.serviceName}');
  
  if (event.type == ServiceEventType.failed) {
    // Handle service failure
    print('Service failed: ${event.serviceName}');
  }
});
```

### 6. Enhanced Diagnostics

Comprehensive diagnostics and statistics:

```dart
// Get service statistics
final stats = ServiceLocator.instance.getStatistics();
print('Total Services: ${stats['totalServices']}');
print('Initialized: ${stats['initialized']}');
print('Ready: ${stats['ready']}');
print('Failed: ${stats['failed']}');
print('Healthy: ${stats['healthy']}');

// Print full diagnostics
ServiceLocator.instance.printDiagnostics();
```

**Example Output:**
```
═══ Service Registry Diagnostics ═══
Total Services: 3
Instantiated: 3
Initialized: 3
Ready: 3
Failed: 0
Healthy: 3
Active Scopes: 0
Event Listeners: 0

═══ Registered Services ═══
✓ YOLO Detection Service (ready, health: healthy)
✓ DenseNet Classification Service (ready, health: healthy)
✓ ML Pipeline Service (ready, health: healthy)
  └─ deps: IDetectionService, IClassificationService
═══════════════════════════════════
```

### 7. Lifecycle Aware Services

Services can implement lifecycle hooks:

```dart
abstract class ILifecycleAware {
  Future<void> onInitialize();
  Future<void> onDispose();
}

class MyService implements ILifecycleAware {
  @override
  Future<void> onInitialize() async {
    // Called during service initialization
    print('Service initializing...');
  }
  
  @override
  Future<void> onDispose() async {
    // Called during service disposal
    print('Service disposing...');
  }
}
```

### 8. Scoped Services

Support for different service scopes:

```dart
enum ServiceScopeType {
  singleton,  // Single instance shared across application
  transient,  // New instance for each request
  scoped;     // Single instance per scope
}

// Scoped services (future enhancement for request/session scoping)
class ServiceScope {
  final String id;
  // Holds scoped instances
}
```

## Integration with Existing Code

### Automatic Initialization Order

Services are now initialized in dependency order:

```dart
Future<bool> initializeServices() async {
  // Gets correct initialization order from dependency graph
  final initOrder = ServiceLocator.instance.getInitializationOrder();
  // Output: [IDetectionService, IClassificationService, IMLPipelineService]
  
  for (final type in initOrder) {
    // Initialize in order
  }
}
```

### Automatic Disposal Order

Services are disposed in reverse order:

```dart
void disposeServices() {
  // Gets correct disposal order (reverse of initialization)
  final disposalOrder = ServiceLocator.instance.getDisposalOrder();
  // Output: [IMLPipelineService, IClassificationService, IDetectionService]
  
  for (final type in disposalOrder) {
    // Dispose in order
  }
}
```

### Enhanced Service Registration

Services are now registered with full metadata in [service_registration.dart](lib/core/service_registration.dart):

```dart
void registerServices() {
  final mlConfig = ConfigService.instance.ml;
  
  registerService<IDetectionService>(
    YOLODetectionServiceTFLite(config: mlConfig.yolo),
    metadata: ServiceMetadata(
      type: IDetectionService,
      name: 'YOLO Detection Service',
      version: '1.0.0',
      description: 'YOLOv8 tumor detection using TFLite',
      scopeType: ServiceScopeType.singleton,
      tags: ['ml', 'detection', 'yolo', 'tflite'],
      dependencies: [],
    ),
  );
  
  // ... more services
}
```

## API Reference

### ServiceLocator Methods

#### Registration
- `registerSingleton<T>(T instance, {ServiceMetadata? metadata})` - Register singleton
- `registerFactory<T>(T Function() factory, {ServiceMetadata? metadata})` - Register factory
- `registerLazySingleton<T>(T Function() factory, {ServiceMetadata? metadata})` - Register lazy singleton

#### Resolution
- `get<T>()` - Get service instance
- `isRegistered<T>()` - Check if service is registered
- `isInitialized<T>()` - Check if service is initialized

#### Metadata
- `getMetadata<T>()` - Get service metadata
- `getAllMetadata()` - Get all service metadata
- `getServicesByTag(String tag)` - Get services by tag
- `getServicesByLifecycle(ServiceLifecycle state)` - Get services by lifecycle state

#### Health Checks
- `checkServiceHealth<T>()` - Check single service health
- `checkAllHealths()` - Check all service health
- `startPeriodicHealthChecks({Duration? interval})` - Start periodic checks
- `stopPeriodicHealthChecks()` - Stop periodic checks
- `getUnhealthyServices()` - Get unhealthy services

#### Dependencies
- `getInitializationOrder()` - Get initialization order
- `getDisposalOrder()` - Get disposal order
- `dependencyGraph` - Access dependency graph

#### Events
- `addEventListener(ServiceEventListener listener)` - Add event listener
- `removeEventListener(ServiceEventListener listener)` - Remove event listener

#### Diagnostics
- `getStatistics()` - Get service statistics
- `printDiagnostics()` - Print full diagnostics
- `registeredTypes` - Get all registered types
- `registeredCount` - Get count of registered services

#### Lifecycle
- `markInitialized<T>()` - Mark service as initialized
- `unregister<T>()` - Unregister service
- `reset()` - Reset service locator

### Global Convenience Functions

```dart
T getService<T extends Object>()
void registerService<T extends Object>(T instance, {ServiceMetadata? metadata})
void registerLazyService<T extends Object>(T Function() factory, {ServiceMetadata? metadata})
void registerFactoryService<T extends Object>(T Function() factory, {ServiceMetadata? metadata})
```

## Best Practices

### 1. Always Provide Metadata

```dart
// Good
registerService<IMyService>(
  MyService(),
  metadata: ServiceMetadata(
    type: IMyService,
    name: 'My Service',
    version: '1.0.0',
    tags: ['core'],
    dependencies: [IOtherService],
  ),
);

// Acceptable (uses defaults)
registerService<IMyService>(MyService());
```

### 2. Declare Dependencies

```dart
registerService<IMLPipelineService>(
  MLPipelineService(...),
  metadata: ServiceMetadata(
    type: IMLPipelineService,
    name: 'ML Pipeline',
    dependencies: [
      IDetectionService,  // Will be initialized first
      IClassificationService,
    ],
  ),
);
```

### 3. Implement Health Checks for Critical Services

```dart
class CriticalService implements IHealthCheckable {
  @override
  Future<HealthCheckResult> checkHealth() async {
    // Test critical functionality
    if (!isOperational()) {
      return HealthCheckResult.unhealthy('Service not operational');
    }
    return HealthCheckResult.healthy();
  }
}
```

### 4. Use Tags for Service Discovery

```dart
// Register with tags
registerService<IService1>(service1, metadata: ServiceMetadata(
  type: IService1,
  name: 'Service 1',
  tags: ['ml', 'core'],
));

// Find by tag
final mlServices = ServiceLocator.instance.getServicesByTag('ml');
```

### 5. Monitor Service Health in Production

```dart
// In production, start periodic health checks
if (ConfigService.instance.environment.isProduction) {
  ServiceLocator.instance.startPeriodicHealthChecks(
    interval: Duration(minutes: 5),
  );
  
  // Listen for health issues
  ServiceLocator.instance.addEventListener((event) {
    if (event.type == ServiceEventType.healthCheckPerformed) {
      // Log to monitoring service
    }
  });
}
```

## Architecture Benefits

✅ **Visibility** - Complete visibility into service state and health  
✅ **Reliability** - Early detection of service failures  
✅ **Dependency Management** - Automatic initialization ordering  
✅ **Diagnostics** - Rich diagnostics for troubleshooting  
✅ **Lifecycle Control** - Fine-grained lifecycle management  
✅ **Monitoring** - Built-in health check support  
✅ **Extensibility** - Event system for custom integrations  
✅ **Documentation** - Self-documenting through metadata  

## Files

### Core Files
- [lib/core/service_lifecycle.dart](lib/core/service_lifecycle.dart) - Lifecycle types and metadata (482 lines)
- [lib/core/service_locator.dart](lib/core/service_locator.dart) - Enhanced ServiceLocator (580 lines)
- [lib/core/service_registration.dart](lib/core/service_registration.dart) - Service registration with metadata (231 lines)

### Documentation
- [SERVICE_REGISTRY.md](SERVICE_REGISTRY.md) - This file

## Migration from Phase 5

No breaking changes - Phase 6 is fully backward compatible. Enhancements are opt-in:

```dart
// Phase 5 style (still works)
registerService<IMyService>(MyService());

// Phase 6 style (recommended)
registerService<IMyService>(
  MyService(),
  metadata: ServiceMetadata(
    type: IMyService,
    name: 'My Service',
    version: '1.0.0',
  ),
);
```

## Summary

Phase 6 transforms the ServiceLocator from a simple DI container into a comprehensive service management system with lifecycle tracking, health monitoring, dependency management, and advanced diagnostics. This provides enterprise-grade service management capabilities essential for production applications.
