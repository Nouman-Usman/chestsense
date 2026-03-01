import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import '../services/ml_pipeline_service_tflite.dart';

/// Simple medical image analyzer screen
/// Pick an image → Click Analyze → See disease prediction
class SimpleAnalyzerScreen extends StatefulWidget {
  const SimpleAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<SimpleAnalyzerScreen> createState() => _SimpleAnalyzerScreenState();
}

class _SimpleAnalyzerScreenState extends State<SimpleAnalyzerScreen> {
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

      // Load and decode image
      final bytes = await _selectedImage!.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Run analysis
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
      SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
    );
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _error = null;
    });
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
        title: const Text('🏥 Medical Image Analyzer'),
        centerTitle: true,
        elevation: 0,
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
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing ML models...'),
        ],
      ),
    );
  }

  Widget _buildMainState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Image preview or placeholder
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No image selected',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Image'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedImage == null || _isAnalyzing ? null : _analyzeImage,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
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
            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    '📊 Analysis Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Total Detected',
                    result.totalDetected.toString(),
                    Icons.search,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Malignant',
                    '$malignant',
                    Icons.warning,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Benign',
                    '$benign',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Processing Time',
                    '${result.processingTimeMs.toStringAsFixed(1)}ms',
                    Icons.timer,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed predictions
            if (result.tumors.isNotEmpty) ...[
              const Text(
                'Disease Classifications:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...result.tumors.map((tumor) => _buildTumorCard(tumor)),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✅ No abnormalities detected',
                  style: TextStyle(
                    color: Color.fromARGB(255, 27, 94, 32),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Analyze Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTumorCard(DetectedTumor tumor) {
    final isMalignant = tumor.classification.toLowerCase() == 'malignant';
    final bgColor = isMalignant ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isMalignant ? Colors.red.shade300 : Colors.green.shade300;
    final textColor = isMalignant ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detected Region ${tumor.index}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMalignant ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tumor.classification,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${(tumor.classificationConfidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
          Text(
            'Position: (${tumor.x.toStringAsFixed(0)}, ${tumor.y.toStringAsFixed(0)})',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
