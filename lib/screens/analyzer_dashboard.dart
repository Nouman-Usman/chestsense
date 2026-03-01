import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../services/ml_pipeline_service_tflite.dart';
import '../services/firebase_auth_service.dart';

/// Clean minimalist medical image analyzer dashboard
class AnalyzerDashboard extends StatefulWidget {
  const AnalyzerDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyzerDashboard> createState() => _AnalyzerDashboardState();
}

class _AnalyzerDashboardState extends State<AnalyzerDashboard> {
  late MLPipelineServiceTFLite _pipeline;
  
  File? _selectedImage;
  bool _isInitializing = true;
  bool _isAnalyzing = false;
  String? _error;
  TumorAnalysisResult? _result;
  
  @override
  void initState() {
    super.initState();
    _initializePipeline();
  }

  Future<void> _initializePipeline() async {
    try {
      _pipeline = MLPipelineServiceTFLite();
      await _pipeline.initialize();
      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      final bytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');

      final result = await _pipeline.analyze(image);

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = 'Analysis failed: $e';
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _error = null;
    });
  }

  Future<void> _logout() async {
    final auth = FirebaseAuthService();
    await auth.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _pipeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Image Analyzer'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isInitializing
          ? _buildInitializingState()
          : _result != null
              ? _buildResultState()
              : _buildMainState(),
    );
  }

  Widget _buildInitializingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 24),
          const Text('Initializing ML models...'),
          const SizedBox(height: 8),
          Text(
            'This happens only once',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMainState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload & Analyze',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a medical image to get instant analysis',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Image upload area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select image',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'JPG, PNG supported',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Analyze button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedImage == null || _isAnalyzing
                    ? null
                    : _analyzeImage,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState() {
    final result = _result!;
    final malignant = result.tumors
        .where((t) => t.classification.toLowerCase() == 'malignant')
        .length;
    final benign = result.totalDetected - malignant;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results header
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Statistics grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Detected',
                    value: result.totalDetected.toString(),
                    icon: Icons.search,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'Malignant',
                    value: malignant.toString(),
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Benign',
                    value: benign.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'Time',
                    value: '${result.processingTimeMs.toStringAsFixed(0)}ms',
                    icon: Icons.timer,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Detailed results
            if (result.tumors.isNotEmpty) ...[
              Text(
                'Disease Classifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...result.tumors.map((tumor) => _TumorCard(tumor: tumor)),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No abnormalities detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Analyze Another Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat display card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tumor classification card
class _TumorCard extends StatelessWidget {
  final DetectedTumor tumor;

  const _TumorCard({required this.tumor});

  @override
  Widget build(BuildContext context) {
    final isMalignant = tumor.classification.toLowerCase() == 'malignant';
    final color = isMalignant ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected Region ${tumor.index}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(tumor.classificationConfidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tumor.classification,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
