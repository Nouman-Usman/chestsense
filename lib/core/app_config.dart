import 'package:flutter/foundation.dart';
import 'ml_config.dart';

enum Environment {
  development,
  staging,
  production;
  bool get isDevelopment => this == Environment.development;
  bool get isStaging => this == Environment.staging;
  bool get isProduction => this == Environment.production;
  static Environment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dev':
      case 'development':
        return Environment.development;
      case 'staging':
      case 'stg':
        return Environment.staging;
      case 'prod':
      case 'production':
        return Environment.production;
      default:
        return Environment.development;
    }
  }
}
class AppConfig {
  final Environment environment;
  final MLConfig ml;
  final bool enableDebugLogging;
  final bool enablePerformanceMonitoring;
  final bool enableAnalytics;
  final FirebaseConfig firebase;
  final ApiConfig api;
  final FeatureFlags features;

  const AppConfig({
    required this.environment,
    required this.ml,
    this.enableDebugLogging = false,
    this.enablePerformanceMonitoring = false,
    this.enableAnalytics = false,
    required this.firebase,
    required this.api,
    required this.features,
  });

  /// Create development configuration.
  factory AppConfig.development() {
    return AppConfig(
      environment: Environment.development,
      ml: MLConfig.development(),
      enableDebugLogging: true,
      enablePerformanceMonitoring: true,
      enableAnalytics: false,
      firebase: FirebaseConfig.development(),
      api: ApiConfig.development(),
      features: FeatureFlags.development(),
    );
  }

  /// Create staging configuration.
  factory AppConfig.staging() {
    return AppConfig(
      environment: Environment.staging,
      ml: MLConfig.staging(),
      enableDebugLogging: true,
      enablePerformanceMonitoring: true,
      enableAnalytics: true,
      firebase: FirebaseConfig.staging(),
      api: ApiConfig.staging(),
      features: FeatureFlags.staging(),
    );
  }

  /// Create production configuration.
  factory AppConfig.production() {
    return AppConfig(
      environment: Environment.production,
      ml: MLConfig.production(),
      enableDebugLogging: false,
      enablePerformanceMonitoring: true,
      enableAnalytics: true,
      firebase: FirebaseConfig.production(),
      api: ApiConfig.production(),
      features: FeatureFlags.production(),
    );
  }

  /// Create configuration based on environment.
  factory AppConfig.fromEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        return AppConfig.development();
      case Environment.staging:
        return AppConfig.staging();
      case Environment.production:
        return AppConfig.production();
    }
  }
}

/// Firebase configuration.
class FirebaseConfig {
  final String projectId;
  final String storageBucket;
  final bool enableFirestore;
  final bool enableAuth;
  final bool enableStorage;

  const FirebaseConfig({
    required this.projectId,
    required this.storageBucket,
    this.enableFirestore = true,
    this.enableAuth = true,
    this.enableStorage = true,
  });

  factory FirebaseConfig.development() {
    return const FirebaseConfig(
      projectId: 'chestsense-dev',
      storageBucket: 'chestsense-dev.appspot.com',
    );
  }

  factory FirebaseConfig.staging() {
    return const FirebaseConfig(
      projectId: 'chestsense-staging',
      storageBucket: 'chestsense-staging.appspot.com',
    );
  }

  factory FirebaseConfig.production() {
    return const FirebaseConfig(
      projectId: 'chestsense-prod',
      storageBucket: 'chestsense-prod.appspot.com',
    );
  }
}

/// API configuration.
class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final bool enableCaching;

  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableCaching = true,
  });

  factory ApiConfig.development() {
    return const ApiConfig(
      baseUrl: 'http://localhost:8080/api',
      timeout: Duration(seconds: 60),
    );
  }

  factory ApiConfig.staging() {
    return const ApiConfig(
      baseUrl: 'https://staging-api.chestsense.com/api',
      timeout: Duration(seconds: 45),
    );
  }

  factory ApiConfig.production() {
    return const ApiConfig(
      baseUrl: 'https://api.chestsense.com/api',
      timeout: Duration(seconds: 30),
    );
  }
}

/// Feature flags for conditional features.
class FeatureFlags {
  final bool enableGradCAM;
  final bool enableBatchProcessing;
  final bool enableCloudSync;
  final bool enableOfflineMode;
  final bool enableExperimentalFeatures;

  const FeatureFlags({
    this.enableGradCAM = true,
    this.enableBatchProcessing = false,
    this.enableCloudSync = true,
    this.enableOfflineMode = false,
    this.enableExperimentalFeatures = false,
  });

  factory FeatureFlags.development() {
    return const FeatureFlags(
      enableGradCAM: true,
      enableBatchProcessing: true,
      enableCloudSync: false,
      enableOfflineMode: true,
      enableExperimentalFeatures: true,
    );
  }

  factory FeatureFlags.staging() {
    return const FeatureFlags(
      enableGradCAM: true,
      enableBatchProcessing: true,
      enableCloudSync: true,
      enableOfflineMode: false,
      enableExperimentalFeatures: true,
    );
  }

  factory FeatureFlags.production() {
    return const FeatureFlags(
      enableGradCAM: true,
      enableBatchProcessing: false,
      enableCloudSync: true,
      enableOfflineMode: false,
      enableExperimentalFeatures: false,
    );
  }
}

/// Configuration service for managing application configuration.
///
/// Provides global access to configuration and supports hot-reload in debug mode.
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance {
    if (_instance == null) {
      throw StateError(
        'ConfigService not initialized. Call ConfigService.initialize() first.',
      );
    }
    return _instance!;
  }

  AppConfig _config;

  ConfigService._(this._config);

  /// Initialize configuration service.
  ///
  /// Must be called before accessing [instance].
  static void initialize({Environment? environment}) {
    // Determine environment from const or default to development in debug mode
    final env = environment ??
        (kDebugMode ? Environment.development : Environment.production);

    _instance = ConfigService._(AppConfig.fromEnvironment(env));
  }

  /// Get current configuration.
  AppConfig get config => _config;

  /// Get current environment.
  Environment get environment => _config.environment;

  /// Get ML configuration.
  MLConfig get ml => _config.ml;

  /// Get Firebase configuration.
  FirebaseConfig get firebase => _config.firebase;

  /// Get API configuration.
  ApiConfig get api => _config.api;

  /// Get feature flags.
  FeatureFlags get features => _config.features;

  /// Update configuration (useful for hot-reload in development).
  ///
  /// Only available in debug mode.
  void updateConfig(AppConfig newConfig) {
    if (!kDebugMode) {
      throw UnsupportedError(
        'Configuration updates are only allowed in debug mode.',
      );
    }
    _config = newConfig;
  }

  /// Reset configuration service (useful for testing).
  static void reset() {
    _instance = null;
  }
}
