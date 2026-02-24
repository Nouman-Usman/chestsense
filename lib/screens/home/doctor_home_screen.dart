import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../doctor/xray_doctor_screen.dart';
import '../shared/profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});
  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = AppColors.doctorPrimary;

  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goToAnalyze() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const XrayDoctorScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _goToProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => const ProfileScreen(),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<FirebaseAuthService>();
    final name = auth.currentUser?.displayName ?? 'Doctor';
    final firstName = name.split(' ').last;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    const AppLogoMark(size: 36, color: _accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good morning,', style: AppText.caption),
                          Text('Dr. $firstName',
                              style: AppText.headingMd,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _accent.withValues(alpha: 0.35),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: _accent, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Hero CTA ─────────────────────────────────────────────────
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _HeroCta(accent: _accent, onTap: _goToAnalyze),
                ),
              ),
              const SizedBox(height: 28),

              // ── AI Analyses section ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent AI Analyses', style: AppText.headingMd),
                      Text(
                        'view all',
                        style: AppText.caption
                            .copyWith(color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Analyses stream ─────────────────────────────────────────────
              Expanded(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('analyses')
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _accent));
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return const _EmptyAnalyses();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _AnalysisCard(data: docs[i].data(), accent: _accent),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAnalyze,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.biotech_outlined, size: 20),
        label: const Text('New Analysis',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Hero CTA Card ────────────────────────────────────────────────────────────

class _HeroCta extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _HeroCta({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xxl),
                      border:
                          Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'ADVANCED AI',
                      style: AppText.eyebrow.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Analyze X-Rays\nwith Heatmaps',
                    style: AppText.displayMd,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a chest X-ray to get AI diagnosis\nwith visual heatmap overlay.',
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.xxl),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.biotech_outlined,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Analyze Now',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(Icons.analytics_outlined,
                  size: 38, color: accent.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analysis Card ────────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color accent;
  const _AnalysisCard({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final diagnosis  = data['diagnosis'] as String? ?? 'Unknown';
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
    final pct        = (confidence * 100).toStringAsFixed(0);
    final ts         = data['createdAt'] as Timestamp?;
    final dateStr    = ts != null ? _formatDate(ts.toDate()) : '—';

    final isNormal  = diagnosis.toLowerCase().contains('normal');
    final diagColor = isNormal ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: diagColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: diagColor.withValues(alpha: 0.25)),
          ),
          child: Icon(
            isNormal
                ? Icons.verified_user_outlined
                : Icons.warning_rounded,
            color: diagColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(diagnosis,
                  style: AppText.headingMd
                      .copyWith(color: diagColor, fontSize: 15),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(dateStr, style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$pct%',
                style: AppText.headingMd.copyWith(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Text('confidence', style: AppText.caption),
          ],
        ),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyAnalyses extends StatelessWidget {
  const _EmptyAnalyses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: 64,
                color: AppColors.doctorPrimary
                    .withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text('No analyses yet',
                style: AppText.headingMd
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Start analyzing X-rays to see results here.',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
