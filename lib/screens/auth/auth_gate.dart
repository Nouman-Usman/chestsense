import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import '../home/doctor_home_screen.dart';
import '../home/patient_home_screen.dart';

/// Auth gate widget that routes users based on authentication state
/// - If authenticated: loads user role from Firestore and navigates to home screen
/// - If not authenticated: shows welcome screen
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
    // Give Firebase Auth time to restore persisted session from device storage
    // This is essential for maintaining user sessions between app restarts
    _initFuture = Future.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<FirebaseAuthService>();
    final db = context.read<FirebaseDbService>();

    // Wait for Firebase to check for persisted session
    return FutureBuilder(
      future: _initFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // After init delay, check if user is already logged in (cached locally)
        final cachedUser = auth.currentUser;
        if (cachedUser != null) {
          // User session exists - navigate to home
          return _buildUserHome(db, cachedUser.uid);
        }

        // No cached user - listen to auth state stream for changes
        return StreamBuilder(
          stream: auth.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorScreen('Auth error: ${snapshot.error}');
            }

            final user = snapshot.data;
            if (user == null) {
              // User not logged in
              return const WelcomeScreen();
            }

            // User is logged in - navigate to home
            return _buildUserHome(db, user.uid);
          },
        );
      },
    );
  }

  /// Fetch user role and build appropriate home screen
  Widget _buildUserHome(FirebaseDbService db, String uid) {
    return FutureBuilder<String?>(
      future: _getUserRole(db, uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen('Error: ${snapshot.error}');
        }

        final role = snapshot.data;
        if (role == 'doctor') {
          return const DoctorHomeScreen();
        } else if (role == 'patient') {
          return const PatientHomeScreen();
        }

        // Invalid or missing role
        return const WelcomeScreen();
      },
    );
  }

  /// Fetch user role with timeout
  Future<String?> _getUserRole(FirebaseDbService db, String uid) async {
    try {
      return await db
          .getUserRole(uid)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.patientPrimary),
            ),
            const SizedBox(height: 16),
            Text('Loading ChestSense...',
                style:
                    AppText.caption.copyWith(color: AppColors.textMuted)),
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
              Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text('Oops, something went wrong',
                  style: AppText.label
                      .copyWith(color: Colors.redAccent)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: AppText.caption
                      .copyWith(color: AppColors.textMuted)),
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
