import 'package:flutter/material.dart';
import '../theme/spine_fonts.dart';
import '../theme/app_theme.dart';

// ── Back button ─────────────────────────────────────────────────────────────

class AuthBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  const AuthBackButton({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onBack ?? () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(24),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          Icons.chevron_left_rounded,
          color: AppTheme.mutedForeground,
          size: 28,
        ),
      ),
    );
  }
}

// ── Field label ─────────────────────────────────────────────────────────────

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SpineFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.foregroundDark,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ── Auth text field ─────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color accentColor;
  final Widget? trailing;
  final List<String>? autofillHints;
  final TextAlign textAlign;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.accentColor,
    this.trailing,
    this.autofillHints,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.profileSurface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? accentColor : AppTheme.profileBorder,
              width: isFocused ? 2.0 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  autofillHints: autofillHints,
                  textAlign: textAlign,
                  maxLength: maxLength,
                  onChanged: onChanged,
                  style: SpineFonts.outfit(
                    fontSize: 16,
                    color: AppTheme.foregroundDark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    counterText:
                        "", // Hide character counter if maxLength is set
                    hintText: hintText,
                    hintStyle: SpineFonts.outfit(
                      fontSize: 15,
                      color: AppTheme.profileMuted.withValues(alpha: 0.65),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        );
      },
    );
  }
}

// ── Eye toggle ──────────────────────────────────────────────────────────────

class AuthEyeToggle extends StatelessWidget {
  final bool showPassword;
  final VoidCallback onToggle;
  const AuthEyeToggle({
    super.key,
    required this.showPassword,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: showPassword ? 'Hide password' : 'Show password',
      button: true,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppTheme.mutedForeground,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Primary CTA button ───────────────────────────────────────────────────────

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool loading;
  final VoidCallback onTap;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: loading ? color.withValues(alpha: 0.7) : color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: SpineFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
