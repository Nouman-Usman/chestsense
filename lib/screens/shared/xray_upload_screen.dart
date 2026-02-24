import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../services/storage_service.dart';
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
  String? _errorMsg;

  // ── Result state ───────────────────────────────────────────────────────────
  MLResponse? _result;
  String? _imageUrl;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
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
    // Restrict to image files only (JPEG, PNG)
    final file = await picker.pickImage(
      source: src,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (file == null) return;
    
    // Validate file extension
    final ext = file.path.toLowerCase().split('.').last;
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      setState(() => _errorMsg = 'Please select a valid image (JPG or PNG)');
      return;
    }
    
    setState(() {
      _xfile = file;
      _result = null;
      _errorMsg = null;
      _imageUrl = null;
    });
    if (kIsWeb) {
      _webBytes = await file.readAsBytes();
      setState(() {});
    }
  }

  // ── Upload → Analyse ──────────────────────────────────────────────────────
  Future<void> _analyzeXray() async {
    if (_xfile == null) return;

    final auth    = context.read<FirebaseAuthService>();
    final db      = context.read<FirebaseDbService>();
    final storage = context.read<StorageService>();
    final ml      = context.read<MLService>();
    final uid     = auth.currentUser?.uid ?? 'anon';

    setState(() {
      _uploading = true;
      _analyzing = false;
      _errorMsg  = null;
      _result    = null;
    });

    try {
      // 1 – Upload to Firebase Storage
      final dynamic fileArg = kIsWeb ? _webBytes! : File(_xfile!.path);
      final url = await storage.uploadXray(userId: uid, file: fileArg);
      _imageUrl = url;
      setState(() { _uploading = false; _analyzing = true; });

      // 2 – Call ML service
      final response = await ml.analyze(file: fileArg, imageUrl: url);
      setState(() { _analyzing = false; _result = response; });

      if (response.isSuccess) {
        // 3 – Persist result to Firestore
        await db.saveAnalysisResult(
          patientUid: uid,
          imageUrl: url,
          diagnosis: response.diagnosis,
          confidence: response.confidence,
          classScores: response.classScores,
          heatmapUrl: response.heatmapUrl,
        );
      } else {
        setState(() => _errorMsg = response.errorMessage);
      }
    } catch (e) {
      setState(() {
        _uploading  = false;
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

  Widget _buildResultCard(MLResponse res) {
    if (!res.isSuccess) {
      return _ErrorCard(message: res.errorMessage ?? 'Unknown error');
    }

    final pct = (res.confidence * 100).toStringAsFixed(1);
    Color diagColor = res.diagnosis.toLowerCase().contains('normal')
        ? Colors.greenAccent.shade400
        : Colors.orangeAccent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt_rounded, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text('Analysis Complete',
                  style: AppText.label.copyWith(color: _accent)),
            ],
          ),
          const SizedBox(height: 16),
          // Diagnosis badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: diagColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(color: diagColor.withAlpha(80)),
            ),
            child: Text(res.diagnosis,
                style: AppText.headingMd.copyWith(color: diagColor)),
          ),
          const SizedBox(height: 16),
          // Confidence bar
          Text('Confidence: $pct%',
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            child: LinearProgressIndicator(
              value: res.confidence,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(_accent),
            ),
          ),
          if (res.classScores.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Divider(),
            const SizedBox(height: 12),
            Text('Class probabilities',
                style: AppText.caption
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ...res.classScores.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ScoreRow(label: e.key, value: e.value),
                )),
          ],
          if (_imageUrl != null) ...[
            const SizedBox(height: 16),
            const _Divider(),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(_imageUrl!,
                  height: 160, width: double.infinity, fit: BoxFit.cover),
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
                        if (_result != null) ...[
                          const SizedBox(height: 8),
                          _buildResultCard(_result!),
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
