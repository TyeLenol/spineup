import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/edge_to_edge_helper.dart';
import '../services/auth_service.dart';
import 'auth_components.dart';
import 'forgot_password_flow.dart';

/// Login and Sign-up screen — toggled via [AuthMode].
///
/// Matching the reference UI exactly:
/// - Fields sit directly on the background (no card wrapper)
/// - Sage CTA for login, coral CTA for signup
/// - Inline mascot beside password label, reactive to focus/reveal state
/// - Account access remains optional; primary use stays on-device and private
class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  final VoidCallback? onBack;
  final void Function(AuthMode mode) onSwitchMode;
  final VoidCallback onSuccess;

  const AuthScreen({
    super.key,
    required this.mode,
    required this.onSwitchMode,
    required this.onSuccess,
    this.onBack,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthMode { login, signup }

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _loading = false;

  bool get _isLogin => widget.mode == AuthMode.login;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    return RegExp(
      r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]',
    ).hasMatch(password);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!_isValidEmail(email)) {
      _showSnackBar(
        "That email doesn't look quite right. Give it another check! 💌",
      );
      return;
    }
    if (!_isLogin && !_isValidPassword(password)) {
      _showSnackBar(
        'Password needs at least 8 characters and one number or symbol. Almost there! 💪',
      );
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Don't forget your password! 🔑");
      return;
    }

    setState(() => _loading = true);
    String? error;
    if (_isLogin) {
      error = await AuthService.signInWithEmail(email, password);
    } else {
      error = await AuthService.signUpWithEmail(email, password);
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackBar(error);
    } else {
      widget.onSuccess();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: AppTheme.foregroundDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    final accentColor = AppTheme.profileSage;
    final bgColor = AppTheme.profileCanvas;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Decorative floating blobs ──────────────────────────────────────
          RepaintBoundary(child: _FloatingBlobs(isLogin: _isLogin)),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account access is kept for a future real account path;
                    // local-first entry no longer appears as a guest escape hatch.
                    const SizedBox(height: 8),
                    AuthBackButton(onBack: widget.onBack),
                    const SizedBox(height: 24),

                    // Heading
                    RepaintBoundary(child: _Heading(isLogin: _isLogin)),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _isLogin
                          ? 'Log in to continue your private SpineUp records.'
                          : "We'll set up your profile and preferences next.",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field
                    AuthFieldLabel('Email address'),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      hintText: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      accentColor: accentColor,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 20),

                    // Password label row
                    Row(
                      children: [
                        AuthFieldLabel('Password'),
                        if (_isLogin) ...[
                          const Spacer(),
                          _ForgotPasswordLink(accentColor: accentColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    AuthTextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      hintText: '••••••••',
                      obscureText: !_showPassword,
                      accentColor: accentColor,
                      autofillHints: _isLogin
                          ? const [AutofillHints.password]
                          : const [AutofillHints.newPassword],
                      trailing: AuthEyeToggle(
                        showPassword: _showPassword,
                        onToggle: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),

                    // Signup hint
                    if (!_isLogin) ...[
                      const SizedBox(height: 8),
                      Text(
                        'At least 8 characters, including a number or symbol.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Primary CTA
                    AuthPrimaryButton(
                      label: _isLogin ? 'Log in' : 'Create account',
                      color: accentColor,
                      textColor: _isLogin
                          ? AppTheme.onPrimaryDark
                          : Colors.white,
                      loading: _loading,
                      onTap: _submit,
                    ),

                    const SizedBox(height: 28),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.profileSage.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.profileSage.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: AppTheme.profileSage,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Account access is optional. Private on-device use is the normal SpineUp experience.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.4,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Switch mode link
                    Center(
                      child: _SwitchModeLink(
                        isLogin: _isLogin,
                        onSwitch: () => widget.onSwitchMode(
                          _isLogin ? AuthMode.signup : AuthMode.login,
                        ),
                      ),
                    ),

                    // Bottom breathing room for imePadding
                    const SizedBox(height: 32),
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

// ── Floating blob decoration ────────────────────────────────────────────────

class _FloatingBlobs extends StatelessWidget {
  final bool isLogin;
  const _FloatingBlobs({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final color = isLogin ? AppTheme.primarySage : AppTheme.secondaryCoral;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Large ambient blob top-right
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.20),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            // Small dot — top area, left-ish (matches reference screenshot)
            Positioned(
              top: 48,
              left: 28,
              child: _BlobDot(size: 10, color: color.withValues(alpha: 0.5)),
            ),
            // Medium dot — upper right (matches reference)
            Positioned(
              top: 80,
              right: 60,
              child: _BlobDot(size: 16, color: color.withValues(alpha: 0.35)),
            ),
            // Tiny dot — right edge
            Positioned(
              top: 120,
              right: 24,
              child: _BlobDot(size: 10, color: color.withValues(alpha: 0.28)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlobDot extends StatelessWidget {
  final double size;
  final Color color;
  const _BlobDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Heading ─────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  final bool isLogin;
  const _Heading({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final accentColor = isLogin
        ? AppTheme.primarySage
        : AppTheme.secondaryCoral;
    final plain = isLogin ? 'Welcome ' : "Let's get ";
    final italic = isLogin ? 'back.' : 'started.';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: plain,
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundDark,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: italic,
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: accentColor,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forgot password link ────────────────────────────────────────────────────

class _ForgotPasswordLink extends StatelessWidget {
  final Color accentColor;
  const _ForgotPasswordLink({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(forgotPasswordRoute()),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          'Forgot password?',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}

// ── Switch mode link ─────────────────────────────────────────────────────────

class _SwitchModeLink extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onSwitch;
  const _SwitchModeLink({required this.isLogin, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final prompt = isLogin
        ? "Don't have an account? "
        : 'Already have an account? ';
    final action = isLogin ? 'Sign up' : 'Log in';
    return GestureDetector(
      onTap: onSwitch,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: prompt,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            TextSpan(
              text: action,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.foregroundDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
