import 'package:flutter/material.dart';
import '../theme/spine_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/app_transitions.dart';
import '../theme/edge_to_edge_helper.dart';
import 'auth_components.dart';

Route<void> forgotPasswordRoute() {
  return slideRoute(const ForgotPasswordScreen());
}

Route<void> slideRoute(Widget page) {
  return AppTransitions.buildForwardBackwardRoute<void>(
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 480),
    pageBuilder: (context) => page,
  );
}

// ── Screen 1: Forgot Password ───────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _send() {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "That email doesn't look quite right. Give it a check! 💌",
            style: SpineFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(slideRoute(VerifyEmailScreen(email: email)));
    });
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          const RepaintBoundary(child: _Screen1Accents()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const AuthBackButton(),
                  ),
                  const SizedBox(height: 48),
                  _IconBadge(
                    mainIcon: Icons.lock_outline_rounded,
                    badgeIcon: Icons.help_outline_rounded,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    badgeColor: const Color(0xFF8B7FF1), // purple badge
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Forgot your ', style: _headingStyle()),
                        TextSpan(
                          text: 'password?',
                          style: _headingStyle(
                            color: Theme.of(context).colorScheme.primary,
                            italic: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No worries, it happens. Enter your email and we'll help you get back in.",
                    textAlign: TextAlign.center,
                    style: SpineFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const AuthFieldLabel('Email address'),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    accentColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  AuthPrimaryButton(
                    label: 'Send reset link',
                    color: Theme.of(context).colorScheme.primary,
                    textColor: AppTheme.onPrimaryDark,
                    loading: _loading,
                    onTap: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen 2: Verify Email (OTP) ────────────────────────────────────────────

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _ctrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;
  final Color _lavender = const Color(0xFF8B7FF1);

  @override
  void dispose() {
    for (var c in _ctrls) {
      c.dispose();
    }
    for (var n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _verify() {
    // MOCK: accept any 4 digits
    final code = _ctrls.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter all 4 digits.',
            style: SpineFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(slideRoute(const SetNewPasswordScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          const RepaintBoundary(child: _Screen2Accents()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const AuthBackButton(),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _lavender,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Verify your ', style: _headingStyle()),
                        TextSpan(
                          text: 'email.',
                          style: _headingStyle(
                            color: Theme.of(context).colorScheme.primary,
                            italic: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter the 4-digit code sent to\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: SpineFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 60,
                          child: AuthTextField(
                            controller: _ctrls[index],
                            focusNode: _nodes[index],
                            hintText: '',
                            accentColor: _lavender,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            onChanged: (val) {
                              if (val.isNotEmpty && index < 3) {
                                _nodes[index + 1].requestFocus();
                              } else if (val.isEmpty && index > 0) {
                                _nodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Resend code',
                        style: SpineFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _lavender,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AuthPrimaryButton(
                    label: 'Verify',
                    color: _lavender,
                    textColor: Colors.white,
                    loading: _loading,
                    onTap: _verify,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen 3: Set New Password ──────────────────────────────────────────────

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});
  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _update() {
    final pwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pwd.length < 8 ||
        !RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]').hasMatch(pwd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password needs at least 8 characters and one number or symbol.',
            style: SpineFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
      return;
    }
    if (pwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Passwords do not match.',
            style: SpineFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password updated successfully! 🔒',
            style: SpineFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    EdgeToEdgeHelper.configureSystemUi(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      body: Stack(
        children: [
          const RepaintBoundary(child: _Screen3Accents()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const AuthBackButton(),
                  ),
                  const SizedBox(height: 48),
                  _IconBadge(
                    mainIcon: Icons.lock_outline_rounded,
                    badgeIcon: Icons.check_rounded,
                    primaryColor: AppTheme.secondaryCoral,
                    badgeColor: Theme.of(
                      context,
                    ).colorScheme.primary, // green checkmark badge
                  ),
                  const SizedBox(height: 32),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Set a new ', style: _headingStyle()),
                        TextSpan(
                          text: 'password.',
                          style: _headingStyle(
                            color: AppTheme.secondaryCoral,
                            italic: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Please enter your new password below.",
                    textAlign: TextAlign.center,
                    style: SpineFonts.outfit(
                      fontSize: 15,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    children: [
                      const AuthFieldLabel('New password'),
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B7FF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            '^^',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: _newCtrl,
                    focusNode: _newFocus,
                    hintText: '••••••••',
                    obscureText: !_showNew,
                    accentColor: AppTheme.secondaryCoral,
                    trailing: AuthEyeToggle(
                      showPassword: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: const AuthFieldLabel('Confirm password'),
                  ),
                  const SizedBox(height: 6),
                  AuthTextField(
                    controller: _confirmCtrl,
                    focusNode: _confirmFocus,
                    hintText: '••••••••',
                    obscureText: !_showConfirm,
                    accentColor: AppTheme.secondaryCoral,
                    trailing: AuthEyeToggle(
                      showPassword: _showConfirm,
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'At least 8 characters, including a number or symbol.',
                      style: SpineFonts.outfit(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  AuthPrimaryButton(
                    label: 'Update password',
                    color: AppTheme.secondaryCoral,
                    textColor: Colors.white,
                    loading: _loading,
                    onTap: _update,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared UI Utils ─────────────────────────────────────────────────────────

TextStyle _headingStyle({Color? color, bool italic = false}) {
  return SpineFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: 1.1,
    letterSpacing: -0.5,
  );
}

class _IconBadge extends StatelessWidget {
  final IconData mainIcon;
  final IconData badgeIcon;
  final Color primaryColor;
  final Color badgeColor;

  const _IconBadge({
    required this.mainIcon,
    required this.badgeIcon,
    required this.primaryColor,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(mainIcon, color: Colors.white, size: 40),
        ),
        Positioned(
          bottom: -6,
          right: -6,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.backgroundCream, width: 3),
            ),
            child: Icon(badgeIcon, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;
  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Screen1Accents extends StatelessWidget {
  const _Screen1Accents();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 60,
            child: _Dot(
              size: 10,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            top: 105,
            right: 80,
            child: _Dot(
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 145,
            right: 65,
            child: _Dot(
              size: 8,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            top: 160,
            right: 120,
            child: Icon(
              Icons.auto_awesome,
              size: 24,
              color: const Color(0xFF8B7FF1).withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            top: 340,
            left: 110,
            child: _Dot(size: 12, color: AppTheme.secondaryCoral),
          ),
        ],
      ),
    );
  }
}

class _Screen2Accents extends StatelessWidget {
  const _Screen2Accents();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 170,
            right: 125,
            child: Icon(
              Icons.auto_awesome,
              size: 24,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            top: 270,
            left: 95,
            child: _Dot(
              size: 10,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 350,
            left: 110,
            child: _Dot(size: 12, color: AppTheme.secondaryCoral),
          ),
          Positioned(
            top: 330,
            right: 100,
            child: _Dot(
              size: 14,
              color: const Color(0xFF8B7FF1).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Screen3Accents extends StatelessWidget {
  const _Screen3Accents();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 45,
            left: 55,
            child: _Dot(
              size: 10,
              color: AppTheme.secondaryCoral.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            top: 90,
            left: 105,
            child: Icon(
              Icons.auto_awesome,
              size: 24,
              color: const Color(0xFF8B7FF1).withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            top: 95,
            right: 80,
            child: _Dot(
              size: 14,
              color: AppTheme.secondaryCoral.withValues(alpha: 0.3),
            ),
          ),
          Positioned(
            top: 145,
            right: 65,
            child: _Dot(
              size: 8,
              color: AppTheme.secondaryCoral.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            top: 275,
            left: 110,
            child: _Dot(size: 10, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
