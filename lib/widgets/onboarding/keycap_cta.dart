import 'package:flutter/material.dart';

/// M3-Expressive Keycap CTA: opaque keycap over a darker offset shape beneath.
/// Features a depth press animation on interaction (`translateY(6)` and radius morphing).
class KeycapCta extends StatefulWidget {
  final String label;
  final VoidCallback onClick;
  final Color fill;
  final Color ink;
  final Color text;

  const KeycapCta({
    super.key,
    required this.label,
    required this.onClick,
    required this.fill,
    required this.ink,
    required this.text,
  });

  @override
  State<KeycapCta> createState() => _KeycapCtaState();
}

class _KeycapCtaState extends State<KeycapCta> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320.0, minHeight: 56.0),
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
                margin: const EdgeInsets.only(top: 6.0),
                decoration: BoxDecoration(
                  color: widget.ink,
                  borderRadius: BorderRadius.circular(_isPressed ? 22.0 : 999.0),
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
                  _isPressed && !disableAnimations ? 6.0 : 0.0,
                  0.0,
                ),
                decoration: BoxDecoration(
                  color: widget.fill,
                  borderRadius: BorderRadius.circular(_isPressed ? 22.0 : 999.0),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.text,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
