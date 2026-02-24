import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import 'patient_signup_screen.dart';
import 'doctor_signup_screen.dart';
import '../home/patient_home_screen.dart';
import '../home/doctor_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<FirebaseAuthService>();
    final db = context.read<FirebaseDbService>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signInWithEmail(email: email, password: pass);
      final uid = auth.currentUser!.uid;
      final data = await db.getUserData(uid);
      if (!mounted) return;

      final role = data?['role'];
      if (role == null) {
        await auth.signOut();
        messenger.showSnackBar(
          const SnackBar(content: Text('User role not found. Please contact support.')),
        );
        setState(() => _loading = false);
        return;
      }

      // Redirect based on role
      Widget homeScreen;
      if (role == 'doctor') {
        homeScreen = const DoctorHomeScreen();
      } else if (role == 'patient') {
        homeScreen = const PatientHomeScreen();
      } else {
        await auth.signOut();
        messenger.showSnackBar(
          const SnackBar(content: Text('Invalid user role.')),
        );
        setState(() => _loading = false);
        return;
      }

      nav.pushReplacement(_fadeRoute(homeScreen));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 36),
                  PortalBadge(
                    label: 'SECURE LOGIN',
                    icon: Icons.security_rounded,
                    accent: AppColors.doctorPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text('Welcome back', style: AppText.displayMd),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your personalized\nclinical dashboard.',
                    style: AppText.bodyLg,
                  ),
                  const SizedBox(height: 36),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'EMAIL ADDRESS',
                          controller: _email,
                          hint: 'your@email.com',
                          icon: Icons.email_outlined,
                          accent: AppColors.doctorPrimary,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        AppPasswordField(
                          label: 'PASSWORD',
                          controller: _password,
                          hint: '••••••••',
                          obscure: _obscure,
                          accent: AppColors.doctorPrimary,
                          onToggle: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.doctorPrimary),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Sign In',
                          isLoading: _loading,
                          color: AppColors.doctorPrimary,
                          trailingIcon: Icons.arrow_forward_rounded,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or', style: AppText.caption),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.fingerprint_rounded,
                              size: 20),
                          label: const Text('Sign in with Biometrics'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New here?", style: AppText.bodySm),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .push(_slideRoute(const RoleSelectionForSignup())),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.doctorPrimary),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple role selection screen for signup
class RoleSelectionForSignup extends StatefulWidget {
  const RoleSelectionForSignup({super.key});
  @override
  State<RoleSelectionForSignup> createState() => _RoleSelectionForSignupState();
}

class _RoleSelectionForSignupState extends State<RoleSelectionForSignup>
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
                        Text('Create account', style: AppText.displayMd),
                        const SizedBox(height: 10),
                        Text('Choose your role to get started.', style: AppText.bodyLg),
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
                            onTap: () => Navigator.of(context).push(_slideRoute(const DoctorSignupScreen())),
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
                            onTap: () => Navigator.of(context).push(_slideRoute(const PatientSignupScreen())),
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
                    child: Text('Secure signup  ·  AES-256 encryption', style: AppText.caption),
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
  final String role;
  final String badge;
  final String subtitle;
  final Color accent;
  final Color glow;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.role,
    required this.badge,
    required this.subtitle,
    required this.accent,
    required this.glow,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: _hover ? widget.accent : AppColors.border,
              width: _hover ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.glow.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 0,
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.icon, color: widget.accent, size: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.glow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.badge,
                      style: AppText.caption.copyWith(
                        color: widget.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(widget.role, style: AppText.headingMd),
              const SizedBox(height: 8),
              Text(widget.subtitle, style: AppText.bodySm),
            ],
          ),
        ),
      ),
    );
  }
}

Route<void> _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 380),
    transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
}

Route<void> _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, anim, secondary, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
