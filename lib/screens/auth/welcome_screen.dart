import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Ambient glow top-right
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.25,
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.doctorPrimary.withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Ambient glow bottom-left
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.patientPrimary.withValues(alpha: 0.09),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const AppLogoMark(size: 56, color: AppColors.doctorPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _logoFade,
                    child: Text(
                      'ChestSense',
                      style: AppText.label.copyWith(
                          color: AppColors.textSecondary, letterSpacing: 1.8, fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  // Main content
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced\nCardiac Care.',
                            style: AppText.displayLg.copyWith(fontSize: 42),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A clinical-grade platform connecting\ncardiologists and patients through\nreal-time monitoring and diagnostics.',
                            style: AppText.bodyLg,
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              _FeatureChip(label: 'HIPAA Compliant', icon: Icons.verified_user_outlined),
                              _FeatureChip(label: 'End-to-End Encrypted', icon: Icons.lock_outline_rounded),
                              _FeatureChip(label: 'Real-Time ECG', icon: Icons.monitor_heart_outlined),
                            ],
                          ),
                          const SizedBox(height: 40),
                          PrimaryButton(
                            label: 'Get Started',
                            trailingIcon: Icons.arrow_forward_rounded,
                            onPressed: () => Navigator.of(context).push(_fadeRoute(const RoleSelectionScreen())),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Trusted by 2,400+ clinicians worldwide',
                              style: AppText.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.doctorPrimary),
          const SizedBox(width: 7),
          Text(label, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

Route<void> _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
}
