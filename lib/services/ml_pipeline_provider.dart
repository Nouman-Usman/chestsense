/// Provider-based ML Pipeline management
/// Use with `provider` package for reactive state management
library;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../core/service_locator.dart';
import '../core/service_interfaces.dart';

class MLPipelineProvider extends ChangeNotifier {
  late final IMLPipelineService _pipeline;
  
  // State properties
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  String? _error;
  TumorAnalysisResult? _lastResult;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  TumorAnalysisResult? get lastResult => _lastResult;
  
  MLPipelineProvider() {
    // Get pipeline from service locator
    _pipeline = getService<IMLPipelineService>();
  }
  
  /// Initialize the ML pipeline
  Future<void> initialize() async {
    try {
      _error = null;
      _isInitialized = false;
      notifyListeners();
      
      await _pipeline.initialize();
      
      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
      _error = 'Initialization failed: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// Analyze CT slice image
  Future<void> analyzeImage(img.Image image) async {
    if (!_isInitialized) {
      _error = 'Pipeline not initialized';
      notifyListeners();
      return;
    }
    
    try {
      _isAnalyzing = true;
      _error = null;
      notifyListeners();
      
      _lastResult = await _pipeline.analyze(image);
      
      _isAnalyzing = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isAnalyzing = false;
      _error = 'Analysis failed: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  /// Get summary statistics from last analysis
  Map<String, dynamic> getAnalysisSummary() {
    if (_lastResult == null) {
      return {};
    }
    
    // Group by classification type
    final classificationCounts = <String, int>{};
    for (final tumor in _lastResult!.tumors) {
      final key = tumor.classification;
      classificationCounts[key] = (classificationCounts[key] ?? 0) + 1;
    }
    
    final avgDetectionConfidence = _lastResult!.tumors.isNotEmpty
        ? _lastResult!.tumors
            .fold<double>(0, (sum, t) => sum + t.detectionConfidence) /
            _lastResult!.tumors.length
        : 0.0;
    
    final avgClassificationConfidence = _lastResult!.tumors.isNotEmpty
        ? _lastResult!.tumors
            .fold<double>(0, (sum, t) => sum + t.classificationConfidence) /
            _lastResult!.tumors.length
        : 0.0;
    
    return {
      'totalDetected': _lastResult!.totalDetected,
      'classificationCounts': classificationCounts,
      'processingTimeMs': _lastResult!.processingTimeMs,
      'avgDetectionConfidence': avgDetectionConfidence,
      'avgClassificationConfidence': avgClassificationConfidence,
    };
  }
  
  /// Clear last result
  void clearResult() {
    _lastResult = null;
    notifyListeners();
  }
  
  /// Reset error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
  }
}

/// Example usage in a widget:
/// 
/// ```dart
/// class MyAnalysisWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Consumer<MLPipelineProvider>(
///       builder: (context, provider, _) {
///         if (!provider.isInitialized) {
///           return const Text('Pipeline initializing...');
///         }
///         
///         if (provider.isAnalyzing) {
///           return const CircularProgressIndicator();
///         }
///         
///         if (provider.error != null) {
///           return Text('Error: ${provider.error}');
///         }
///         
///         final result = provider.lastResult;
///         if (result == null) {
///           return const Text('No analysis yet');
///         }
///         
///         return Column(
///           children: [
///             Text('Total: ${result.totalDetected}'),
///             Text('Time: ${result.processingTimeMs}ms'),
///           ],
///         );
///       },
///     );
///   }
/// }
/// ```
