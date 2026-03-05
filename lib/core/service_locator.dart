/// Enhanced service locator with lifecycle management, health checks, and dependency tracking.
///
/// Provides dependency injection container with advanced features:
/// - Service lifecycle management (registered, initializing, ready, disposed)
/// - Health monitoring for services
/// - Dependency graph tracking
/// - Service metadata and versioning
/// - Scoped services (singleton, transient, scoped)
/// - Event listeners for service lifecycle events
library;

import 'dart:async';
import '../core/logger_service.dart';
import '../core/exceptions.dart';
import 'service_lifecycle.dart' as lifecycle;

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal();

  // Core service storage
  final Map<Type, Object> _singletons = {};
  final Map<Type, Object Function()> _factories = {};
  final Map<Type, bool> _initialized = {};
  
  // Enhanced Phase 6 features
  final Map<Type, lifecycle.ServiceMetadata> _metadata = {};
  final lifecycle.ServiceDependencyGraph _dependencyGraph = lifecycle.ServiceDependencyGraph();
  final List<lifecycle.ServiceEventListener> _eventListeners = [];
  final Map<String, lifecycle.ServiceScope> _scopes = {};
  
  // Health check scheduling
  Timer? _healthCheckTimer;
  Duration _healthCheckInterval = const Duration(minutes: 5);

  /// Register a singleton service with metadata.
  /// 
  /// Example:
  /// ```dart
  /// ServiceLocator.instance.registerSingleton<IDetectionService>(
  ///   YOLODetectionServiceTFLite(),
  ///   metadata: ServiceMetadata(
  ///     type: IDetectionService,
  ///     name: 'YOLO Detection',
  ///     version: '1.0.0',
  ///     tags: ['ml', 'detection'],
  ///     dependencies: [],
  ///   ),
  /// );
  /// ```
  void registerSingleton<T extends Object>(
    T instance, {
    lifecycle.ServiceMetadata? metadata,
  }) {
    final type = T;
    if (_singletons.containsKey(type)) {
      LoggerService.warning(
        'Service already registered: $type. Replacing existing instance.',
      );
    }
    
    _singletons[type] = instance;
    _initialized[type] = false;
    
    // Register metadata
    final meta = metadata ?? lifecycle.ServiceMetadata(
      type: type,
      name: type.toString(),
      scopeType: lifecycle.ServiceScopeType.singleton,
    );
    _metadata[type] = meta;
    
    // Add to dependency graph
    _dependencyGraph.addNode(type, meta.name, meta.dependencies);
    
    // Emit event
    _emitEvent(lifecycle.ServiceEvent(
      type: lifecycle.ServiceEventType.registered,
      serviceType: type,
      serviceName: meta.name,
    ));
    
    LoggerService.ml('Registered singleton: $type', isDebug: true);
  }

  /// Register a factory for creating service instances.
  void registerFactory<T extends Object>(
    T Function() factory, {
    lifecycle.ServiceMetadata? metadata,
  }) {
    final type = T;
    if (_factories.containsKey(type)) {
      LoggerService.warning(
        'Factory already registered: $type. Replacing existing factory.',
      );
    }
    
    _factories[type] = factory;
    
    // Register metadata
    final meta = metadata ?? lifecycle.ServiceMetadata(
      type: type,
      name: type.toString(),
      scopeType: lifecycle.ServiceScopeType.transient,
    );
    _metadata[type] = meta;
    
    // Add to dependency graph
    _dependencyGraph.addNode(type, meta.name, meta.dependencies);
    
    _emitEvent(lifecycle.ServiceEvent(
      type: lifecycle.ServiceEventType.registered,
      serviceType: type,
      serviceName: meta.name,
    ));
    
    LoggerService.ml('Registered factory: $type', isDebug: true);
  }
  
  /// Register a lazy singleton.
  /// 
  /// Instance is created on first [get] call and reused thereafter.
  /// 
  /// Example:
  /// ```dart
  /// ServiceLocator.instance.registerLazySingleton<IDetectionService>(
  ///   () => YOLODetectionServiceTFLite(),
  ///   metadata: ServiceMetadata(
  ///     type: IDetectionService,
  ///     name: 'YOLO Detection',
  ///     dependencies: [ITFLiteInterpreter],
  ///   ),
  /// );
  /// ```
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    lifecycle.ServiceMetadata? metadata,
  }) {
    final type = T;
    if (_factories.containsKey(type) || _singletons.containsKey(type)) {
      LoggerService.warning(
        'Service already registered: $type. Replacing existing registration.',
      );
    }
    
    _factories[type] = () {
      if (!_singletons.containsKey(type)) {
        final instance = factory();
        _singletons[type] = instance;
        _initialized[type] = false;
        LoggerService.ml('Created lazy singleton: $type', isDebug: true);
      }
      return _singletons[type]!;
    };
    
    // Register metadata
    final meta = metadata ?? lifecycle.ServiceMetadata(
      type: type,
      name: type.toString(),
      scopeType: lifecycle.ServiceScopeType.singleton,
    );
    _metadata[type] = meta;
    
    // Add to dependency graph
    _dependencyGraph.addNode(type, meta.name, meta.dependencies);
    
    _emitEvent(lifecycle.ServiceEvent(
      type: lifecycle.ServiceEventType.registered,
      serviceType: type,
      serviceName: meta.name,
    ));
    
    LoggerService.ml('Registered lazy singleton: $type', isDebug: true);
  }
  
  /// Get a service instance.
  /// 
  /// Throws [ConfigurationException] if service not registered.
  /// 
  /// Example:
  /// ```dart
  /// final detector = ServiceLocator.get<IDetectionService>();
  /// ```
  static T get<T extends Object>() {
    return instance._get<T>();
  }
  
  T _get<T extends Object>() {
    final type = T;
    
    // Check if service is in degraded or failed state
    final meta = _metadata[type];
    if (meta != null) {
      if (meta.lifecycle.isFailed) {
        LoggerService.warning(
          'Attempting to get service $type in failed state. Error: ${meta.initializationError}',
        );
      }
      if (meta.lifecycle.isDisposed) {
        throw ConfigurationException(
          'Service $type has been disposed and cannot be used.',
          configKey: type.toString(),
        );
      }
    }
    
    if (_singletons.containsKey(type)) {
      return _singletons[type] as T;
    }
    if (_factories.containsKey(type)) {
      final factory = _factories[type]!;
      return factory() as T;
    }
    throw ConfigurationException(
      'Service not registered: $type. Call ServiceLocator.instance.register<$type>() first.',
      configKey: type.toString(),
    );
  }
  
  /// Check if a service is registered.
  bool isRegistered<T extends Object>() {
    final type = T;
    return _singletons.containsKey(type) || _factories.containsKey(type);
  }
  
  /// Mark service as initialized.
  void markInitialized<T extends Object>() {
    final type = T;
    _initialized[type] = true;
    
    final meta = _metadata[type];
    if (meta != null) {
      meta.markReady();
      _emitEvent(lifecycle.ServiceEvent(
        type: lifecycle.ServiceEventType.initialized,
        serviceType: type,
        serviceName: meta.name,
      ));
    }
    
    LoggerService.ml('Marked as initialized: $type', isDebug: true);
  }
  
  /// Check if a service is initialized.
  bool isInitialized<T extends Object>() {
    final type = T;
    return _initialized[type] ?? false;
  }
  
  /// Get service metadata.
  lifecycle.ServiceMetadata? getMetadata<T extends Object>() {
    return _metadata[T];
  }
  
  /// Get all service metadata.
  List<lifecycle.ServiceMetadata> getAllMetadata() {
    return _metadata.values.toList();
  }
  
  /// Perform health check on a service.
  Future<lifecycle.HealthCheckResult> checkServiceHealth<T extends Object>() async {
    final type = T;
    final instance = _singletons[type];
    
    if (instance == null) {
      return lifecycle.HealthCheckResult.unhealthy('Service not instantiated');
    }
    
    if (instance is lifecycle.IHealthCheckable) {
      try {
        final result = await instance.checkHealth();
        
        // Update metadata
        final meta = _metadata[type];
        meta?.updateHealth(result);
        
        _emitEvent(lifecycle.ServiceEvent(
          type: lifecycle.ServiceEventType.healthCheckPerformed,
          serviceType: type,
          serviceName: meta?.name ?? type.toString(),
          data: {'status': result.status.name},
        ));
        
        return result;
      } catch (e) {
        final result = lifecycle.HealthCheckResult.unhealthy(
          'Health check failed: $e',
        );
        _metadata[type]?.updateHealth(result);
        return result;
      }
    }
    
    // Service doesn't support health checks
    return lifecycle.HealthCheckResult.healthy('No health check implemented');
  }
  
  /// Perform health check on all services.
  Future<Map<Type, lifecycle.HealthCheckResult>> checkAllHealths() async {
    final results = <Type, lifecycle.HealthCheckResult>{};
    
    for (final type in _singletons.keys) {
      final instance = _singletons[type];
      if (instance is lifecycle.IHealthCheckable) {
        try {
          final result = await instance.checkHealth();
          results[type] = result;
          _metadata[type]?.updateHealth(result);
        } catch (e) {
          results[type] = lifecycle.HealthCheckResult.unhealthy('Check failed: $e');
        }
      }
    }
    
    LoggerService.ml('Health check completed: ${results.length} services checked');
    return results;
  }
  
  /// Start periodic health checks.
  void startPeriodicHealthChecks({Duration? interval}) {
    _healthCheckInterval = interval ?? _healthCheckInterval;
    
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      LoggerService.ml('Running periodic health checks...', isDebug: true);
      await checkAllHealths();
    });
    
    LoggerService.ml('Started periodic health checks (interval: $_healthCheckInterval)');
  }
  
  /// Stop periodic health checks.
  void stopPeriodicHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    LoggerService.ml('Stopped periodic health checks');
  }
  
  /// Add event listener for service lifecycle events.
  void addEventListener(lifecycle.ServiceEventListener listener) {
    _eventListeners.add(listener);
  }
  
  /// Remove event listener.
  void removeEventListener(lifecycle.ServiceEventListener listener) {
    _eventListeners.remove(listener);
  }
  
  /// Emit service event to all listeners.
  void _emitEvent(lifecycle.ServiceEvent event) {
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (e) {
        LoggerService.error('Error in event listener', error: e);
      }
    }
  }
  
  /// Get dependency graph.
  lifecycle.ServiceDependencyGraph get dependencyGraph => _dependencyGraph;
  
  /// Get initialization order based on dependencies.
  List<Type> getInitializationOrder() {
    try {
      return _dependencyGraph.getInitializationOrder();
    } catch (e) {
      LoggerService.error('Failed to calculate initialization order', error: e);
      return _metadata.keys.toList();
    }
  }
  
  /// Get disposal order based on dependencies.
  List<Type> getDisposalOrder() {
    try {
      return _dependencyGraph.getDisposalOrder();
    } catch (e) {
      LoggerService.error('Failed to calculate disposal order', error: e);
      return _metadata.keys.toList();
    }
  }
  
  /// Unregister a service.
  void unregister<T extends Object>() {
    final type = T;
    
    final meta = _metadata[type];
    if (meta != null) {
      meta.markDisposed();
      _emitEvent(lifecycle.ServiceEvent(
        type: lifecycle.ServiceEventType.disposed,
        serviceType: type,
        serviceName: meta.name,
      ));
    }
    
    _singletons.remove(type);
    _factories.remove(type);
    _initialized.remove(type);
    _metadata.remove(type);
    
    LoggerService.ml('Unregistered: $type', isDebug: true);
  }
  
  /// Reset service locator (clear all registrations).
  void reset() {
    LoggerService.ml('Resetting ServiceLocator - clearing all registrations', isDebug: true);
    
    // Stop health checks
    stopPeriodicHealthChecks();
    
    // Emit disposal events
    for (final meta in _metadata.values) {
      _emitEvent(lifecycle.ServiceEvent(
        type: lifecycle.ServiceEventType.disposed,
        serviceType: meta.type,
        serviceName: meta.name,
      ));
    }
    
    _singletons.clear();
    _factories.clear();
    _initialized.clear();
    _metadata.clear();
    _dependencyGraph.clear();
    _eventListeners.clear();
    _scopes.clear();
  }
  
  /// Get count of registered services.
  int get registeredCount => _singletons.length + _factories.length;
  
  /// Get all registered service types.
  List<Type> get registeredTypes => [
    ..._singletons.keys,
    ..._factories.keys.where((key) => !_singletons.containsKey(key)),
  ];
  
  /// Get service statistics.
  Map<String, dynamic> getStatistics() {
    final totalServices = registeredCount;
    final instantiated = _singletons.length;
    final initialized = _initialized.values.where((v) => v).length;
    
    final healthyCount = _metadata.values
        .where((m) => m.lastHealthCheck?.status.isHealthy ?? false)
        .length;
    
    final readyCount = _metadata.values
        .where((m) => m.lifecycle.isReady)
        .length;
    
    final failedCount = _metadata.values
        .where((m) => m.lifecycle.isFailed)
        .length;
    
    return {
      'totalServices': totalServices,
      'instantiated': instantiated,
      'initialized': initialized,
      'ready': readyCount,
      'failed': failedCount,
      'healthy': healthyCount,
      'scopes': _scopes.length,
      'eventListeners': _eventListeners.length,
    };
  }
  
  /// Get services by tag.
  List<lifecycle.ServiceMetadata> getServicesByTag(String tag) {
    return _metadata.values
        .where((m) => m.tags.contains(tag))
        .toList();
  }
  
  /// Get services by lifecycle state.
  List<lifecycle.ServiceMetadata> getServicesByLifecycle(
    lifecycle.ServiceLifecycle state,
  ) {
    return _metadata.values
        .where((m) => m.lifecycle == state)
        .toList();
  }
  
  /// Get unhealthy services.
  List<lifecycle.ServiceMetadata> getUnhealthyServices() {
    return _metadata.values
        .where((m) => 
          m.lastHealthCheck != null && 
          !m.lastHealthCheck!.status.isOperational)
        .toList();
  }
  
  /// Print service registry diagnostics.
  void printDiagnostics() {
    final stats = getStatistics();
    
    LoggerService.ml('═══ Service Registry Diagnostics ═══');
    LoggerService.ml('Total Services: ${stats['totalServices']}');
    LoggerService.ml('Instantiated: ${stats['instantiated']}');
    LoggerService.ml('Initialized: ${stats['initialized']}');
    LoggerService.ml('Ready: ${stats['ready']}');
    LoggerService.ml('Failed: ${stats['failed']}');
    LoggerService.ml('Healthy: ${stats['healthy']}');
    LoggerService.ml('Active Scopes: ${stats['scopes']}');
    LoggerService.ml('Event Listeners: ${stats['eventListeners']}');
    
    // List all services
    LoggerService.ml('\n═══ Registered Services ═══');
    for (final meta in _metadata.values) {
      final status = meta.lifecycle.isReady ? '✓' : 
                     meta.lifecycle.isFailed ? '✗' : '○';
      final health = meta.lastHealthCheck?.status.name ?? 'unknown';
      LoggerService.ml('$status ${meta.name} (${meta.lifecycle.name}, health: $health)');
      
      if (meta.dependencies.isNotEmpty) {
        LoggerService.ml('  └─ deps: ${meta.dependencies.map((t) => t.toString()).join(", ")}');
      }
    }
    
    // Check for circular dependencies
    if (_dependencyGraph.hasCircularDependencies()) {
      LoggerService.warning('⚠️  Circular dependencies detected!');
    }
    
    LoggerService.ml('═══════════════════════════════════');
  }

  @Deprecated('Use initializeServices() from service_registration.dart instead')
  Future<int> initializeAll() async {
    int count = 0;
    LoggerService.ml('Initializing all registered services...');
    LoggerService.warning('initializeAll() is deprecated. Use initializeServices() from service_registration.dart instead.');
    
    LoggerService.success('Initialized $count services');
    return count;
  }

  @Deprecated('Use disposeServices() from service_registration.dart instead')
  void disposeAll() {
    LoggerService.ml('Disposing all registered services...');
    LoggerService.warning('disposeAll() is deprecated. Use disposeServices() from service_registration.dart instead.');
    
    _initialized.clear();
    LoggerService.ml('All services disposed');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Global convenience functions
// ═══════════════════════════════════════════════════════════════════════════

/// Get a service instance (convenience wrapper).
T getService<T extends Object>() => ServiceLocator.get<T>();

/// Register a singleton service (convenience wrapper).
void registerService<T extends Object>(
  T instance, {
  lifecycle.ServiceMetadata? metadata,
}) {
  ServiceLocator.instance.registerSingleton<T>(instance, metadata: metadata);
}

/// Register a lazy singleton service (convenience wrapper).
void registerLazyService<T extends Object>(
  T Function() factory, {
  lifecycle.ServiceMetadata? metadata,
}) {
  ServiceLocator.instance.registerLazySingleton<T>(factory, metadata: metadata);
}

/// Register a factory service (convenience wrapper).
void registerFactoryService<T extends Object>(
  T Function() factory, {
  lifecycle.ServiceMetadata? metadata,
}) {
  ServiceLocator.instance.registerFactory<T>(factory, metadata: metadata);
}
