import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  // Colors
  static const _bgColor = Color(0xFF0f172a);
  static const _surfaceColor = Color(0xFF1e293b);
  static const _borderColor = Color(0xFF334155);
  static const _doctorAccent = Color(0xFF3b82f6);
  static const _patientAccent = Color(0xFF10b981);
  static const _textPrimary = Color(0xFFf1f5f9);
  static const _textSecondary = Color(0xFF94a3b8);
  static const _textMuted = Color(0xFF64748b);

  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
    final db = context.read<FirebaseDbService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final data = await db.getUserData(uid);
    if (!mounted) return;
    setState(() {
      _profile = data;
      _nameCtrl.text = data?['displayName'] ?? '';
      _phoneCtrl.text = data?['phone'] ?? '';
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final auth = context.read<FirebaseAuthService>();
    final db = context.read<FirebaseDbService>();
    final uid = auth.currentUser?.uid;
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
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: _textSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
            child: const Text('Sign Out'),
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
    final auth = context.read<FirebaseAuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final role = _profile?['role'] as String? ?? 'patient';
    final accent = role == 'doctor' ? _doctorAccent : _patientAccent;

    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Change Password',
          style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                controller: currentPwCtrl,
                hint: 'Current password',
                obscure: true,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: newPwCtrl,
                hint: 'New password',
                obscure: true,
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: confirmPwCtrl,
                hint: 'Confirm new password',
                obscure: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text('Change'),
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
          SnackBar(
            content: const Text('Please fill all fields'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
          SnackBar(
            content: const Text('New passwords do not match'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
          SnackBar(
            content: const Text('Password must be at least 6 characters'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      currentPwCtrl.dispose();
      newPwCtrl.dispose();
      confirmPwCtrl.dispose();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<FirebaseAuthService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red.shade400, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: _textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              controller: passwordCtrl,
              hint: 'Enter password to confirm',
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Delete Permanently'),
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
          SnackBar(
            content: const Text('Please enter your password'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _profile?['role'] as String? ?? 'patient';
    final accent = role == 'doctor' ? _doctorAccent : _patientAccent;

    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Profile Settings',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accent,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Avatar section
                            _buildAvatar(role, accent),
                            const SizedBox(height: 32),

                            // Personal Information
                            _buildSectionHeader('Personal Information'),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              accent: accent,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              accent: accent,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 28),

                            // Account Details
                            _buildSectionHeader('Account Details'),
                            const SizedBox(height: 12),
                            _buildInfoTile(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _profile?['email'] ?? '—',
                            ),
                            const SizedBox(height: 10),
                            _buildInfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Role',
                              value: role == 'doctor' ? 'Doctor' : 'Patient',
                              accent: accent,
                            ),

                            // Doctor-specific fields
                            if (role == 'doctor') ...[
                              const SizedBox(height: 10),
                              _buildInfoTile(
                                icon: Icons.local_hospital_outlined,
                                label: 'Specialization',
                                value: _profile?['specialization'] ?? '—',
                              ),
                              const SizedBox(height: 10),
                              _buildInfoTile(
                                icon: Icons.verified_outlined,
                                label: 'Medical License',
                                value: _profile?['licenseNumber'] ?? '—',
                              ),
                            ],

                            // Patient-specific fields
                            if (role == 'patient') ...[
                              const SizedBox(height: 10),
                              _buildInfoTile(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: _profile?['age']?.toString() ?? '—',
                              ),
                              const SizedBox(height: 10),
                              _buildInfoTile(
                                icon: Icons.wc_outlined,
                                label: 'Gender',
                                value: _profile?['gender'] ?? '—',
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Save Button
                            _buildActionButton(
                              label: 'Save Changes',
                              icon: Icons.save_outlined,
                              color: accent,
                              isLoading: _saving,
                              onPressed: _saveProfile,
                            ),
                            const SizedBox(height: 12),

                            // Change Password
                            _buildOutlineButton(
                              label: 'Change Password',
                              icon: Icons.key_outlined,
                              color: accent,
                              onPressed: _changePassword,
                            ),
                            const SizedBox(height: 12),

                            // Delete Account
                            _buildOutlineButton(
                              label: 'Delete Account',
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                              onPressed: _deleteAccount,
                            ),
                            const SizedBox(height: 12),

                            // Sign Out
                            _buildOutlineButton(
                              label: 'Sign Out',
                              icon: Icons.logout_rounded,
                              color: Colors.red.shade400,
                              onPressed: _signOut,
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
    );
  }

  // Widget Builders
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
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent.withOpacity(0.3), accent.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nameCtrl.text.isEmpty ? 'Your Name' : _nameCtrl.text,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role == 'doctor' ? Icons.medical_services : Icons.person,
                  size: 14,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accent,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPrimary, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: accent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (accent ?? _textSecondary).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent ?? _textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: color.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
