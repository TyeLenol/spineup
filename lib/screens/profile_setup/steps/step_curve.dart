import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';
import '../profile_fields.dart';

class StepCurve extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool>? onValidityChanged;

  const StepCurve({
    super.key,
    required this.initialData,
    required this.onSave,
    this.onValidityChanged,
  });

  @override
  State<StepCurve> createState() => _StepCurveState();
}

class _StepCurveState extends State<StepCurve> {
  static const double _minAngle = 0;
  static const double _maxAngle = 180;

  late TextEditingController _primaryController;
  late TextEditingController _secondaryController;
  late TextEditingController _risserController;
  CurveType? _curveType;
  String? _primaryError;
  String? _secondaryError;
  bool _advanced = false;
  bool _lastValidity = true;

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
    _primaryError = _angleError(_primaryController.text);
    _secondaryError = _angleError(_secondaryController.text);
    _lastValidity = _primaryError == null && _secondaryError == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onValidityChanged?.call(_lastValidity);
    });

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

  String? _angleError(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed);
    if (value == null || value < _minAngle || value > _maxAngle) {
      return 'Enter a number from 0 to 180°.';
    }
    return null;
  }

  void _save() {
    final primaryText = _primaryController.text.trim();
    final secondaryText = _secondaryController.text.trim();
    final primaryError = _angleError(primaryText);
    final secondaryError = _angleError(secondaryText);
    final p = primaryError == null ? double.tryParse(primaryText) : null;
    final s = secondaryError == null ? double.tryParse(secondaryText) : null;
    final r = int.tryParse(_risserController.text.trim());
    final valid = primaryError == null && secondaryError == null;

    if (mounted &&
        (_primaryError != primaryError || _secondaryError != secondaryError)) {
      setState(() {
        _primaryError = primaryError;
        _secondaryError = secondaryError;
      });
    }
    if (valid != _lastValidity) {
      _lastValidity = valid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onValidityChanged?.call(valid);
      });
    }

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
          hint:
              'Use the number from a clinic report if you have one. SpineUp stores it without interpreting it.',
          child: ProfileTextInput(
            controller: _primaryController,
            labelText: 'Cobb angle',
            hintText: 'e.g. 28',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _primaryError,
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
                        errorText: _secondaryError,
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
