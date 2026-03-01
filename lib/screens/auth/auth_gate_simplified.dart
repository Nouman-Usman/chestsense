import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/app_theme.dart';
import 'welcome_screen.dart';
import '../simple_analyzer_screen.dart';

/// Simple auth gate - just login or go to analyzer
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
    _initFuture = Future.delayed(const Duration(milliseconds: 1000));
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
          return const SimpleAnalyzerScreen();
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

            return const SimpleAnalyzerScreen();
          },
        );
      },
    );
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
