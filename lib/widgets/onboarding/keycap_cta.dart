import 'package:flutter/material.dart';

/// Expressive onboarding CTA with a small tactile depth cue and a calm
/// rounded-rectangle silhouette.
class KeycapCta extends StatefulWidget {
  final String label;
  final VoidCallback onClick;
  final Color fill;
  final Color ink;
  final Color text;
  final IconData? icon;
  final bool compact;

  const KeycapCta({
    super.key,
    required this.label,
    required this.onClick,
    required this.fill,
    required this.ink,
    required this.text,
    this.icon,
    this.compact = false,
  });

  @override
  State<KeycapCta> createState() => _KeycapCtaState();
}

class _KeycapCtaState extends State<KeycapCta> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Align(
      alignment: widget.compact ? Alignment.centerRight : Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.compact ? 240.0 : 320.0,
          minHeight: 56.0,
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onClick();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Darker depth shape beneath (offset Y: +6dp)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: 56.0,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4.0),
                decoration: BoxDecoration(
                  color: widget.ink,
                  borderRadius: BorderRadius.circular(_isPressed ? 16.0 : 18.0),
                ),
              ),

              // 2. Opaque keycap top surface (presses down +6dp)
              AnimatedContainer(
                duration: Duration(milliseconds: disableAnimations ? 0 : 150),
                curve: Curves.easeOut,
                height: 56.0,
                width: double.infinity,
                transform: Matrix4.translationValues(
                  0.0,
                  _isPressed && !disableAnimations ? 4.0 : 0.0,
                  0.0,
                ),
                decoration: BoxDecoration(
                  color: widget.fill,
                  borderRadius: BorderRadius.circular(_isPressed ? 16.0 : 18.0),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14.0 : 32.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.text,
                        fontSize: widget.compact ? 15.0 : 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      SizedBox(width: widget.compact ? 8.0 : 10.0),
                      Icon(
                        widget.icon,
                        color: widget.text,
                        size: widget.compact ? 18.0 : 20.0,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
