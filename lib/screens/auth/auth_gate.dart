import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import '../dashboards/dashboards.dart';

/// Auth gate with role-based routing
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<FirebaseAuthService>();

    return FutureBuilder(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final cachedUser = auth.currentUser;
        if (cachedUser != null) {
          return _RoleRouter(uid: cachedUser.uid);
        }

        return StreamBuilder(
          stream: auth.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorScreen('Error: ${snapshot.error}');
            }

            final user = snapshot.data;
            if (user == null) {
              return const WelcomeScreen();
            }

            return _RoleRouter(uid: user.uid);
          },
        );
      },
    );
  }

  // ── Loading / Error screens ──────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.patientPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: AppText.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text('Error',
                  style: AppText.label.copyWith(color: Colors.redAccent)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patientPrimary),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.bg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── ROLE ROUTER ──────────────────────────────────────

/// Fetches user role from Firestore then routes to the appropriate dashboard.
class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    try {
      final db = context.read<FirebaseDbService>();
      final data = await db.getUserData(widget.uid);
      if (!mounted) return;
      final role = data?['role'] as String?;
      final dest = role == 'doctor'
          ? const DoctorDashboard()
          : const PatientDashboard();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => dest,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (_) {
      // Fallback to patient dashboard on error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.doctorPrimary),
        ),
      ),
    );
  }
}
