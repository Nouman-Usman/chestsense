import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/service_locator.dart';
import '../../core/service_interfaces.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_with_bounding_boxes.dart';

// ─────────────────────────── CT-SCAN ANALYSIS SCREEN ───────────────────────────

class CTScanAnalysisScreen extends StatefulWidget {
  final String userRole; // 'doctor' | 'patient'
  final String displayName;

  const CTScanAnalysisScreen({
    super.key,
    required this.userRole,
    required this.displayName,
  });

  @override
  State<CTScanAnalysisScreen> createState() => _CTScanAnalysisScreenState();
}

class _CTScanAnalysisScreenState extends State<CTScanAnalysisScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  IMLPipelineService? _pipeline;

  bool _pipelineReady = false;
  bool _isAnalyzing = false;
  String? _initError;

  // Source selection
  _SourceMode _mode = _SourceMode.none;

  // Sample images
  List<String> _samplePaths = [];
  String? _selectedSamplePath;

  // Selected bytes (whichever path was chosen)
  Uint8List? _selectedBytes;
  ui.Image? _decodedImage;
  String _selectedLabel = '';

  // Result
  TumorAnalysisResult? _result;
  String? _analysisError;

  Color get _accent => widget.userRole == 'doctor'
      ? AppColors.doctorPrimary
      : AppColors.patientPrimary;

  @override
  void initState() {
    super.initState();
    _initPipeline();
    _loadSampleManifest();
  }

  @override
  void dispose() {
    _pipeline?.dispose();
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _initPipeline() async {
    try {
      final p = getService<IMLPipelineService>();
      await p.initialize();
      if (mounted) {
        _pipeline = p;
        setState(() => _pipelineReady = true);
      } else {
        p.dispose();
      }
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  Future<void> _loadSampleManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest
          .listAssets()
          .where((k) => k.startsWith('test-images/') && k.endsWith('.png'))
          .toList()
        ..sort();
      if (mounted) setState(() => _samplePaths = keys);
    } catch (_) {}
  }

  // ── Image selection ────────────────────────────────────────────────────────
  void _selectSample(int index) async {
    final path = _samplePaths[index];
    try {
      final bytes = await rootBundle.load(path);
      setState(() {
        _selectedSamplePath = path;
        _selectedBytes = bytes.buffer.asUint8List();
        _selectedLabel = 'CT Sample ${index + 1}';
        _result = null;
        _analysisError = null;
      });
    } catch (e) {
      _showSnack('Failed to load sample: $e');
    }
  }

  Future<void> _pickFromDevice() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      setState(() {
        _selectedBytes = bytes;
        _selectedLabel = xFile.name;
        _selectedSamplePath = null;
        _result = null;
        _analysisError = null;
      });
    } catch (e) {
      _showSnack('Failed to pick image: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera);
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      setState(() {
        _selectedBytes = bytes;
        _selectedLabel = xFile.name;
        _selectedSamplePath = null;
        _result = null;
        _analysisError = null;
      });
    } catch (e) {
      _showSnack('Failed to capture image: $e');
    }
  }

  // ── Analysis ───────────────────────────────────────────────────────────────
  Future<void> _analyze() async {
    if (_selectedBytes == null) {
      _showSnack('Please select an image first');
      return;
    }
    if (!_pipelineReady || _pipeline == null) {
      _showSnack('Models are still loading…');
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _result = null;
      _analysisError = null;
      _decodedImage = null;
    });
    try {
      // Run analysis
      final result = await _pipeline!.analyzeImageBytes(_selectedBytes!);
      
      // Decode image for display with bounding boxes
      final codec = await ui.instantiateImageCodec(_selectedBytes!);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      
      if (mounted) {
        setState(() {
          _result = result;
          _decodedImage = uiImage;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _analysisError = e.toString());
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────── BUILD ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.biotech_rounded, size: 18, color: _accent),
          ),
          const SizedBox(width: 10),
          const Text('CT-SCAN Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
        ],
      ),
      actions: [
        // Pipeline status indicator
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _pipelineReady
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Ready',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                  ],
                )
              : _initError != null
                  ? const Icon(Icons.error_outline_rounded,
                      size: 18, color: AppColors.error)
                  : const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                      ),
                    ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          // ── Source selection ────────────────────────────────────────────
          if (_mode == _SourceMode.none) ...[
            _sectionLabel('SELECT IMAGE SOURCE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SourceCard(
                    icon: Icons.collections_rounded,
                    title: 'Sample Library',
                    subtitle: '${_samplePaths.length} CT scans',
                    accent: _accent,
                    onTap: () => setState(() => _mode = _SourceMode.sample),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Import from Device',
                    subtitle: 'Gallery / Files',
                    accent: _accent,
                    onTap: () {
                      setState(() => _mode = _SourceMode.device);
                      _pickFromDevice();
                    },
                  ),
                ),
              ],
            ),
          ],

          // ── Sample library grid ─────────────────────────────────────────
          if (_mode == _SourceMode.sample) ...[
            _sectionLabelWithBack('SAMPLE LIBRARY', () {
              setState(() {
                _mode = _SourceMode.none;
                _selectedSamplePath = null;
                _selectedBytes = null;
                _result = null;
              });
            }),
            const SizedBox(height: 12),
            _buildSampleGrid(),
          ],

          // ── Device mode (just shows pick again button if no image yet) ──
          if (_mode == _SourceMode.device && _selectedBytes == null) ...[
            _sectionLabelWithBack('DEVICE IMPORT', () {
              setState(() {
                _mode = _SourceMode.none;
                _selectedBytes = null;
                _result = null;
              });
            }),
            const SizedBox(height: 12),
            _PickerPromptCard(
              accent: _accent,
              onGallery: _pickFromDevice,
              onCamera: _pickFromCamera,
            ),
          ],

          const SizedBox(height: 20),

          // ── Selected image preview ──────────────────────────────────────
          if (_selectedBytes != null) ...[
            _sectionLabel('SELECTED IMAGE'),
            const SizedBox(height: 12),
            _ImagePreviewCard(
              bytes: _selectedBytes!,
              label: _selectedLabel,
              accent: _accent,
              onClear: () => setState(() {
                _selectedBytes = null;
                _selectedSamplePath = null;
                _result = null;
                _analysisError = null;
              }),
              onReplace: _mode == _SourceMode.device
                  ? _pickFromDevice
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Analyze button ────────────────────────────────────────────
            _AnalyzeButton(
              label: _isAnalyzing ? 'Analyzing with AI...' : 'Run Analysis',
              isLoading: _isAnalyzing,
              isReady: _pipelineReady && !_isAnalyzing,
              accent: _accent,
              onTap: _analyze,
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.biotech, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Running YOLO + DenseNet models...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],

          // ── Results ─────────────────────────────────────────────────────
          if (_analysisError != null)
            _ErrorCard(message: _analysisError!),

          if (_result != null) ...[
            _sectionLabel('ANALYSIS RESULTS'),
            const SizedBox(height: 12),
            _ResultsPanel(
              result: _result!,
              accent: _accent,
              decodedImage: _decodedImage,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _accent,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _sectionLabelWithBack(String text, VoidCallback onBack) {
    return Row(
      children: [
        Expanded(child: _sectionLabel(text)),
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text('Change',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSampleGrid() {
    if (_samplePaths.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _samplePaths.length,
      itemBuilder: (context, i) {
        final selected = _samplePaths[i] == _selectedSamplePath;
        return GestureDetector(
          onTap: () => _selectSample(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? _accent : AppColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: _accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  selected ? AppRadius.md - 2 : AppRadius.md - 1),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _samplePaths[i],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textMuted, size: 28),
                      ),
                    ),
                  ),
                  // Bottom label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        'CT-${i + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Selected checkmark
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper functions for classification colors and names
  static Color _getColorForClassification(String classification) {
    final lower = classification.toLowerCase();
    if (lower.contains('adenocarcinoma') || lower.contains('class a')) {
      return const Color(0xFFE53935); // Bright red - most serious
    } else if (lower.contains('small cell') || lower.contains('class b')) {
      return const Color(0xFF8E24AA); // Purple - distinct from others
    } else if (lower.contains('large cell') || lower.contains('class e')) {
      return const Color(0xFF00897B); // Teal - cool color for contrast
    } else if (lower.contains('squamous') || lower.contains('class g')) {
      return const Color(0xFFFB8C00); // Deep orange - warm but distinct
    }
    return Colors.blue;
  }

  static String _getShortClassName(String classification) {
    if (classification.contains('Adenocarcinoma')) return 'Adeno';
    if (classification.contains('Small Cell')) return 'Small Cell';
    if (classification.contains('Large Cell')) return 'Large Cell';
    if (classification.contains('Squamous')) return 'Squamous';
    return classification;
  }
}

// ─────────────────────────── ENUM ─────────────────────────────────────────────

enum _SourceMode { none, sample, device }

// ─────────────────────────── SUB-WIDGETS ──────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashColor: accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Select',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      )),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerPromptCard extends StatelessWidget {
  final Color accent;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _PickerPromptCard({
    required this.accent,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Dotted upload zone ──
        GestureDetector(
          onTap: onGallery,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: accent.withValues(alpha: 0.55),
              borderRadius: AppRadius.xl,
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 1.5),
                    ),
                    child: Icon(Icons.cloud_upload_outlined,
                        size: 34, color: accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to select CT scan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'JPG/PNG  ·  Max 10 MB',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // ── Gallery / Camera buttons ──
        Row(
          children: [
            Expanded(
              child: _PickerButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                accent: accent,
                onTap: onGallery,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                accent: accent,
                onTap: onCamera,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Picker secondary button ───────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashColor: accent.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 9.0;
    const dashSpace = 6.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}

class _ImagePreviewCard extends StatelessWidget {
  final Uint8List bytes;
  final String label;
  final Color accent;
  final VoidCallback onClear;
  final VoidCallback? onReplace;

  const _ImagePreviewCard({
    required this.bytes,
    required this.label,
    required this.accent,
    required this.onClear,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl - 1),
            ),
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Image.memory(
                    bytes,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: AppColors.surfaceAlt,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.textMuted, size: 40),
                      ),
                    ),
                  ),
                ),
                // Top-right close button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.image_rounded, size: 14, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onReplace != null)
                  GestureDetector(
                    onTap: onReplace,
                    child: Text('Replace',
                        style: TextStyle(
                            fontSize: 11,
                            color: accent,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final bool isReady;
  final Color accent;
  final VoidCallback onTap;

  const _AnalyzeButton({
    required this.label,
    required this.isLoading,
    required this.isReady,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<_AnalyzeButton> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isReady ? widget.onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: widget.isReady
                  ? LinearGradient(
                      colors: [
                        widget.accent,
                        widget.accent.withValues(alpha: 0.85)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isReady ? null : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: widget.isReady
                  ? [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: widget.isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                            strokeCap: StrokeCap.round,
                          ),
                        )
                      : Icon(
                          Icons.biotech_rounded,
                          key: const ValueKey('ready'),
                          size: 22,
                          color: widget.isReady
                              ? Colors.white
                              : AppColors.textMuted,
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isReady ? Colors.white : AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  final TumorAnalysisResult result;
  final Color accent;
  final ui.Image? decodedImage;

  const _ResultsPanel({
    required this.result,
    required this.accent,
    this.decodedImage,
  });

  @override
  Widget build(BuildContext context) {
    // Group by classification type
    final classificationCounts = <String, int>{};
    for (final tumor in result.tumors) {
      final key = tumor.classification;
      classificationCounts[key] = (classificationCounts[key] ?? 0) + 1;
    }

    return Column(
      children: [
        // Summary stats row
        if (classificationCounts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Total',
                value: '${result.totalDetected}',
                icon: Icons.radar_rounded,
                color: accent,
              ),
              ...classificationCounts.entries.map((entry) {
                final classification = entry.key;
                final count = entry.value;
                final color = _CTScanAnalysisScreenState._getColorForClassification(classification);
                final shortName = _CTScanAnalysisScreenState._getShortClassName(classification);
                
                return _StatChip(
                  label: shortName,
                  value: '$count',
                  icon: Icons.location_on_outlined,
                  color: color,
                );
              }),
            ],
          )
        else
          _StatChip(
            label: 'Detected',
            value: '${result.totalDetected}',
            icon: Icons.radar_rounded,
            color: accent,
          ),
        const SizedBox(height: 8),
        // Time chip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Processed in ${result.processingTimeMs.toStringAsFixed(0)} ms',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Image with heatmap and bounding boxes
        if (decodedImage != null && result.tumors.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.gradient_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Detection Heatmap',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Highlighted regions show tumor locations',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ImageWithBoundingBoxes(
                      image: decodedImage!,
                      detections: result.tumors,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _HeatmapLegendItem(
                      color: Colors.red,
                      label: 'Adenocarcinoma',
                    ),
                    _HeatmapLegendItem(
                      color: Colors.deepOrange,
                      label: 'Small Cell',
                    ),
                    _HeatmapLegendItem(
                      color: Colors.amber.shade700,
                      label: 'Large Cell',
                    ),
                    _HeatmapLegendItem(
                      color: Colors.orange,
                      label: 'Squamous',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // No detections
        if (result.tumors.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 24, color: AppColors.success),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No Nodules Detected',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                      SizedBox(height: 3),
                      Text(
                          'The AI model found no significant nodules in this scan.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Tumor cards
        ...result.tumors.asMap().entries.map((entry) {
          final i = entry.key;
          final tumor = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _TumorCard(index: i, tumor: tumor, accent: accent),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _TumorCard extends StatelessWidget {
  final int index;
  final DetectedTumor tumor;
  final Color accent;

  const _TumorCard(
      {required this.index, required this.tumor, required this.accent});

  @override
  Widget build(BuildContext context) {
    final statusColor = _CTScanAnalysisScreenState._getColorForClassification(tumor.classification);
    final confPct = (tumor.classificationConfidence * 100).clamp(0, 100);
    final detPct = (tumor.detectionConfidence * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NODULE #${index + 1}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.8),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 11,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _CTScanAnalysisScreenState._getShortClassName(tumor.classification),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Confidence bars
          _ConfidenceBar(
            label: 'Classification Confidence',
            value: confPct / 100,
            color: statusColor,
            pctText: '${confPct.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _ConfidenceBar(
            label: 'Detection Confidence',
            value: detPct / 100,
            color: accent,
            pctText: '${detPct.toStringAsFixed(1)}%',
          ),
          // Class scores breakdown if available
          if (tumor.classScores.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tumor.classScores.entries.map((e) {
                final pct = (e.value * 100).clamp(0, 100);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${e.key}: ${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String pctText;

  const _ConfidenceBar({
    required this.label,
    required this.value,
    required this.color,
    required this.pctText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
            Text(pctText,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _HeatmapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _HeatmapLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
