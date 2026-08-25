import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../learn_screen.dart';

/// A small hand-sketched 6-point star drawn with CustomPaint.
/// Slightly irregular arm lengths give it a casual, handmade feel.
class _HandmadeStar extends StatelessWidget {
  const _HandmadeStar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: _HandmadeStarPainter(color: AppTheme.profileSage),
      ),
    );
  }
}

class _HandmadeStarPainter extends CustomPainter {
  final Color color;
  const _HandmadeStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    // Slightly irregular outer radii for a hand-drawn look
    const outerR = [0.48, 0.45, 0.47, 0.46, 0.48, 0.44];
    const innerR = 0.18;
    const points = 6;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (math.pi / points) * i - math.pi / 2;
      final r = i.isEven ? outerR[i ~/ 2] * size.width : innerR * size.width;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HandmadeStarPainter old) => old.color != color;
}

class ProfileField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helpTopicId;
  final Widget child;
  final bool required;

  const ProfileField({
    super.key,
    required this.label,
    this.hint,
    this.helpTopicId,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: AppTheme.foregroundDark,
                      ),
                    ),
                  ),
                  if (required) ...[
                    const SizedBox(width: 5),
                    const _HandmadeStar(),
                  ],
                ],
              ),
            ),
            if (helpTopicId != null)
              ContextualHelpIcon(
                topicId: helpTopicId!,
                tooltip: 'Learn about $label',
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.profileMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class ProfileTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const ProfileTextInput({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.foregroundDark,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.profileMuted,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.profileAction,
        ),
        hintText: hintText,
        errorText: errorText,
        hintStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppTheme.profileMuted.withValues(alpha: 0.65),
        ),
        filled: true,
        fillColor: AppTheme.profileSurface.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.profileBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.profileAction, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class ChipOption<T> {
  final T value;
  final String label;
  final String? hint;

  const ChipOption({required this.value, required this.label, this.hint});
}

class ProfileChipGroup<T> extends StatelessWidget {
  final T? selectedValue;
  final List<T> selectedValues;
  final bool multi;
  final List<ChipOption<T>> options;
  final ValueChanged<T>? onChanged;
  final int columns;

  const ProfileChipGroup({
    super.key,
    this.selectedValue,
    this.selectedValues = const [],
    required this.options,
    required this.onChanged,
    this.multi = false,
    this.columns = 2,
  });

  bool _isSelected(T val) {
    if (multi) return selectedValues.contains(val);
    return selectedValue == val;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((opt) {
            final on = _isSelected(opt.value);
            return GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: width,
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: on
                      ? AppTheme.profileSoftSage
                      : AppTheme.profileSurface,

                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: on ? AppTheme.profileAction : AppTheme.profileBorder,
                    width: on ? 1.8 : 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: on
                            ? AppTheme.profileActionDeep
                            : AppTheme.foregroundDark,
                      ),
                    ),
                    if (opt.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        opt.hint!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: on
                              ? AppTheme.profileActionDeep.withValues(
                                  alpha: 0.78,
                                )
                              : AppTheme.profileMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class ProfileSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color tint;

  const ProfileSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 10,
    required this.divisions,
    required this.onChanged,
    this.tint = AppTheme.profileAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              inactiveTrackColor: tint.withValues(alpha: 0.2),
              thumbColor: tint,
              overlayColor: tint.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            value.round().toString(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
