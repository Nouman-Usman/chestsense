import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'doctor_login_screen.dart';
import 'patient_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text('Who are you?', style: AppText.displayMd),
                        const SizedBox(height: 10),
                        Text('Select your role to access your personalised\nclinical dashboard.', style: AppText.bodyLg),
                        const SizedBox(height: 44),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: _RoleCard(
                            icon: Icons.local_hospital_outlined,
                            role: 'Doctor',
                            badge: 'CLINICIAN PORTAL',
                            subtitle: 'Access patient records, ECG analytics, diagnostic\ntools and clinical workflows.',
                            accent: AppColors.doctorPrimary,
                            glow: AppColors.doctorGlow,
                            onTap: () => Navigator.of(context).push(_slideRoute(const DoctorLoginScreen())),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 200),
                          child: _RoleCard(
                            icon: Icons.person_outline_rounded,
                            role: 'Patient',
                            badge: 'PATIENT PORTAL',
                            subtitle: 'Monitor your vitals, review test results and\ncommunicate with your care team.',
                            accent: AppColors.patientPrimary,
                            glow: AppColors.patientGlow,
                            onTap: () => Navigator.of(context).push(_slideRoute(const PatientLoginScreen())),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Center(
                    child: Text('Secure login  ·  AES-256 encryption', style: AppText.caption),
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

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String role, badge, subtitle;
  final Color accent, glow;
  final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.role, required this.badge, required this.subtitle, required this.accent, required this.glow, required this.onTap});
  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _hover;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.977).animate(
        CurvedAnimation(parent: _hover, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _hover.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (d) => _hover.forward(),
        onTapUp: (d) { _hover.reverse(); widget.onTap(); },
        onTapCancel: () => _hover.reverse(),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: widget.glow, blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 26),
                  ),
                  PortalBadge(label: widget.badge, icon: Icons.shield_outlined, accent: widget.accent),
                ],
              ),
              const SizedBox(height: 18),
              Text(widget.role, style: AppText.headingLg.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text(widget.subtitle, style: AppText.bodySm.copyWith(height: 1.65)),
              const SizedBox(height: 20),
              Row(children: [
                Text('Sign in', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.accent)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16, color: widget.accent),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

Route<void> _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, anim, secondary, child) {
      final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
