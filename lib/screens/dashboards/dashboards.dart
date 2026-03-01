import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../theme/app_theme.dart';
import '../scan/ct_scan_analysis_screen.dart';

// ─────────────────────────── PATIENT DASHBOARD ────────────────────────────────

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with TickerProviderStateMixin {
  static const _accent = AppColors.patientPrimary;
  static const _accentLight = AppColors.patientLight;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  late AnimationController _heroCtrl;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final auth = context.read<FirebaseAuthService>();
      final db = context.read<FirebaseDbService>();
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final data = await db.getUserData(uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _loading = false;
          });
          _fadeCtrl.forward();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<FirebaseAuthService>();
    await auth.signOut();
  }

  String get _displayName =>
      _userData?['displayName'] as String? ?? 'Patient';

  String get _email => _userData?['email'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const _LoadingBody(accent: _accent)
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildAnalyzeHero(),
                          const SizedBox(height: 28),
                          _buildHealthTips(),
                          const SizedBox(height: 28),
                          _buildRecentScans(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final pct = ((constraints.maxHeight - 60) / (200 - 60)).clamp(0.0, 1.0);
          final collapsed = pct < 0.3;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A1A28),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_accent, _accentLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _displayName.isNotEmpty
                                    ? _displayName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GreetingText(name: _displayName),
                                const SizedBox(height: 3),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Menu
                          PopupMenuButton<String>(
                            color: AppColors.surfaceAlt,
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColors.textSecondary),
                            onSelected: (v) {
                              if (v == 'signout') _signOut();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'signout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    SizedBox(width: 8),
                                    Text('Sign Out',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Portal badge
                      PortalBadge(
                        label: 'PATIENT PORTAL',
                        icon: Icons.person_outline_rounded,
                        accent: _accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: collapsed
                ? Row(
                    children: [
                      const AppLogoMark(size: 28, color: _accent),
                      const SizedBox(width: 10),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
            child: _MiniStatCard(
          label: 'Total Scans',
          value: '0',
          icon: Icons.document_scanner_outlined,
          accent: _accent,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _MiniStatCard(
          label: 'This Month',
          value: '0',
          icon: Icons.calendar_today_outlined,
          accent: _accentLight,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _MiniStatCard(
          label: 'Status',
          value: 'OK',
          icon: Icons.favorite_outline_rounded,
          accent: AppColors.success,
        )),
      ],
    );
  }

  // ── Analyze Hero ───────────────────────────────────────────────────────────
  Widget _buildAnalyzeHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2C2A),
            Color(0xFF0A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border:
            Border.all(color: _accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.biotech_rounded,
                      size: 32, color: _accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AI-POWERED',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _accentLight,
                                letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI Powered Chest\nCancer Detection',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Upload a chest X-ray for instant\nAI-powered cancer screening',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Start Scan button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CTScanAnalysisScreen(
                    userRole: 'patient',
                    displayName: _displayName,
                  ),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accent, _accentLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner_rounded,
                        size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Start Scan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Health Tips ────────────────────────────────────────────────────────────
  Widget _buildHealthTips() {
    final tips = [
      (Icons.air_rounded, 'Lung Health',
          'Regular screening can catch nodules early, improving outcomes.'),
      (Icons.health_and_safety_outlined, 'When to Scan',
          'Low-dose CT is recommended for high-risk adults aged 50–80.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Health Insights', accent: _accent),
        const SizedBox(height: 12),
        ...tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InfoTile(
                icon: t.$1,
                title: t.$2,
                body: t.$3,
                accent: _accent,
              ),
            )),
      ],
    );
  }

  // ── Recent Scans ───────────────────────────────────────────────────────────
  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Recent Scans', accent: _accent),
        const SizedBox(height: 12),
        _EmptyHistoryCard(
          accent: _accent,
          message: 'No scans yet. Run your first CT-SCAN analysis.',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CTScanAnalysisScreen(
                userRole: 'patient',
                displayName: _displayName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── DOCTOR DASHBOARD ─────────────────────────────────

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with TickerProviderStateMixin {
  static const _accent = AppColors.doctorPrimary;
  static const _accentLight = AppColors.doctorLight;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final auth = context.read<FirebaseAuthService>();
      final db = context.read<FirebaseDbService>();
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        final data = await db.getUserData(uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _loading = false;
          });
          _fadeCtrl.forward();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<FirebaseAuthService>();
    await auth.signOut();
  }

  String get _displayName =>
      _userData?['displayName'] as String? ?? 'Doctor';
  String get _email => _userData?['email'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const _LoadingBody(accent: _accent)
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildStatsGrid(),
                          const SizedBox(height: 28),
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildAnalyzeHero(),
                          const SizedBox(height: 28),
                          _buildRecentAnalyses(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Sliver AppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 210,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final pct = ((constraints.maxHeight - 60) / (210 - 60)).clamp(0.0, 1.0);
          final collapsed = pct < 0.3;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF080F1F),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with shield
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_accent, _accentLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _displayName.isNotEmpty
                                        ? _displayName[0].toUpperCase()
                                        : 'D',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.bg, width: 2),
                                  ),
                                  child: const Icon(Icons.verified_rounded,
                                      size: 8, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back,',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    )),
                                const SizedBox(height: 2),
                                Text(
                                  'Dr. $_displayName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: AppColors.surfaceAlt,
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 20,
                                color: AppColors.textSecondary),
                            onSelected: (v) {
                              if (v == 'signout') _signOut();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'signout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    SizedBox(width: 8),
                                    Text('Sign Out',
                                        style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      PortalBadge(
                        label: 'PHYSICIAN PORTAL',
                        icon: Icons.medical_services_outlined,
                        accent: _accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: collapsed
                ? Row(
                    children: [
                      const AppLogoMark(size: 28, color: _accent),
                      const SizedBox(width: 10),
                      Text(
                        'Dr. $_displayName',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Stats Grid ─────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: const [
        _StatCard(
          label: 'Total Analyses',
          value: '0',
          icon: Icons.analytics_outlined,
          accent: _accent,
          trend: null,
        ),
        _StatCard(
          label: 'This Month',
          value: '0',
          icon: Icons.calendar_month_outlined,
          accent: _accentLight,
          trend: null,
        ),
        _StatCard(
          label: 'Malignant Found',
          value: '0',
          icon: Icons.warning_amber_outlined,
          accent: AppColors.error,
          trend: null,
        ),
        _StatCard(
          label: 'Benign Found',
          value: '0',
          icon: Icons.check_circle_outline_rounded,
          accent: AppColors.success,
          trend: null,
        ),
      ],
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Quick Actions', accent: _accent),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.biotech_rounded,
                label: 'New Analysis',
                accent: _accent,
                onTap: () => _openAnalysis(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.folder_open_outlined,
                label: 'LIDC-IDRI',
                accent: AppColors.textMuted,
                onTap: () => _openAnalysis(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                accent: AppColors.textMuted,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CTScanAnalysisScreen(
          userRole: 'doctor',
          displayName: _displayName,
        ),
      ),
    );
  }

  // ── Analyze Hero ───────────────────────────────────────────────────────────
  Widget _buildAnalyzeHero() {
    return GestureDetector(
      onTap: _openAnalysis,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A1228),
              Color(0xFF0C1D35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
              color: _accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    size: 34, color: _accent),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('CLINICAL AI',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _accentLight,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 8),
                    const Text('New CT-SCAN\nAnalysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        )),
                    const SizedBox(height: 6),
                    const Text(
                        'YOLO + DenseNet pipeline for nodule detection & classification',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: _accentLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent Analyses ────────────────────────────────────────────────────────
  Widget _buildRecentAnalyses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Recent Analyses', accent: _accent),
        const SizedBox(height: 12),
        _EmptyHistoryCard(
          accent: _accent,
          message:
              'No analyses yet. Start a new CT-SCAN analysis to begin.',
          onAction: _openAnalysis,
        ),
      ],
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ───────────────────────────────────

class _LoadingBody extends StatelessWidget {
  final Color accent;
  const _LoadingBody({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
          const SizedBox(height: 16),
          const Text('Loading your dashboard…',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;
  const _SectionHeader({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accent)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? trend;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: accent)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _QuickAction({
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  final Color accent;
  final String message;
  final VoidCallback onAction;

  const _EmptyHistoryCard({
    required this.accent,
    required this.message,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded,
                size: 28, color: accent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 14),
          Text(message,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text('Start Analysis',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  final String name;
  const _GreetingText({required this.name});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting(),
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 1),
        Text(name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
