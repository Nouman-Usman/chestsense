/// Service lifecycle and health monitoring.
///
/// Provides advanced service management capabilities including lifecycle tracking,
/// health checks, and service metadata.
library;

import 'dart:async';
import '../core/logger_service.dart';

/// Service lifecycle states.
enum ServiceLifecycle {
  /// Service is registered but not initialized.
  registered,
  
  /// Service is currently initializing.
  initializing,
  
  /// Service is initialized and ready to use.
  ready,
  
  /// Service is currently being disposed.
  disposing,
  
  /// Service has been disposed.
  disposed,
  
  /// Service initialization or operation failed.
  failed;
  
  bool get isReady => this == ServiceLifecycle.ready;
  bool get isDisposed => this == ServiceLifecycle.disposed;
  bool get isFailed => this == ServiceLifecycle.failed;
  bool get canUse => this == ServiceLifecycle.ready;
}

/// Service scope for lifetime management.
enum ServiceScopeType {
  /// Single instance shared across the application.
  singleton,
  
  /// New instance created for each request.
  transient,
  
  /// Single instance per scope (e.g., per request/session).
  scoped;
}

/// Service health status.
enum HealthStatus {
  /// Service is healthy and functioning normally.
  healthy,
  
  /// Service is operational but experiencing issues.
  degraded,
  
  /// Service is not functioning.
  unhealthy,
  
  /// Health status is unknown.
  unknown;
  
  bool get isHealthy => this == HealthStatus.healthy;
  bool get isOperational => this == HealthStatus.healthy || this == HealthStatus.degraded;
}

/// Health check result.
class HealthCheckResult {
  final HealthStatus status;
  final String? message;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  
  HealthCheckResult({
    required this.status,
    this.message,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory HealthCheckResult.healthy([String? message]) {
    return HealthCheckResult(
      status: HealthStatus.healthy,
      message: message,
      timestamp: DateTime.now(),
    );
  }
  
  factory HealthCheckResult.degraded(String message, {Map<String, dynamic>? details}) {
    return HealthCheckResult(
      status: HealthStatus.degraded,
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }
  
  factory HealthCheckResult.unhealthy(String message, {Map<String, dynamic>? details}) {
    return HealthCheckResult(
      status: HealthStatus.unhealthy,
      message: message,
      details: details,
      timestamp: DateTime.now(),
    );
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('HealthCheck(${status.name}');
    if (message != null) buffer.write(': $message');
    if (details != null) buffer.write(', details: $details');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Interface for services that support health checks.
abstract class IHealthCheckable {
  /// Perform health check on the service.
  Future<HealthCheckResult> checkHealth();
}

/// Interface for services that support lifecycle management.
abstract class ILifecycleAware {
  /// Called when service is being initialized.
  Future<void> onInitialize();
  
  /// Called when service is being disposed.
  Future<void> onDispose();
}

/// Service metadata for tracking and management.
class ServiceMetadata {
  /// Service type.
  final Type type;
  
  /// Service name (human-readable).
  final String name;
  
  /// Service version.
  final String version;
  
  /// Service description.
  final String? description;
  
  /// Service scope (singleton, transient, scoped).
  final ServiceScopeType scopeType;
  
  /// Service tags for categorization.
  final List<String> tags;
  
  /// Service dependencies (types this service depends on).
  final List<Type> dependencies;
  
  /// Registration timestamp.
  final DateTime registeredAt;
  
  /// Initialization timestamp.
  DateTime? initializedAt;
  
  /// Last health check result.
  HealthCheckResult? lastHealthCheck;
  
  /// Current lifecycle state.
  ServiceLifecycle lifecycle;
  
  /// Initialization error if any.
  Object? initializationError;
  
  /// Custom metadata.
  final Map<String, dynamic> metadata;
  
  ServiceMetadata({
    required this.type,
    required this.name,
    this.version = '1.0.0',
    this.description,
    this.scopeType = ServiceScopeType.singleton,
    this.tags = const [],
    this.dependencies = const [],
    DateTime? registeredAt,
    this.lifecycle = ServiceLifecycle.registered,
    this.metadata = const {},
  }) : registeredAt = registeredAt ?? DateTime.now();
  
  /// Check if service is healthy.
  bool get isHealthy => 
      lifecycle.isReady && 
      (lastHealthCheck?.status.isHealthy ?? true);
  
  /// Get service age (time since registration).
  Duration get age => DateTime.now().difference(registeredAt);
  
  /// Get time since initialization.
  Duration? get uptime {
    if (initializedAt == null) return null;
    return DateTime.now().difference(initializedAt!);
  }
  
  /// Mark service as initializing.
  void markInitializing() {
    lifecycle = ServiceLifecycle.initializing;
  }
  
  /// Mark service as ready.
  void markReady() {
    lifecycle = ServiceLifecycle.ready;
    initializedAt = DateTime.now();
    initializationError = null;
  }
  
  /// Mark service as failed.
  void markFailed(Object error) {
    lifecycle = ServiceLifecycle.failed;
    initializationError = error;
  }
  
  /// Mark service as disposing.
  void markDisposing() {
    lifecycle = ServiceLifecycle.disposing;
  }
  
  /// Mark service as disposed.
  void markDisposed() {
    lifecycle = ServiceLifecycle.disposed;
    initializedAt = null;
  }
  
  /// Update health check result.
  void updateHealth(HealthCheckResult result) {
    lastHealthCheck = result;
    if (!result.status.isOperational && lifecycle.isReady) {
      LoggerService.warning(
        'Service $name health degraded: ${result.message}',
      );
    }
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('ServiceMetadata(');
    buffer.write('$name v$version, ');
    buffer.write('scope: ${scopeType.name}, ');
    buffer.write('lifecycle: ${lifecycle.name}');
    if (tags.isNotEmpty) {
      buffer.write(', tags: ${tags.join(", ")}');
    }
    if (dependencies.isNotEmpty) {
      buffer.write(', dependencies: ${dependencies.length}');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// Service scope container for scoped services.
class ServiceScope {
  final String id;
  final DateTime createdAt;
  final Map<Type, Object> _scopedInstances = {};
  
  ServiceScope({String? id})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();
  
  /// Get scoped instance.
  T? getInstance<T extends Object>() {
    return _scopedInstances[T] as T?;
  }
  
  /// Set scoped instance.
  void setInstance<T extends Object>(T instance) {
    _scopedInstances[T] = instance;
  }
  
  /// Check if instance exists in scope.
  bool hasInstance<T extends Object>() {
    return _scopedInstances.containsKey(T);
  }
  
  /// Dispose all scoped instances.
  Future<void> dispose() async {
    LoggerService.ml('Disposing scope $id with ${_scopedInstances.length} instances');
    
    for (final instance in _scopedInstances.values) {
      if (instance is ILifecycleAware) {
        try {
          await instance.onDispose();
        } catch (e) {
          LoggerService.error('Error disposing scoped instance', error: e);
        }
      }
    }
    
    _scopedInstances.clear();
  }
  
  /// Get scope age.
  Duration get age => DateTime.now().difference(createdAt);
}

/// Service event types.
enum ServiceEventType {
  registered,
  initializing,
  initialized,
  healthCheckPerformed,
  failed,
  disposing,
  disposed,
}

/// Service event.
class ServiceEvent {
  final ServiceEventType type;
  final Type serviceType;
  final String serviceName;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  
  ServiceEvent({
    required this.type,
    required this.serviceType,
    required this.serviceName,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() {
    return 'ServiceEvent(${type.name}, $serviceName at ${timestamp.toIso8601String()})';
  }
}

/// Service event listener.
typedef ServiceEventListener = void Function(ServiceEvent event);

/// Service dependency node for graph tracking.
class ServiceDependencyNode {
  final Type type;
  final String name;
  final List<Type> dependencies;
  final List<Type> dependents;
  
  ServiceDependencyNode({
    required this.type,
    required this.name,
    this.dependencies = const [],
    this.dependents = const [],
  });
  
  bool get hasNoDependencies => dependencies.isEmpty;
  bool get hasNoDependents => dependents.isEmpty;
  bool get isLeaf => hasNoDependents;
  bool get isRoot => hasNoDependencies;
}

/// Service dependency graph.
class ServiceDependencyGraph {
  final Map<Type, ServiceDependencyNode> _nodes = {};
  
  /// Add a service node to the graph.
  void addNode(Type type, String name, List<Type> dependencies) {
    _nodes[type] = ServiceDependencyNode(
      type: type,
      name: name,
      dependencies: dependencies,
      dependents: [],
    );
    
    // Update dependents
    for (final dep in dependencies) {
      if (_nodes.containsKey(dep)) {
        final node = _nodes[dep]!;
        if (!node.dependents.contains(type)) {
          node.dependents.add(type);
        }
      }
    }
  }
  
  /// Get initialization order (topological sort).
  List<Type> getInitializationOrder() {
    final result = <Type>[];
    final visited = <Type>{};
    final visiting = <Type>{};
    
    void visit(Type type) {
      if (visited.contains(type)) return;
      if (visiting.contains(type)) {
        throw StateError('Circular dependency detected involving $type');
      }
      
      visiting.add(type);
      
      final node = _nodes[type];
      if (node != null) {
        for (final dep in node.dependencies) {
          visit(dep);
        }
      }
      
      visiting.remove(type);
      visited.add(type);
      result.add(type);
    }
    
    for (final type in _nodes.keys) {
      visit(type);
    }
    
    return result;
  }
  
  /// Get disposal order (reverse of initialization order).
  List<Type> getDisposalOrder() {
    return getInitializationOrder().reversed.toList();
  }
  
  /// Check for circular dependencies.
  bool hasCircularDependencies() {
    try {
      getInitializationOrder();
      return false;
    } on StateError {
      return true;
    }
  }
  
  /// Get all dependencies of a service (transitive).
  Set<Type> getAllDependencies(Type type) {
    final result = <Type>{};
    final node = _nodes[type];
    
    if (node == null) return result;
    
    void collect(Type t) {
      final n = _nodes[t];
      if (n == null) return;
      
      for (final dep in n.dependencies) {
        if (!result.contains(dep)) {
          result.add(dep);
          collect(dep);
        }
      }
    }
    
    collect(type);
    return result;
  }
  
  /// Get all dependents of a service (transitive).
  Set<Type> getAllDependents(Type type) {
    final result = <Type>{};
    final node = _nodes[type];
    
    if (node == null) return result;
    
    void collect(Type t) {
      final n = _nodes[t];
      if (n == null) return;
      
      for (final dep in n.dependents) {
        if (!result.contains(dep)) {
          result.add(dep);
          collect(dep);
        }
      }
    }
    
    collect(type);
    return result;
  }
  
  /// Get node for a service type.
  ServiceDependencyNode? getNode(Type type) => _nodes[type];
  
  /// Clear the graph.
  void clear() {
    _nodes.clear();
  }
}
