import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import 'patient_login_screen.dart';

class PatientSignupScreen extends StatefulWidget {
  const PatientSignupScreen({super.key});
  @override
  State<PatientSignupScreen> createState() => _PatientSignupScreenState();
}

class _PatientSignupScreenState extends State<PatientSignupScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  final _name    = TextEditingController();
  final _age     = TextEditingController();
  final _email   = TextEditingController();
  final _phone   = TextEditingController();
  final _pass    = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _terms    = false;
  bool _loading  = false;
  String? _gender;
  String? _blood;
  static const _accent = AppColors.patientPrimary;
  static const _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  static const _bloods  = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

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
  void dispose() {
    _ctrl.dispose();
    for (final c in [_name, _age, _email, _phone, _pass, _confirm]) { c.dispose(); }
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      _register();
    }
  }

  void _register() async {
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<FirebaseAuthService>();
      final db   = context.read<FirebaseDbService>();
      final cred = await auth.signUpWithEmail(
        email: _email.text.trim(),
        password: _pass.text,
      );
      final uid = cred.user!.uid;
      await auth.updateUserProfile(displayName: _name.text.trim());
      await db.createUserDocument(
        uid: uid,
        email: _email.text.trim(),
        role: 'patient',
        displayName: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      await db.createPatientProfile(
        uid: uid,
        age: _age.text.trim(),
        gender: _gender ?? 'Prefer not to say',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const PatientLoginScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
                    onPressed: _step == 0
                        ? () => Navigator.of(context).pop()
                        : () => setState(() => _step = 0),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PortalBadge(label: 'PATIENT REGISTRATION', icon: Icons.favorite_border_rounded, accent: _accent),
                  const SizedBox(height: 16),
                  Text('Create account', style: AppText.displayMd),
                  const SizedBox(height: 8),
                  Text(_step == 0
                      ? 'Tell us about yourself.'
                      : 'Set up your login details.',
                      style: AppText.bodyLg),
                  const SizedBox(height: 24),
                  StepProgressBar(current: _step, total: 2, accent: _accent),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? AppCard(
                            key: const ValueKey('step0'),
                            child: Column(children: [
                              AppTextField(label: 'FULL NAME', controller: _name, hint: 'John Doe', icon: Icons.person_outline_rounded, accent: _accent),
                              const SizedBox(height: 20),
                              AppTextField(label: 'AGE', controller: _age, hint: '35', icon: Icons.cake_outlined, accent: _accent, keyboardType: TextInputType.number),
                              const SizedBox(height: 20),
                              AppDropdownField(label: 'GENDER', value: _gender, items: _genders, hint: 'Select gender', icon: Icons.wc_rounded, accent: _accent, onChanged: (v) => setState(() => _gender = v)),
                              const SizedBox(height: 20),
                              AppDropdownField(label: 'BLOOD GROUP', value: _blood, items: _bloods, hint: 'Select blood group', icon: Icons.bloodtype_outlined, accent: _accent, onChanged: (v) => setState(() => _blood = v)),
                            ]),
                          )
                        : AppCard(
                            key: const ValueKey('step1'),
                            child: Column(children: [
                              AppTextField(label: 'EMAIL ADDRESS', controller: _email, hint: 'patient@email.com', icon: Icons.email_outlined, accent: _accent, keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 20),
                              AppTextField(label: 'PHONE NUMBER', controller: _phone, hint: '+1 (555) 000-0000', icon: Icons.phone_outlined, accent: _accent, keyboardType: TextInputType.phone),
                              const SizedBox(height: 20),
                              AppPasswordField(label: 'PASSWORD', controller: _pass, hint: '••••••••', obscure: _obscure1, accent: _accent, onToggle: () => setState(() => _obscure1 = !_obscure1)),
                              const SizedBox(height: 20),
                              AppPasswordField(label: 'CONFIRM PASSWORD', controller: _confirm, hint: '••••••••', obscure: _obscure2, accent: _accent, onToggle: () => setState(() => _obscure2 = !_obscure2)),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 20, height: 20, child: Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), activeColor: _accent)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('I agree to the Terms of Service and Privacy Policy', style: AppText.bodySm)),
                                ],
                              ),
                            ]),
                          ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _step == 0 ? 'Continue' : 'Create Account',
                    isLoading: _loading,
                    color: _accent,
                    trailingIcon: _step == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                    onPressed: _next,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?', style: AppText.bodySm),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(foregroundColor: _accent),
                        child: const Text('Sign in'),
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
