/// Enterprise-grade exception hierarchy for ChestSense application.
/// 
/// Provides typed exceptions for better error handling and debugging.
/// Each exception includes contextual information for logging and error recovery.
library;

// ============================================================================
// Base Exception
// ============================================================================

/// Base exception class for all ChestSense exceptions.
/// 
/// Provides common fields for error tracking and debugging.
abstract class ChestSenseException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const ChestSenseException(
    this.message, {
    this.cause,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }
}

// ============================================================================
// ML Service Exceptions
// ============================================================================

/// Thrown when ML model initialization fails.
/// 
/// Common causes:
/// - Model file not found
/// - Corrupted model file
/// - Incompatible TFLite version
/// - Insufficient memory
class ModelInitializationException extends ChestSenseException {
  final String modelPath;
  
  const ModelInitializationException(
    super.message, {
    required this.modelPath,
    super.cause,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() => 'ModelInitializationException: $message (model: $modelPath)';
}

/// Thrown when ML inference/prediction fails.
/// 
/// Common causes:
/// - Invalid input shape
/// - Model not initialized
/// - Runtime error during inference
/// - Memory allocation failure
class InferenceException extends ChestSenseException {
  final String modelName;
  
  const InferenceException(
    super.message, {
    required this.modelName,
    super.cause,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() => 'InferenceException: $message (model: $modelName)';
}

/// Thrown when image preprocessing fails.
/// 
/// Common causes:
/// - Invalid image format
/// - Corrupted image data
/// - Unsupported image dimensions
/// - Memory issues during processing
class ImageProcessingException extends ChestSenseException {
  const ImageProcessingException(
    super.message, {
    super.cause,
    super.stackTrace,
    super.context,
  });
}

/// Thrown when Grad-CAM heatmap generation fails.
/// 
/// This is a recoverable error - analysis can continue without heatmap.
class GradCAMException extends ChestSenseException {
  const GradCAMException(
    super.message, {
    super.cause,
    super.stackTrace,
    super.context,
  });
}

/// Thrown when a service is used before initialization.
/// 
/// Indicates programming error - initialize() must be called first.
class ServiceNotInitializedException extends ChestSenseException {
  final String serviceName;
  
  const ServiceNotInitializedException(
    super.message, {
    required this.serviceName,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() => 'ServiceNotInitializedException: $message (service: $serviceName)';
}

// ============================================================================
// Database Exceptions
// ============================================================================

/// Thrown when database operations fail.
/// 
/// Common causes:
/// - Network connectivity issues
/// - Permission denied
/// - Document not found
/// - Query failures
class DatabaseException extends ChestSenseException {
  final String operation;
  
  const DatabaseException(
    super.message, {
    required this.operation,
    super.cause,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() => 'DatabaseException: $message (operation: $operation)';
}

// ============================================================================
// Input Validation Exceptions
// ============================================================================

/// Thrown when input validation fails.
/// 
/// Indicates client error - invalid data provided by user or caller.
class InvalidInputException extends ChestSenseException {
  final String fieldName;
  final Object? providedValue;
  
  const InvalidInputException(
    super.message, {
    required this.fieldName,
    this.providedValue,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InvalidInputException: $message (field: $fieldName');
    if (providedValue != null) {
      buffer.write(', value: $providedValue');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

// ============================================================================
// Configuration Exceptions
// ============================================================================

/// Thrown when application configuration is invalid.
/// 
/// Common causes:
/// - Missing configuration files
/// - Invalid configuration values
/// - Missing required environment variables
class ConfigurationException extends ChestSenseException {
  final String configKey;
  
  const ConfigurationException(
    super.message, {
    required this.configKey,
    super.cause,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() => 'ConfigurationException: $message (key: $configKey)';
}

// ============================================================================
// Network Exceptions
// ============================================================================

/// Thrown when network operations fail.
/// 
/// Common causes:
/// - No internet connection
/// - Timeout
/// - Server errors (5xx)
/// - DNS resolution failure
class NetworkException extends ChestSenseException {
  final String? url;
  final int? statusCode;
  
  const NetworkException(
    super.message, {
    this.url,
    this.statusCode,
    super.cause,
    super.stackTrace,
    super.context,
  });

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (url != null) {
      buffer.write(' (url: $url)');
    }
    return buffer.toString();
  }
}
