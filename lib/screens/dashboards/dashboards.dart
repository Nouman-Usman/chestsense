import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../theme/app_theme.dart';
import '../scan/ct_scan_analysis_screen.dart';
import '../shared/profile_screen.dart';

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
                          const SizedBox(height: 40),
                          _buildAnalyzeHero(),
                          const SizedBox(height: 24),
                          _buildProfileCard(),
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

  // ── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View and edit your profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
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
                          const SizedBox(height: 40),
                          _buildAnalyzeHero(),
                          const SizedBox(height: 24),
                          _buildProfileCard(),
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

  // ── Profile Card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View and edit your profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
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
