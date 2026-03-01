import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────── COLOUR TOKENS ───────────────────────────

class AppColors {
  AppColors._();

  // Canvas
  static const bg          = Color(0xFF080E1A);  // deepest background
  static const surface     = Color(0xFF0F1923);  // card / dialog surface
  static const surfaceAlt  = Color(0xFF151F2E);  // elevated surface
  static const surfaceVariant = Color(0xFF1A2D3A); // variant surface
  static const surfaceTertiary = Color(0xFF1E3344); // tertiary surface
  static const border      = Color(0xFF1E2D40);  // subtle divider / border
  static const overlay     = Color(0xFF1A2535);  // input fill
  static const primary     = Color(0xFF2563EB);  // primary color (alias)

  // Brand – Doctor (blue)
  static const doctorPrimary  = Color(0xFF2563EB);
  static const doctorLight    = Color(0xFF3B82F6);
  static const doctorGlow     = Color(0x332563EB);

  // Brand – Patient (teal)
  static const patientPrimary = Color(0xFF0D9488);
  static const patientLight   = Color(0xFF14B8A6);
  static const patientGlow    = Color(0x330D9488);

  // Text
  static const textPrimary   = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted     = Color(0xFF475569);
  static const textOnAccent  = Colors.white;

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);

  // Glassmorphism overlays
  static const glassLight = Color(0x1AFFFFFF);  // 10% white
  static const glassMedium = Color(0x33FFFFFF); // 20% white
}

// ─────────────────────────── SPACING ───────────────────────────

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─────────────────────────── RADIUS ───────────────────────────

class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 28;
}

// ─────────────────────────── TEXT STYLES ───────────────────────────

class AppText {
  AppText._();

  static const displayLg = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.8,
  );

  static const displayMd = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const headingLg = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const headingMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static const eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.doctorPrimary,
    letterSpacing: 2.0,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

// ─────────────────────────── THEME ───────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.doctorPrimary,
        secondary: AppColors.patientPrimary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.overlay,
        hintStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
              color: AppColors.doctorPrimary, width: 1.5),
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.doctorPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.doctorPrimary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      // Dropdown
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.overlay,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.doctorPrimary,
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      dividerColor: AppColors.border,
    );
  }

  // Expose system UI overlay style for dark screens
  static const systemBarDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

// ─────────────────────────── SHARED WIDGETS ───────────────────────────

/// Glassmorphism container with frosted glass effect
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color borderColor;
  final double borderWidth;
  final BoxShadow? shadow;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.borderColor = AppColors.border,
    this.borderWidth = 1.0,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.xl),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadow != null
            ? [shadow!]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: child,
    );
  }
}

// ─────────────────────────── ORIGINAL SHARED WIDGETS ───────────────────────────

/// Branded app logo mark
class AppLogoMark extends StatelessWidget {
  final double size;
  final Color color;
  const AppLogoMark({
    super.key,
    this.size = 48,
    this.color = AppColors.doctorPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: size * 0.8,
            offset: Offset(0, size * 0.18),
            spreadRadius: size * 0.2,
          ),
        ],
      ),
      child: Icon(Icons.monitor_heart_rounded,
          size: size * 0.52, color: Colors.white),
    );
  }
}

/// Accent-coloured portal badge  (e.g. "DOCTOR PORTAL")
class PortalBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  const PortalBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark-theme text input with label
class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final Color accent;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppText.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
              prefixIcon: Icon(widget.icon, size: 18, color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: widget.accent, width: 1.5),
              ),
              filled: true,
              fillColor: _focused 
                ? widget.accent.withValues(alpha: 0.05)
                : AppColors.surface.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark-theme password field with label + toggle
class AppPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Color accent;
  final VoidCallback onToggle;

  const AppPasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.accent,
    required this.onToggle,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppText.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscure,
            style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: widget.onToggle,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: widget.accent, width: 1.5),
              ),
              filled: true,
              fillColor: _focused 
                ? widget.accent.withValues(alpha: 0.05)
                : AppColors.surface.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark-theme dropdown field with label
class AppDropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final IconData icon;
  final Color accent;
  final ValueChanged<String?> onChanged;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<AppDropdownField> createState() => _AppDropdownFieldState();
}

class _AppDropdownFieldState extends State<AppDropdownField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: AppText.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: DropdownButtonFormField<String>(
            initialValue: widget.value,
            dropdownColor: AppColors.surfaceAlt,
            style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
            items: widget.items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: AppText.bodySm
                              .copyWith(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
              prefixIcon: Icon(widget.icon, size: 18, color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: widget.accent, width: 1.5),
              ),
              filled: true,
              fillColor: _focused 
                ? widget.accent.withValues(alpha: 0.05)
                : AppColors.surface.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Surface card with consistent dark styling and glassmorphism options
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool glassmorphic;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.glassmorphic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glassmorphic 
          ? AppColors.surface.withValues(alpha: 0.7)
          : AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.xl),
        border: Border.all(
          color: AppColors.border,
          width: glassmorphic ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: glassmorphic ? 0.2 : 0.1),
            blurRadius: glassmorphic ? 24 : 12,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Step indicator bar
class StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color accent;
  const StepProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: i <= current
                    ? accent
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Primary CTA button with loading state and gradient
class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
    this.color,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? AppColors.doctorPrimary;
    final isDisabled = isLoading || onPressed == null;
    
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              baseColor,
              baseColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else ...[
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 18, color: Colors.white),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide up entrance animation wrapper
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
