import 'package:flutter/material.dart';
import '../../../models/profile_data.dart';
import '../profile_fields.dart';

class StepCare extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool> onValidityChanged;

  const StepCare({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.onValidityChanged,
  });

  @override
  State<StepCare> createState() => _StepCareState();
}

class _StepCareState extends State<StepCare> {
  bool? _wears;
  BraceType? _type;
  late TextEditingController _hoursController;
  PtMethod? _method;

  @override
  void initState() {
    super.initState();
    _wears = widget.initialData.brace.wears;
    _type = widget.initialData.brace.type;
    _hoursController = TextEditingController(text: widget.initialData.brace.hoursPerDay?.toString() ?? '');
    _method = widget.initialData.pt.method;

    _hoursController.addListener(_save);

    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  void _validate() {
    final valid = _wears != null;
    widget.onValidityChanged(valid);
  }

  void _save() {
    final h = double.tryParse(_hoursController.text.trim());

    widget.onSave(widget.initialData.copyWith(
      brace: _wears == true
          ? ProfileBrace(
              wears: true,
              type: _type,
              hoursPerDay: h,
            )
          : const ProfileBrace(
              wears: false,
              type: BraceType.none,
            ),
      pt: ProfilePt(method: _method),
    ));
  }

  @override
  void didUpdateWidget(covariant StepCare oldWidget) {
    super.didUpdateWidget(oldWidget);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileField(
          label: 'Do you currently wear a brace?',
          required: true,
          child: ProfileChipGroup<bool>(
            columns: 2,
            selectedValue: _wears,
            onChanged: (v) {
              setState(() => _wears = v);
              _validate();
              _save();
            },
            options: const [
              ChipOption(value: true, label: 'Yes'),
              ChipOption(value: false, label: 'No'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _wears == true
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileField(
                      label: 'Brace type',
                      child: ProfileChipGroup<BraceType>(
                        columns: 2,
                        selectedValue: _type,
                        onChanged: (v) {
                          setState(() => _type = v);
                          _save();
                        },
                        options: const [
                          ChipOption(value: BraceType.boston, label: 'Boston'),
                          ChipOption(value: BraceType.rigoCheneau, label: 'Rigo-Chêneau'),
                          ChipOption(value: BraceType.providence, label: 'Providence', hint: 'Night-time'),
                          ChipOption(value: BraceType.spinecor, label: 'SpineCor', hint: 'Soft brace'),
                          ChipOption(value: BraceType.other, label: 'Other'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProfileField(
                      label: 'Prescribed hours per day',
                      hint: 'Whatever your doctor recommended.',
                      child: ProfileTextInput(
                        controller: _hoursController,
                        labelText: 'Prescribed Hours',
                        hintText: 'e.g. 20',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        ProfileField(
          label: 'Physio method (optional)',
          hint: 'If you\'re following a specific scoliosis exercise approach.',
          child: ProfileChipGroup<PtMethod>(
            columns: 1,
            selectedValue: _method,
            onChanged: (v) {
              setState(() => _method = v);
              _save();
            },
            options: const [
              ChipOption(value: PtMethod.schroth, label: 'Schroth', hint: 'Curve-specific breathing & posture'),
              ChipOption(value: PtMethod.seas, label: 'SEAS', hint: 'Scientific Exercise Approach to Scoliosis'),
              ChipOption(value: PtMethod.otherPsse, label: 'Other PSSE method'),
              ChipOption(value: PtMethod.none, label: 'General physio / stretches'),
              ChipOption(value: PtMethod.unsure, label: 'Not sure'),
            ],
          ),
        ),
      ],
    );
  }
}
