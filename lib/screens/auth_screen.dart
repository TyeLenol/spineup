import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
/// - Google + Apple buttons follow platform branding requirements
/// - All social auth is MOCK — see [AuthService] for replacement instructions
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
    return RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]').hasMatch(password);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!_isValidEmail(email)) {
      _showSnackBar("That email doesn't look quite right. Give it another check! 💌");
      return;
    }
    if (!_isLogin && !_isValidPassword(password)) {
      _showSnackBar('Password needs at least 8 characters and one number or symbol. Almost there! 💪');
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

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    final error = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _showSnackBar(error);
    } else {
      widget.onSuccess();
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    final error = await AuthService.signInWithApple();
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
    final accentColor = _isLogin ? AppTheme.primarySage : AppTheme.secondaryCoral;

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
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
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      const SizedBox(height: 8),
                      AuthBackButton(onBack: widget.onBack),
                      const SizedBox(height: 32),

                      // Heading
                      RepaintBoundary(child: _Heading(isLogin: _isLogin)),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        _isLogin
                            ? 'Log in to keep tracking your curve and streak.'
                            : "We'll set up your diagnosis and avatar next.",
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
                          onToggle: () => setState(() => _showPassword = !_showPassword),
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
                        textColor: _isLogin ? AppTheme.onPrimaryDark : Colors.white,
                        loading: _loading,
                        onTap: _submit,
                      ),

                      const SizedBox(height: 28),

                      // OR divider
                      const _OrDivider(),
                      const SizedBox(height: 16),

                      // Google button
                      _GoogleButton(onTap: _signInWithGoogle, loading: _loading),
                      const SizedBox(height: 12),

                      // Apple button
                      _AppleButton(onTap: _signInWithApple, loading: _loading),
                      const SizedBox(height: 24),

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
    final accentColor = isLogin ? AppTheme.primarySage : AppTheme.secondaryCoral;
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

// ── OR divider ───────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.borderCream),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedForeground,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.borderCream),
        ),
      ],
    );
  }
}

// ── Google sign-in button ────────────────────────────────────────────────────
// Per Google branding requirements: white background, official Google G logo, black text.

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  const _GoogleButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      onTap: loading ? () {} : onTap,
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      borderColor: const Color(0xFFDADADA),
      label: 'Continue with Google',
      icon: const _GoogleLogoSvg(),
    );
  }
}

/// Official Google "G" logo using the exact SVG path data from
/// https://developers.google.com/identity/branding-guidelines
class _GoogleLogoSvg extends StatelessWidget {
  const _GoogleLogoSvg();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 20, height: 20);
  }
}

// ── Apple sign-in button ─────────────────────────────────────────────────────
// Per Apple branding requirements: black background, official Apple logo, white text.

class _AppleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  const _AppleButton({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      onTap: loading ? () {} : onTap,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      borderColor: Colors.black,
      label: 'Continue with Apple',
      icon: const _AppleLogoSvg(),
    );
  }
}

/// Apple logo via font_awesome_flutter — correct shape, no SVG boilerplate.
/// FaIcon handles sizing and color automatically.
class _AppleLogoSvg extends StatelessWidget {
  const _AppleLogoSvg();

  @override
  Widget build(BuildContext context) {
    return const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 20);
  }
}

// ── Generic social button ────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final String label;
  final Widget icon;

  const _SocialButton({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
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
    final prompt = isLogin ? "Don't have an account? " : 'Already have an account? ';
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

