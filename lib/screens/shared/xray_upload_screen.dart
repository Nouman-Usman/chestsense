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

class XrayUploadScreen extends StatefulWidget {
  final String userRole; // 'doctor' or 'patient'
  const XrayUploadScreen({super.key, this.userRole = 'patient'});

  @override
  State<XrayUploadScreen> createState() => _XrayUploadScreenState();
}

class _XrayUploadScreenState extends State<XrayUploadScreen>
    with SingleTickerProviderStateMixin {
  Color get _accent => widget.userRole == 'doctor' 
      ? AppColors.doctorPrimary 
      : AppColors.patientPrimary;

  static const List<String> _testImages = [
    'test-images/Class_A_A0038_1.3.6.1.4.1.14519.5.2.1.6655.2359.200964933229773819858342958376.png',
    'test-images/Class_A_A0112_1.3.6.1.4.1.14519.5.2.1.6655.2359.133514946679481457237095867057.png',
    'test-images/Class_A_A0135_1.3.6.1.4.1.14519.5.2.1.6655.2359.229546735729215903345807275212.png',
    'test-images/Class_B_B0012_1.3.6.1.4.1.14519.5.2.1.6655.2359.251928415045889960528301518132.png',
    'test-images/Class_B_B0019_1.3.6.1.4.1.14519.5.2.1.6655.2359.542688158494865904457546511093.png',
    'test-images/Class_B_B0038_1.3.6.1.4.1.14519.5.2.1.6655.2359.241194015321121397721615046131.png',
    'test-images/Class_E_E0004_1.3.6.1.4.1.14519.5.2.1.6655.2359.258085984221221292325353998664.png',
    'test-images/Class_E_E0004_1.3.6.1.4.1.14519.5.2.1.6655.2359.319078072563246713259486471363.png',
    'test-images/Class_E_E0004_1.3.6.1.4.1.14519.5.2.1.6655.2359.501875774437494706086763872552.png',
    'test-images/Class_G_G0002_1.3.6.1.4.1.14519.5.2.1.6655.2359.250157524168081247720689697171.png',
    'test-images/Class_G_G0048_1.3.6.1.4.1.14519.5.2.1.6655.2359.132679891311395561463279459011.png',
    'test-images/Class_G_G0056_1.3.6.1.4.1.14519.5.2.1.6655.2359.250923355059840684410808786741.png',
  ];

  XFile? _xfile;
  Uint8List? _memoryBytes;
  bool _isAsset = false;

  bool _analyzing = false;
  String? _errorMsg;
  String? _statusMsg;

  ValidateCTResponse? _validationResult;
  AnalysisResponse? _analysisResult;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
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
            Text('Select Test Sample', style: AppText.headingMd),
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
      _statusMsg = 'Validating CT scan...';
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

      setState(() => _statusMsg = 'AI analyzing image...');
      final result = await ml.analyzeWithBackend(fileArg);

      setState(() { 
        _analyzing = false;
        _statusMsg = null;
        _analysisResult = result;
      });

      if (result.isSuccess) {
        await db.saveAnalysisResult(
          patientUid: uid,
          imageUrl: null, 
          diagnosis: result.diagnosis,
          confidence: result.confidence,
          classScores: result.detections.isNotEmpty ? result.detections.first.allConfidences : {},
          heatmapUrl: null,
        );
      } else {
        setState(() => _errorMsg = result.errorMessage);
      }
    } catch (e) {
      setState(() {
        _analyzing  = false;
        _statusMsg  = null;
        _errorMsg   = e.toString();
      });
    }
  }

  Widget _buildPickArea() {
    final hasImage = _xfile != null;
    return GestureDetector(
      onTap: () => _pick(ImageSource.gallery),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: hasImage ? _accent : AppColors.border,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl - 1),
                child: (_isAsset || kIsWeb || _memoryBytes != null)
                    ? Image.memory(_memoryBytes!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover)
                    : Image.file(io.File(_xfile!.path),
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.upload_file_outlined,
                      size: 48, color: _accent.withAlpha(180)),
                  const SizedBox(height: 12),
                  Text('Tap to select chest X-ray',
                      style: AppText.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('JPG / PNG · Max 10 MB',
                      style: AppText.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
      ),
    );
  }

  Widget _buildSourceRow() {
    return Row(
      children: [
        Expanded(child: _SourceBtn(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          accent: _accent,
          onTap: () => _pick(ImageSource.gallery),
        )),
        const SizedBox(width: 12),
        if (!kIsWeb)
          Expanded(child: _SourceBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            accent: _accent,
            onTap: () => _pick(ImageSource.camera),
          )),
        const SizedBox(width: 12),
        Expanded(child: _SourceBtn(
          icon: Icons.biotech_outlined,
          label: 'Test Samples',
          accent: Colors.orangeAccent,
          onTap: _showTestPicker,
        )),
      ],
    );
  }

  Widget _buildStatusRow() {
    if (_analyzing) {
      return _StatusTile(
          icon: Icons.biotech_outlined,
          label: _statusMsg ?? 'Cloud AI analyzing…',
          accent: _accent,
          loading: true);
    }
    return const SizedBox.shrink();
  }

  Widget _buildResultCard(AnalysisResponse res) {
    if (!res.isSuccess) {
      return _ErrorCard(message: res.errorMessage ?? 'Analysis failed');
    }

    final diagnosis = res.diagnosis;
    final confidence = res.confidence;
    final detectionImage = res.detectionImage;
    final heatmapImage = res.heatmapImage;

    // Determine severity color
    Color severityColor;
    final diagLower = diagnosis.toLowerCase();
    if (diagLower.contains('normal') || res.tumorsDetected == 0) {
      severityColor = Colors.greenAccent.shade400;
    } else if (diagLower.contains('adenocarcinoma') || diagLower.contains('small cell')) {
      severityColor = Colors.redAccent;
    } else {
      severityColor = Colors.orangeAccent;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text('Cloud AI Result',
                  style: AppText.label.copyWith(color: _accent)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: severityColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: severityColor.withAlpha(80)),
            ),
            child: Text(
              diagnosis.toUpperCase(),
              style: AppText.headingMd.copyWith(color: severityColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(res.tumorsDetected > 0 
                  ? '${res.tumorsDetected} tumor(s) detected with boxes' 
                  : 'No tumors detected by YOLO',
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          
          if (res.tumorsDetected > 0) ...[
            const SizedBox(height: 16),
            Text('Combined Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: AppText.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: LinearProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(_accent),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          
          // Show detection image for both doctor and patient
          if (detectionImage.isNotEmpty) ...[
            Text('Tumor Detection (YOLO):',
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.memory(base64Decode(detectionImage),
                  width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
          ],

          // Only show heatmap for doctors
          if (widget.userRole == 'doctor' && heatmapImage.isNotEmpty) ...[
            Text('AI Explanation (Grad-CAM):',
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.memory(base64Decode(heatmapImage),
                  width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text('✦ Red areas indicate regions the AI focused on for classification.',
                style: AppText.caption.copyWith(color: _accent, fontSize: 10)),
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
                  child: Row(
                    children: [
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
                            Text('X-Ray Analysis',
                                style: AppText.headingMd
                                    .copyWith(color: AppColors.textPrimary)),
                            Text('AI Classification Pipeline',
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPickArea(),
                        const SizedBox(height: 14),
                        _buildSourceRow(),
                        const SizedBox(height: 24),
                        if (_errorMsg != null)
                          _ErrorCard(message: _errorMsg!),
                        _buildStatusRow(),
                        if (_validationResult != null && !_validationResult!.isCTScan)
                          _ValidationFailedCard(res: _validationResult!),
                        if (_analysisResult != null) ...[
                          const SizedBox(height: 8),
                          _buildResultCard(_analysisResult!),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: PrimaryButton(
                    label: 'Start Analysis',
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
  final bool loading;
  const _StatusTile(
      {required this.icon,
      required this.label,
      required this.accent,
      required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, valueColor: AlwaysStoppedAnimation(accent)),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
        ],
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.redAccent.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppText.caption.copyWith(color: Colors.redAccent)),
          ),
        ],
      ),
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
          Text('Invalid Scan Image', style: AppText.headingMd.copyWith(color: Colors.redAccent)),
          const SizedBox(height: 8),
          Text(
            res.message,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Text('Please upload a valid grayscale CT-Scan (DICOM/JPG/PNG). The AI detected excessive color or non-medical patterns.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
