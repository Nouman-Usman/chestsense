import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_db_service.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _saving   = false;
  Map<String, dynamic>? _profile;

  // Controllers for editable fields
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<FirebaseAuthService>();
    final db   = context.read<FirebaseDbService>();
    final uid  = auth.currentUser?.uid;
    if (uid == null) return;
    final data = await db.getUserData(uid);
    if (!mounted) return;
    setState(() {
      _profile = data;
      _nameCtrl.text  = data?['displayName'] ?? '';
      _phoneCtrl.text = data?['phone'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final auth = context.read<FirebaseAuthService>();
    final db   = context.read<FirebaseDbService>();
    final uid  = auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await auth.updateUserProfile(displayName: _nameCtrl.text.trim());
      await db.updateUserData(uid, {
        'displayName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Sign out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<FirebaseAuthService>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _changePassword() async {
    // Get all dependencies upfront
    final auth = context.read<FirebaseAuthService>();
    final messenger = ScaffoldMessenger.of(context);

    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Change Password',
            style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPwCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.overlay,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'New password',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.overlay,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPwCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.overlay,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change',
                style: TextStyle(color: AppColors.patientPrimary)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      return;
    }

    final current = currentPwCtrl.text.trim();
    final newPw = newPwCtrl.text.trim();
    final confirm = confirmPwCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
      }
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      return;
    }

    if (newPw != confirm) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('New passwords do not match.')),
        );
      }
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      return;
    }

    if (newPw.length < 6) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters.')),
        );
      }
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      return;
    }

    try {
      await auth.changePassword(
            currentPassword: current,
            newPassword: newPw,
          );
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Password changed successfully.'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Get all dependencies upfront
    final auth = context.read<FirebaseAuthService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('Delete Account',
            style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter password to confirm',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.overlay,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete permanently',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      passwordCtrl.dispose();
      return;
    }

    final password = passwordCtrl.text.trim();
    if (password.isEmpty) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please enter your password.')),
        );
      }
      passwordCtrl.dispose();
      return;
    }

    try {
      await auth.deleteAccount(password: password);
      passwordCtrl.dispose();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      passwordCtrl.dispose();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final role = _profile?['role'] as String? ?? 'patient';
    final accent = role == 'doctor'
        ? AppColors.doctorPrimary
        : AppColors.patientPrimary;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Text('Profile settings',
                        style: AppText.headingMd
                            .copyWith(color: AppColors.textPrimary)),
                  ]),
                ),
                const SizedBox(height: 8),
                // ── Body ───────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accent))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAvatar(role, accent),
                              const SizedBox(height: 28),
                              // ── Editable fields ──────────────────────────
                              _SectionHeader(label: 'Personal information'),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Full name',
                                controller: _nameCtrl,
                                hint: 'Full name',
                                icon: Icons.person_outline_rounded,
                                accent: accent,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Phone number',
                                controller: _phoneCtrl,
                                hint: 'Phone number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                accent: accent,
                              ),
                              const SizedBox(height: 24),
                              // ── Read-only info ──────────────────────────
                              _SectionHeader(label: 'Account details'),
                              const SizedBox(height: 12),
                              _InfoTile(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _profile?['email'] ?? '—',
                              ),
                              const SizedBox(height: 8),
                              _InfoTile(
                                icon: Icons.badge_outlined,
                                label: 'Role',
                                value: role == 'doctor' ? 'Doctor' : 'Patient',
                                accent: accent,
                              ),
                              // Doctor-specific read-only fields
                              if (role == 'doctor') ...[
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.local_hospital_outlined,
                                  label: 'Specialization',
                                  value: _profile?['specialization'] ?? '—',
                                ),
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.verified_outlined,
                                  label: 'Medical license',
                                  value: _profile?['licenseNumber'] ?? '—',
                                ),
                              ],
                              // Patient-specific read-only fields
                              if (role == 'patient') ...[
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.cake_outlined,
                                  label: 'Age',
                                  value: _profile?['age'] ?? '—',
                                ),
                                const SizedBox(height: 8),
                                _InfoTile(
                                  icon: Icons.wc_outlined,
                                  label: 'Gender',
                                  value: _profile?['gender'] ?? '—',
                                ),
                              ],
                              const SizedBox(height: 32),
                              // ── Save button ──────────────────────────────
                              PrimaryButton(
                                label: 'Save changes',
                                color: accent,
                                isLoading: _saving,
                                onPressed: _saveProfile,
                                trailingIcon: Icons.save_outlined,
                              ),
                              const SizedBox(height: 12),
                              // ── Change password ─────────────────────────
                              OutlinedButton.icon(
                                onPressed: _changePassword,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: accent.withAlpha(100)),
                                  foregroundColor: accent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.md),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.key_outlined, size: 18),
                                label: const Text('Change Password'),
                              ),
                              const SizedBox(height: 12),
                              // ── Delete account  ─────────────────────────
                              OutlinedButton.icon(
                                onPressed: _deleteAccount,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.redAccent.withAlpha(100)),
                                  foregroundColor: Colors.redAccent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.md),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.delete_outline_rounded, size: 18),
                                label: const Text('Delete Account'),
                              ),
                              const SizedBox(height: 12),
                              // ── Sign out ─────────────────────────────────
                              OutlinedButton.icon(
                                onPressed: _signOut,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.redAccent.withAlpha(100)),
                                  foregroundColor: Colors.redAccent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.md),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.logout_rounded, size: 18),
                                label: const Text('Sign out'),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String role, Color accent) {
    final initials = (_nameCtrl.text.isNotEmpty
            ? _nameCtrl.text.trim().split(' ')
            : ['?'])
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: accent.withAlpha(30),
            child: Text(
              initials,
              style: AppText.headingLg.copyWith(color: accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _nameCtrl.text.isEmpty ? 'Your name' : _nameCtrl.text,
            style: AppText.headingMd.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          PortalBadge(
            label: role.toUpperCase(),
            icon: role == 'doctor'
                ? Icons.medical_services_outlined
                : Icons.person_outline_rounded,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppText.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600));
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon,
            size: 18,
            color: accent ?? AppColors.textSecondary.withAlpha(160)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppText.caption
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppText.bodyLg.copyWith(color: AppColors.textPrimary)),
        ]),
      ]),
    );
  }
}
