import 'package:flutter/material.dart';
import '../theme/spine_fonts.dart';

/// Reusable 3D Tactile Push-Button with physical depth lip and depression physics.
class Chunky3DButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color depthColor;
  final IconData icon;

  const Chunky3DButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFD85A30), // secondary Coral
    this.depthColor = const Color(0xFFB33D18), // dark depth lip
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<Chunky3DButton> createState() => _Chunky3DButtonState();
}

class _Chunky3DButtonState extends State<Chunky3DButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _depthAnim;
  late Animation<double> _pushYAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _depthAnim = Tween<double>(begin: 5.0, end: 1.5).animate(_pressCtrl);
    _pushYAnim = Tween<double>(begin: 0.0, end: 3.5).animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressCtrl.reverse().then((_) => widget.onTap());
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _pushYAnim.value),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.depthColor,
                    offset: Offset(0, _depthAnim.value),
                    blurRadius: 0, // Solid 3D lip shadow
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: SpineFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(widget.icon, color: Colors.white, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
