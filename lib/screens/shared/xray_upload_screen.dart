import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/ml_service.dart';

class XrayUploadScreen extends StatefulWidget {
  const XrayUploadScreen({super.key});

  @override
  State<XrayUploadScreen> createState() => _XrayUploadScreenState();
}

class _XrayUploadScreenState extends State<XrayUploadScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = AppColors.patientPrimary;

  // ── Image state ────────────────────────────────────────────────────────────
  XFile? _xfile;
  Uint8List? _webBytes;

  // ── Flow state ─────────────────────────────────────────────────────────────
  bool _uploading = false;
  bool _analyzing = false;
  bool _useOCR = true; // Toggle for Doctr OCR
  String? _errorMsg;

  // ── Result state ───────────────────────────────────────────────────────────
  CombinedAnalysisResult? _combinedResult;
  String? _imageUrl;

  // ── Animation ──────────────────────────────────────────────────────────────
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

  // ── Pick image ─────────────────────────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: src,
      imageQuality: 90,
    );
    if (file == null) return;
    
    setState(() {
      _xfile = file;
      _combinedResult = null;
      _errorMsg = null;
      _imageUrl = null;
    });
    if (kIsWeb) {
      _webBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  // ── Analyse (Local DenseNet) ─────────────────────────────────────────────
  Future<void> _analyzeXray() async {
    if (_xfile == null) return;

    final auth    = context.read<FirebaseAuthService>();
    final db      = context.read<FirebaseDbService>();
    final ml      = context.read<MLService>();
    final uid     = auth.currentUser?.uid ?? 'anon';

    setState(() {
      _uploading = false; // No longer uploading to cloud
      _analyzing = true;
      _errorMsg  = null;
      _combinedResult = null;
    });

    try {
      final dynamic fileArg = kIsWeb ? _webBytes! : File(_xfile!.path);
      
      // 1. Try Backend AI (Port 5001 - Grad-CAM + Prediction)
      final isHealthy = await ml.checkHealth();
      CombinedAnalysisResult combinedResult;

      if (isHealthy && !kIsWeb) {
        debugPrint('Using Backend AI Analysis...');
        combinedResult = await ml.analyzeWithBackend(File(_xfile!.path));
      } else {
        // 2. Fallback to Local Models (DenseNet)
        debugPrint('Backend offline or Web. Using Local AI...');
        combinedResult = await ml.analyzeChestXray(
          imageFile: fileArg,
          imageWidth: 640,
          imageHeight: 640,
          includeDocumentOCR: _useOCR,
        );
      }

      setState(() { 
        _analyzing = false;
        _combinedResult = combinedResult;
      });

      if (combinedResult.isSuccess) {
        // Persist textual result to DB
        await db.saveAnalysisResult(
          patientUid: uid,
          imageUrl: null, // No cloud URL
          diagnosis: combinedResult.densenetResult?.diagnosis ?? 'Normal / Unclassified',
          confidence: combinedResult.densenetResult?.confidence ?? 0.0,
          classScores: combinedResult.densenetResult?.classScores ?? {},
          heatmapUrl: null,
        );
      } else {
        setState(() => _errorMsg = combinedResult.errorMessage);
      }
    } catch (e) {
      setState(() {
        _analyzing  = false;
        _errorMsg   = e.toString();
      });
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
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
                child: kIsWeb
                    ? Image.memory(_webBytes!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover)
                    : Image.file(File(_xfile!.path),
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
      ],
    );
  }

  Widget _buildStatusRow() {
    if (_uploading) {
      return _StatusTile(
          icon: Icons.cloud_upload_outlined,
          label: 'Uploading image…',
          accent: _accent,
          loading: true);
    }
    if (_analyzing) {
      return _StatusTile(
          icon: Icons.psychology_outlined,
          label: 'AI model analyzing…',
          accent: _accent,
          loading: true);
    }
    return const SizedBox.shrink();
  }



  /// Build combined analysis result card (DenseNet + OCR)
  Widget _buildCombinedResultCard(CombinedAnalysisResult res) {
    if (!res.isSuccess) {
      return _ErrorCard(message: res.errorMessage ?? 'Analysis failed');
    }

    final densenet = res.densenetResult;
    final ocr = res.documentOCR;

    final diagnosis = densenet?.diagnosis ?? 'Normal / Unclassified';
    final confidence = densenet?.confidence ?? 0.0;

    // Determine severity color
    Color severityColor;
    final diagLower = diagnosis.toLowerCase();
    if (diagLower.contains('normal')) {
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
          // Header
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text('AI Health Assessment (Local AI)',
                  style: AppText.label.copyWith(color: _accent)),
            ],
          ),
          const SizedBox(height: 16),

          // Diagnosis Badge
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
          const SizedBox(height: 16),

          // Confidence Info
          Text('AI Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
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

          if (densenet != null && densenet.classScores.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Divider(),
            const SizedBox(height: 12),
            Text('Diagnosis Breakdown',
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...densenet.classScores.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ScoreRow(
                  label: e.key,
                  value: e.value,
                ),
              );
            }),
          ],

          // OCR Results
          if (ocr != null && ocr.charactersCount > 0) ...[
            const SizedBox(height: 16),
            const _Divider(),
            const SizedBox(height: 12),
            Text('Document Recognition',
                style: AppText.caption.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text('Characters: ${ocr.charactersCount}',
                style: AppText.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('OCR Confidence: ${(ocr.confidence * 100).toStringAsFixed(1)}%',
                style: AppText.caption
                    .copyWith(color: AppColors.textSecondary)),
            if (ocr.keywordsDetected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Medical Keywords:',
                  style: AppText.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ocr.keywordsDetected.take(4).map((kw) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withAlpha(15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color: _accent.withAlpha(50), width: 0.5),
                    ),
                    child: Text(kw,
                        style: AppText.caption
                            .copyWith(color: _accent, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ],
          ],

          // Processing Info
          const SizedBox(height: 16),
          const _Divider(),
          const SizedBox(height: 12),
          Text(
            'High-precision DenseNet classification',
            style: AppText.caption
                .copyWith(color: AppColors.textMuted, fontSize: 10),
          ),

          if (_xfile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: res.densenetResult?.heatmapBytes != null
                  ? Image.memory(res.densenetResult!.heatmapBytes!,
                      height: 180, width: double.infinity, fit: BoxFit.cover)
                  : (kIsWeb
                      ? Image.memory(_webBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover)
                      : Image.file(File(_xfile!.path),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover)),
            ),
            if (res.densenetResult?.heatmapBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('✦ Grad-CAM visualization active',
                    style: AppText.caption.copyWith(
                        color: _accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
                // Top bar
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
                            Text('Upload chest X-ray for AI classification',
                                style: AppText.caption
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Body
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
                        if (_combinedResult != null) ...[
                          const SizedBox(height: 8),
                          _buildCombinedResultCard(_combinedResult!),
                        ],
                      ],
                    ),
                  ),
                ),
                // Footer button
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: PrimaryButton(
                    label: 'Analyse X-Ray',
                    color: _accent,
                    isLoading: _uploading || _analyzing,
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

// ── Small helpers ──────────────────────────────────────────────────────────────

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

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;
  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppText.caption
                    .copyWith(color: AppColors.textSecondary)),
            Text('$pct%',
                style: AppText.caption
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.patientPrimary),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: 1);
  }
}
