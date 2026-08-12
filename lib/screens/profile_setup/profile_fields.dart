import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../learn_screen.dart';

class ProfileField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helpTopicId;
  final Widget child;

  const ProfileField({
    super.key,
    required this.label,
    this.hint,
    this.helpTopicId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.foregroundDark,
                ),
              ),
            ),
            if (helpTopicId != null)
              ContextualHelpIcon(
                topicId: helpTopicId!,
                tooltip: 'Learn about $label',
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedForeground,
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

  const ProfileTextInput({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.foregroundDark,
      ),
      decoration: InputDecoration(
        labelText: labelText ?? hintText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.5,
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
  final ValueChanged<T> onChanged;
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
        final spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((opt) {
            final on = _isSelected(opt.value);
            return GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: width,
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: on
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: on
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: on ? 2.5 : 1.5,
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
                        fontWeight: FontWeight.w600,
                        color: on
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (opt.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        opt.hint!,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: on
                              ? Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
    this.tint = AppTheme.secondaryCoral,
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
