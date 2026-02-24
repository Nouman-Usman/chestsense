import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import 'doctor_signup_screen.dart';
import '../home/doctor_home_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});
  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  static const _accent = AppColors.doctorPrimary;

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
  void dispose() {
    _ctrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _email.text.trim();
    final pass  = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<FirebaseAuthService>();
    final db   = context.read<FirebaseDbService>();
    final nav  = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signInWithEmail(email: email, password: pass);
      final uid  = auth.currentUser!.uid;
      final data = await db.getUserData(uid);
      if (!mounted) return;
      if (data?['role'] != 'doctor') {
        await auth.signOut();
        messenger.showSnackBar(
          const SnackBar(content: Text('This account is not a Doctor account.')),
        );
        setState(() => _loading = false);
        return;
      }
      nav.pushReplacement(_fadeRoute(const DoctorHomeScreen()));
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
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 36),
                  PortalBadge(label: 'DOCTOR PORTAL', icon: Icons.medical_services_outlined, accent: _accent),
                  const SizedBox(height: 16),
                  Text('Welcome back', style: AppText.displayMd),
                  const SizedBox(height: 8),
                  Text('Sign in to your clinical account to access your\npatient dashboard.', style: AppText.bodyLg),
                  const SizedBox(height: 36),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(label: 'EMAIL ADDRESS', controller: _email, hint: 'doctor@hospital.com', icon: Icons.email_outlined, accent: _accent, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 20),
                        AppPasswordField(label: 'PASSWORD', controller: _password, hint: '••••••••', obscure: _obscure, accent: _accent, onToggle: () => setState(() => _obscure = !_obscure)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(width: 20, height: 20, child: Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false), activeColor: _accent)),
                            const SizedBox(width: 10),
                            Text('Remember me', style: AppText.bodySm),
                            const Spacer(),
                            TextButton(onPressed: () {}, child: const Text('Forgot password?')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(label: 'Sign In', isLoading: _loading, color: _accent, trailingIcon: Icons.arrow_forward_rounded, onPressed: _submit),
                        const SizedBox(height: 16),
                        Row(children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: AppText.caption)),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.business_outlined, size: 18), label: const Text('Sign in with SSO')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: AppText.bodySm),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(_slideRoute(const DoctorSignupScreen())),
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

Route<void> _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, anim, secondary) => page,
    transitionDuration: const Duration(milliseconds: 380),
    transitionsBuilder: (context, anim, secondary, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
  );
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
