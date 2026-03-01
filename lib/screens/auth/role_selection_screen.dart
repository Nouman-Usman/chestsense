import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'patient_login_screen.dart';
import 'doctor_login_screen.dart';

/// Who are you? – choose between Doctor and Patient portals.
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
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          // Ambient glow – blue top right
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.doctorPrimary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          // Ambient glow – teal bottom left
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.patientPrimary.withValues(alpha: 0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // Back button
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: AppColors.textSecondary),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(
                                    color: AppColors.border),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Header
                            _HeaderSection(),
                            const SizedBox(height: 44),
                            // Doctor card
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 80),
                              child: _PortalCard(
                                icon: Icons.local_hospital_outlined,
                                title: 'Doctor',
                                subtitle: 'Clinician Portal',
                                description:
                                    'Access diagnostic tools, review patient\nanalyses, and leverage AI-powered imaging.',
                                accent: AppColors.doctorPrimary,
                                glow: AppColors.doctorGlow,
                                featureLabel: 'HIPAA CERTIFIED',
                                featureIcon: Icons.verified_rounded,
                                onTap: () => Navigator.of(context).push(
                                    _slideRoute(const DoctorLoginScreen())),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Patient card
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 180),
                              child: _PortalCard(
                                icon: Icons.person_outline_rounded,
                                title: 'Patient',
                                subtitle: 'Patient Portal',
                                description:
                                    'Upload chest X-rays, get AI-powered\ndiagnosis results and manage your health.',
                                accent: AppColors.patientPrimary,
                                glow: AppColors.patientGlow,
                                featureLabel: 'END-TO-END ENCRYPTED',
                                featureIcon: Icons.lock_outline_rounded,
                                onTap: () => Navigator.of(context).push(
                                    _slideRoute(
                                        const PatientLoginScreen())),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Center(
                        child: Text(
                          'Trusted by 2,400+ clinicians worldwide',
                          style: AppText.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow pill
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.doctorPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: AppColors.doctorPrimary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.waving_hand_rounded,
                  size: 13, color: AppColors.doctorPrimary),
              const SizedBox(width: 6),
              Text(
                'WELCOME TO CHESTSENSE',
                style: AppText.caption.copyWith(
                  color: AppColors.doctorPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          'Who are you?',
          style: AppText.displayMd.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 10),
        Text(
          'Select your role to access the right\npersonalised clinical experience.',
          style: AppText.bodyLg,
        ),
      ],
    );
  }
}

// ── Portal Card ───────────────────────────────────────────────────────────────

class _PortalCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color accent;
  final Color glow;
  final String featureLabel;
  final IconData featureIcon;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accent,
    required this.glow,
    required this.featureLabel,
    required this.featureIcon,
    required this.onTap,
  });

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: _pressed
                ? widget.accent.withValues(alpha: 0.6)
                : AppColors.border,
            width: _pressed ? 1.8 : 1.2,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.glow.withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.2),
                        widget.accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.25)),
                  ),
                  child: Icon(widget.icon,
                      size: 26, color: widget.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppText.headingLg,
                      ),
                      const SizedBox(height: 3),
                      // Portal badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          widget.subtitle.toUpperCase(),
                          style: AppText.caption.copyWith(
                            color: widget.accent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: widget.accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            Divider(
                color: AppColors.border.withValues(alpha: 0.6),
                height: 1),
            const SizedBox(height: 14),
            // Description
            Text(widget.description, style: AppText.bodySm),
            const SizedBox(height: 14),
            // Feature chip
            Row(
              children: [
                Icon(widget.featureIcon,
                    size: 12,
                    color: widget.accent.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  widget.featureLabel,
                  style: AppText.caption.copyWith(
                    color: widget.accent.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route helpers ─────────────────────────────────────────────────────────────

Route<void> _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, anim, secondary, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity:
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
