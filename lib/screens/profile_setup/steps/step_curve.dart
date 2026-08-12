import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';
import '../profile_fields.dart';

class StepCurve extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;

  const StepCurve({super.key, required this.initialData, required this.onSave});

  @override
  State<StepCurve> createState() => _StepCurveState();
}

class _StepCurveState extends State<StepCurve> {
  late TextEditingController _primaryController;
  late TextEditingController _secondaryController;
  late TextEditingController _risserController;
  CurveType? _curveType;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _primaryController = TextEditingController(
      text: widget.initialData.curve.cobbPrimary?.toString() ?? '',
    );
    _secondaryController = TextEditingController(
      text: widget.initialData.curve.cobbSecondary?.toString() ?? '',
    );
    _risserController = TextEditingController(
      text: widget.initialData.curve.risser?.toString() ?? '',
    );
    _curveType = widget.initialData.curve.curveType;

    _primaryController.addListener(_save);
    _secondaryController.addListener(_save);
    _risserController.addListener(_save);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _risserController.dispose();
    super.dispose();
  }

  void _save() {
    final p = double.tryParse(_primaryController.text.trim());
    final s = double.tryParse(_secondaryController.text.trim());
    final r = int.tryParse(_risserController.text.trim());

    widget.onSave(
      widget.initialData.copyWith(
        curve: ProfileCurve(
          cobbPrimary: p,
          cobbSecondary: s,
          curveType: _curveType,
          risser: r,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant StepCurve oldWidget) {
    super.didUpdateWidget(oldWidget);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileField(
          label: 'Primary Cobb angle (°)',
          helpTopicId: 'cobb-angle',
          hint: 'The main curve angle from your X-ray.',
          child: ProfileTextInput(
            controller: _primaryController,
            labelText: 'Cobb Angle',
            hintText: 'e.g. 28',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(height: 24),
        ProfileField(
          label: 'Curve pattern',
          child: ProfileChipGroup<CurveType>(
            columns: 1,
            selectedValue: _curveType,
            onChanged: (v) {
              setState(() => _curveType = v);
              _save();
            },
            options: const [
              ChipOption(
                value: CurveType.thoracic,
                label: 'Thoracic (upper back)',
              ),
              ChipOption(value: CurveType.lumbar, label: 'Lumbar (lower back)'),
              ChipOption(
                value: CurveType.thoracolumbar,
                label: 'Thoracolumbar (mid)',
              ),
              ChipOption(value: CurveType.doubleS, label: 'Double / S-shaped'),
              ChipOption(value: CurveType.unsure, label: 'Not sure'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _advanced = !_advanced),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _advanced ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: AppTheme.primarySage,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Advanced clinical details',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primarySage,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _advanced
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    ProfileField(
                      label: 'Secondary Cobb angle (°)',
                      hint: 'If you have a compensatory curve.',
                      child: ProfileTextInput(
                        controller: _secondaryController,
                        labelText: 'Secondary Cobb',
                        hintText: 'e.g. 18',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProfileField(
                      label: 'Risser sign (0–5)',
                      hint: 'Skeletal maturity marker from your X-ray.',
                      child: ProfileTextInput(
                        controller: _risserController,
                        labelText: 'Risser Sign',
                        hintText: '0–5',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
