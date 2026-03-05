/// Service interfaces for dependency injection.
/// 
/// Defines abstract contracts for all major services in the application.
/// This enables loose coupling, easier testing, and platform-specific implementations.
library;

import 'dart:typed_data';
import 'package:image/image.dart' as img;

// ============================================================================
// ML Service Interfaces
// ============================================================================

abstract class IDetectionService {
  Future<void> initialize();
  Future<List<DetectionResult>> detect(img.Image image);
  void dispose();
  bool get isInitialized;
}
class DetectionResult {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final int classId;
  
  DetectionResult({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.classId,
  });
  
  /// Get bounding box as [x1, y1, x2, y2]
  List<double> get bbox => [
    x - width / 2,
    y - height / 2,
    x + width / 2,
    y + height / 2,
  ];
}

/// Interface for image classification services (e.g., DenseNet).
/// 
/// Classifies image regions into predefined categories.
abstract class IClassificationService {
  /// Initialize the classification model.
  /// 
  /// Must be called before [classify].
  /// Throws [ModelInitializationException] if initialization fails.
  Future<void> initialize();
  
  /// Classify the given image.
  /// 
  /// [image] - Image to classify
  /// [generateGradCAM] - Whether to generate Grad-CAM heatmap visualization
  /// 
  /// Returns classification result with label, confidence, and optional heatmap.
  /// Throws [InferenceException] if classification fails.
  /// Throws [ServiceNotInitializedException] if called before [initialize].
  Future<ClassificationResult> classify(
    img.Image image, {
    bool generateGradCAM = false,
  });
  
  /// Release model resources.
  void dispose();
  
  /// Whether the service is initialized and ready.
  bool get isInitialized;
}

/// Result from classification service.
class ClassificationResult {
  final String label;
  final double confidence;
  final Map<String, double> classScores;
  final img.Image? gradcamHeatmap;
  
  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.classScores,
    this.gradcamHeatmap,
  });
}

/// Interface for Grad-CAM visualization services.
/// 
/// Generates class activation maps for explainable AI.
abstract class IGradCAMService {
  /// Initialize the Grad-CAM service.
  Future<void> initialize();
  
  /// Generate Grad-CAM heatmap for the given image and target class.
  /// 
  /// [image] - Input image
  /// [targetClassIndex] - Index of the target class
  /// [classLabels] - Map of class indices to labels
  /// 
  /// Returns heatmap visualization and predictions.
  /// Throws [GradCAMException] if generation fails.
  Future<GradCAMResult> generateGradCAM(
    img.Image image,
    int targetClassIndex,
    Map<int, String> classLabels,
  );
}

/// Result from Grad-CAM generation.
class GradCAMResult {
  final img.Image heatmap;
  final String targetClass;
  final double confidence;
  final List<double> predictions;
  
  GradCAMResult({
    required this.heatmap,
    required this.targetClass,
    required this.confidence,
    required this.predictions,
  });
}

/// Interface for complete ML pipeline (detection + classification).
/// 
/// Orchestrates multi-stage ML analysis workflow.
abstract class IMLPipelineService {
  /// Initialize the entire ML pipeline.
  /// 
  /// Must be called before [analyze].
  /// Throws [ModelInitializationException] if initialization fails.
  Future<void> initialize();
  
  /// Run complete analysis: detection → classification.
  /// 
  /// [image] - CT scan slice to analyze
  /// 
  /// Returns comprehensive analysis result with all detected tumors.
  /// Throws [InferenceException] if analysis fails.
  /// Throws [ServiceNotInitializedException] if called before [initialize].
  Future<TumorAnalysisResult> analyze(img.Image image);
  
  /// Analyze image from raw bytes.
  /// 
  /// Convenience method that decodes bytes before analysis.
  Future<TumorAnalysisResult> analyzeImageBytes(Uint8List bytes);
  
  /// Release all model resources.
  void dispose();
  
  /// Whether the pipeline is initialized and ready.
  bool get isInitialized;
}

/// Result from complete tumor analysis pipeline.
class TumorAnalysisResult {
  final int totalDetected;
  final List<DetectedTumor> tumors;
  final double processingTimeMs;
  
  TumorAnalysisResult({
    required this.totalDetected,
    required this.tumors,
    required this.processingTimeMs,
  });
}

/// Individual tumor detection and classification result.
class DetectedTumor {
  final int index;
  final double x;
  final double y;
  final double width;
  final double height;
  final double detectionConfidence;
  final String classification;
  final double classificationConfidence;
  final Map<String, double> classScores;
  final img.Image? heatmapImage;
  final img.Image? originalRegion;
  
  DetectedTumor({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.detectionConfidence,
    required this.classification,
    required this.classificationConfidence,
    required this.classScores,
    this.heatmapImage,
    this.originalRegion,
  });
  
  /// Get bounding box as [x1, y1, x2, y2]
  List<double> get bbox => [
    x - width / 2,
    y - height / 2,
    x + width / 2,
    y + height / 2,
  ];
}

/// Interface for TFLite model interpreter.
/// 
/// Low-level model loading and execution wrapper.
abstract class IModelInterpreter {
  /// Load model from asset path.
  /// 
  /// Throws [ModelInitializationException] if loading fails.
  Future<void> loadModel();
  
  /// Run inference with single input/output.
  /// 
  /// Throws [StateError] if model not loaded.
  void run(Object input, Object output);
  
  /// Run inference with multiple inputs/outputs.
  /// 
  /// Throws [StateError] if model not loaded.
  void runForMultipleInputs(List<Object> inputs, Map<int, Object> outputs);
  
  /// Get input tensor shape.
  List<int> getInputShape();
  
  /// Get output tensor shape.
  List<int> getOutputShape();
  
  /// Release model resources.
  void close();
}

// ============================================================================
// Database Service Interfaces
// ============================================================================

/// Interface for database operations.
/// 
/// Abstracts Firebase Firestore or other database implementations.
abstract class IDatabaseService {
  /// Create a new user document.
  Future<void> createUser(String uid, Map<String, dynamic> userData);
  
  /// Get user data by UID.
  Future<Map<String, dynamic>?> getUserData(String uid);
  
  /// Update user data.
  Future<void> updateUserData(String uid, Map<String, dynamic> data);
  
  /// Save analysis result.
  Future<String> saveAnalysisResult(String userId, Map<String, dynamic> result);
  
  /// Get analysis history for user.
  Future<List<Map<String, dynamic>>> getAnalysisHistory(String userId, {int? limit});
  
  /// Delete analysis result.
  Future<void> deleteAnalysisResult(String userId, String analysisId);
}

// ============================================================================
// Authentication Service Interfaces
// ============================================================================

/// Interface for authentication operations.
/// 
/// Abstracts Firebase Auth or other authentication providers.
abstract class IAuthenticationService {
  /// Sign in with email and password.
  Future<String> signInWithEmail(String email, String password);
  
  /// Register new user with email and password.
  Future<String> registerWithEmail(String email, String password);
  
  /// Sign in with Google.
  Future<String> signInWithGoogle();
  
  /// Sign out current user.
  Future<void> signOut();
  
  /// Get current user ID.
  String? getCurrentUserId();
  
  /// Stream of authentication state changes.
  Stream<String?> get authStateChanges;
}
