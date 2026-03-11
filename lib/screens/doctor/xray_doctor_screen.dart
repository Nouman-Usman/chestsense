import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/ml_service.dart';

class XrayDoctorScreen extends StatefulWidget {
  const XrayDoctorScreen({super.key});

  @override
  State<XrayDoctorScreen> createState() => _XrayDoctorScreenState();
}

class _XrayDoctorScreenState extends State<XrayDoctorScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = AppColors.doctorPrimary;

  static const List<String> _testImages = [
    'test-images/1.png',
    'test-images/2.png',
    'test-images/3.png',
    'test-images/4.png',
    'test-images/5.png',
    'test-images/6.png',
    'test-images/7.png',
    'test-images/8.png',
    'test-images/9.png',
    'test-images/10.png',
    'test-images/11.png',
    'test-images/12.png',
  ];

  XFile? _xfile;
  Uint8List? _memoryBytes;
  bool _isAsset = false;
  bool _analyzing = false;
  String? _errorMsg;
  String? _statusMsg;
  
  ValidateCTResponse? _validationResult;
  AnalysisResponse? _analysisResult;
  bool _showHeatmap = false;
  bool _showDetections = true;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: src,
      imageQuality: 90,
    );
    if (file == null) return;
    
    setState(() {
      _xfile = file;
      _validationResult = null;
      _analysisResult = null;
      _errorMsg = null;
      _statusMsg = null;
      _showHeatmap = false;
      _isAsset = false;
    });
    if (kIsWeb) {
      _memoryBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  void _showTestPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Testing Sample', style: AppText.headingMd),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: _testImages.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final path = _testImages[index];
                  final name = path.split('/').last;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(path, width: 40, height: 40, fit: BoxFit.cover),
                    ),
                    title: Text(name, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      Navigator.pop(context);
                      final bytes = await rootBundle.load(path);
                      setState(() {
                        _xfile = XFile(path);
                        _memoryBytes = bytes.buffer.asUint8List();
                        _isAsset = true;
                        _validationResult = null;
                        _analysisResult = null;
                        _showHeatmap = false;
                        _errorMsg = null;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeXray() async {
    if (_xfile == null) return;

    final auth    = context.read<FirebaseAuthService>();
    final db      = context.read<FirebaseDbService>();
    final ml      = context.read<MLService>();
    final uid     = auth.currentUser?.uid ?? 'anon';

    setState(() {
      _analyzing = true;
      _errorMsg  = null;
      _statusMsg = 'Validating scan...';
      _analysisResult = null;
    });

    try {
      final dynamic fileArg = (_isAsset || kIsWeb) ? _memoryBytes : io.File(_xfile!.path);
      
      final validation = await ml.validateCT(fileArg);
      if (!validation.isCTScan) {
        setState(() {
          _validationResult = validation;
          _analyzing = false;
        });
        return;
      }

      setState(() => _statusMsg = 'AI analyzing (YOLO + DenseNet)...');
      final result = await ml.analyzeWithBackend(fileArg);

      setState(() { 
        _analyzing = false; 
        _statusMsg = null;
        _analysisResult = result; 
      });

      if (result.isSuccess) {
        // Save to doctor analyses collection
        try {
          await db.saveDoctorAnalysis(
            doctorUid: uid,
            imageUrl: null,
            diagnosis: result.diagnosis,
            confidence: result.confidence,
            classScores: result.detections.isNotEmpty ? result.detections.first.allConfidences : {},
            heatmapUrl: null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Analysis saved successfully'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (saveError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save: $saveError'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        setState(() => _errorMsg = result.errorMessage);
      }
    } catch (e) {
      setState(() {
        _analyzing = false;
        _statusMsg = null;
        _errorMsg  = e.toString();
      });
    }
  }

  Widget _buildImagePanel() {
    final hasResult = _analysisResult?.isSuccess ?? false;
    final hasHeatmap = _analysisResult?.heatmapImage.isNotEmpty ?? false;
    final hasDetections = _analysisResult?.detectionImage.isNotEmpty ?? false;
    final hasPickedImage = _xfile != null;

    if (!hasPickedImage) {
      return _PickArea(onTap: () => _pick(ImageSource.gallery));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasResult)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasDetections) ...[
                   Text('Show Boxes',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
                  Switch(
                    value: _showDetections,
                    activeThumbColor: _accent,
                    onChanged: (v) => setState(() => _showDetections = v),
                  ),
                  const SizedBox(width: 12),
                ],
                if (hasHeatmap) ...[
                  Text('Heatmap',
                      style: AppText.caption
                          .copyWith(color: AppColors.textSecondary)),
                  Switch(
                    value: _showHeatmap,
                    activeThumbColor: _accent,
                    onChanged: (v) => setState(() {
                      _showHeatmap = v;
                      if (v) _showDetections = false;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base image
                (_isAsset || kIsWeb || _memoryBytes != null)
                    ? Image.memory(_memoryBytes!, fit: BoxFit.cover)
                    : Image.file(io.File(_xfile!.path), fit: BoxFit.cover),
                
                // Detection layer (YOLO boxes)
                if (hasDetections && _showDetections)
                  Image.memory(
                    base64Decode(_analysisResult!.detectionImage),
                    fit: BoxFit.cover,
                  ),

                // Heatmap overlay
                if (hasHeatmap)
                  AnimatedOpacity(
                    opacity: _showHeatmap ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Image.memory(
                      base64Decode(_analysisResult!.heatmapImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withAlpha(200),
                      borderRadius:
                          BorderRadius.circular(AppRadius.xxl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                        _showHeatmap && hasHeatmap
                            ? 'Heatmap View'
                            : (_showDetections && hasDetections ? 'Detection View' : 'Original X-Ray'),
                        style: AppText.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(AnalysisResponse res) {
    if (!res.isSuccess) {
      return _ErrorCard(message: res.errorMessage ?? 'Unknown error');
    }

    final diagnosis = res.diagnosis;
    final confidence = res.confidence;
    
    Color diagColor;
    final diagLower = diagnosis.toLowerCase();
    if (diagLower.contains('normal')) {
      diagColor = Colors.greenAccent.shade400;
    } else if (diagLower.contains('adenocarcinoma') || diagLower.contains('small cell')) {
      diagColor = Colors.redAccent;
    } else {
      diagColor = Colors.orangeAccent;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_done_outlined, color: _accent, size: 18),
            const SizedBox(width: 8),
            Text('Diagnostic Report (Cloud AI)',
                style: AppText.label.copyWith(color: _accent)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: diagColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: diagColor.withAlpha(80)),
            ),
            child: Text(diagnosis,
                style: AppText.headingMd.copyWith(color: diagColor)),
          ),
          const SizedBox(height: 16),
          Text('Combined Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
              style:
                  AppText.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(_accent),
            ),
          ),

          if (res.detections.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            Text('Detected Tumors (${res.tumorsDetected})',
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...res.detections.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tumor #${d.tumorId}: ${d.prediction}', 
                          style: AppText.label.copyWith(fontSize: 12)),
                      Text('${d.confidence.toStringAsFixed(1)}%', 
                          style: AppText.caption.copyWith(color: _accent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Small crop preview if needed, but we have detection image above
                ],
              ),
            )),
          ],

          if (res.heatmapImage.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.thermostat_outlined,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Toggle heatmap overlay above to inspect activation regions',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Doctor Analysis',
                                style: AppText.headingMd.copyWith(
                                    color: AppColors.textPrimary)),
                            Text('Cloud YOLO + DenseNet Pipeline',
                                style: AppText.caption.copyWith(
                                    color: AppColors.textMuted)),
                          ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImagePanel(),
                        const SizedBox(height: 14),
                        if (_analysisResult == null)
                          Row(children: [
                            Expanded(
                              child: _SourceBtn(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                accent: _accent,
                                onTap: () => _pick(ImageSource.gallery),
                              ),
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SourceBtn(
                                  icon: Icons.camera_alt_outlined,
                                  label: 'Camera',
                                  accent: _accent,
                                  onTap: () => _pick(ImageSource.camera),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Expanded(child: _SourceBtn(
                              icon: Icons.biotech_outlined,
                              label: 'Samples',
                              accent: Colors.orangeAccent,
                              onTap: _showTestPicker,
                            )),
                          ]),
                        if (_analysisResult != null) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _xfile = null;
                              _memoryBytes = null;
                              _isAsset = false;
                              _validationResult = null;
                              _analysisResult = null;
                              _errorMsg = null;
                              _showHeatmap = false;
                              _statusMsg = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: _accent.withAlpha(100)),
                              foregroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md)),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('New Scan'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_errorMsg != null) _ErrorCard(message: _errorMsg!),
                        if (_analyzing)
                          _StatusTile(
                               icon: Icons.biotech_outlined,
                              label: _statusMsg ?? 'Cloud AI analyzing…',
                              accent: _accent),
                        if (_validationResult != null && !_validationResult!.isCTScan)
                          _ValidationFailedCard(res: _validationResult!),
                        if (_analysisResult != null) ...[
                          const SizedBox(height: 4),
                          _buildResultCard(_analysisResult!),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_analysisResult == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: PrimaryButton(
                      label: 'Start Scanning',
                      color: _accent,
                      isLoading: _analyzing,
                      onPressed: _xfile == null ? null : _analyzeXray,
                      trailingIcon: Icons.biotech_outlined,
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

class _PickArea extends StatelessWidget {
  final VoidCallback onTap;
  const _PickArea({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_outlined,
                size: 48,
                color: AppColors.doctorPrimary.withAlpha(180)),
            const SizedBox(height: 12),
            Text('Tap to select CT image',
                style: AppText.label
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('CT Scan · JPG / PNG',
                style: AppText.caption
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _SourceBtn(
      {required this.icon,
      required this.label,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: BorderSide(color: accent.withAlpha(100)),
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppText.label.copyWith(color: accent)),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _StatusTile(
      {required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: AppText.caption
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.redAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: AppText.caption.copyWith(color: Colors.redAccent)),
        ),
      ]),
    );
  }
}

class _ValidationFailedCard extends StatelessWidget {
  final ValidateCTResponse res;
  const _ValidationFailedCard({required this.res});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Invalid Image Format', style: AppText.headingMd.copyWith(color: Colors.redAccent)),
          const SizedBox(height: 8),
          Text(
            res.message,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Text('The AI pre-validator rejected this scan. Please ensure the image is a grayscale CT scan with minimal artifacts.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
