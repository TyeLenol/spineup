import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/profile_data.dart';
import '../profile_fields.dart';

class StepBasics extends StatefulWidget {
  final ProfileData initialData;
  final bool isCaregiverMode;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool> onValidityChanged;

  const StepBasics({
    super.key,
    required this.initialData,
    required this.isCaregiverMode,
    required this.onSave,
    required this.onValidityChanged,
  });

  @override
  State<StepBasics> createState() => _StepBasicsState();
}

class _StepBasicsState extends State<StepBasics> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  String _dobIso = '';
  TreatmentStage? _stage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData.basics.displayName,
    );
    _dobIso = widget.initialData.basics.dob;
    _dobController = TextEditingController(text: _formatDisplayDate(_dobIso));
    _stage = widget.initialData.story.treatmentStage;

    _nameController.addListener(_validate);
    _dobController.addListener(_validate);
    _nameController.addListener(_save);
    _dobController.addListener(_save);

    // Initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _formatDisplayDate(String value) {
    if (value.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : DateFormat.yMMMd().format(parsed);
  }

  void _validate() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final dobValid = _dobIso.trim().isNotEmpty;
    final stageValid = _stage != null;
    widget.onValidityChanged(nameValid && dobValid && stageValid);
  }

  void _save() {
    widget.onSave(
      widget.initialData.copyWith(
        basics: ProfileBasics(
          displayName: _nameController.text.trim(),
          dob: _dobIso,
          sex: Sex.none,
        ),
        story: widget.initialData.story.copyWith(treatmentStage: _stage),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant StepBasics oldWidget) {
    super.didUpdateWidget(oldWidget);
    _save();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dobIso = date.toIso8601String().substring(0, 10);
      _dobController.text = DateFormat.yMMMd().format(date);
      _save();
      _validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileField(
          label: widget.isCaregiverMode
              ? 'What should we call them?'
              : 'What should we call you?',
          required: true,
          child: ProfileTextInput(
            controller: _nameController,
            labelText: 'Name',
            hintText: widget.isCaregiverMode
                ? 'Their first name or nickname'
                : 'Your first name or nickname',
          ),
        ),
        const SizedBox(height: 24),
        ProfileField(
          label: widget.isCaregiverMode
              ? 'Their date of birth'
              : 'Date of birth',
          required: true,
          hint:
              'Used only to present age-appropriate information and recordkeeping.',
          child: GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: ProfileTextInput(
                controller: _dobController,
                labelText: 'Birth Date',
                hintText: 'Select your birth date',
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        ProfileField(
          label: widget.isCaregiverMode
              ? 'Where are they in their journey?'
              : 'Where are you in your journey?',
          required: true,
          hint: 'Shapes tracking and reminders. You can change this any time.',
          child: ProfileChipGroup<TreatmentStage>(
            columns: 1,
            selectedValue: _stage,
            onChanged: (v) {
              setState(() => _stage = v);
              _save();
              _validate();
            },
            options: const [
              ChipOption(
                value: TreatmentStage.observation,
                label: 'Being monitored',
                hint: 'Watch-and-wait, no brace yet',
              ),
              ChipOption(
                value: TreatmentStage.bracing,
                label: 'Wearing a brace',
              ),
              ChipOption(
                value: TreatmentStage.preOp,
                label: 'Preparing for surgery',
              ),
              ChipOption(
                value: TreatmentStage.postOp,
                label: 'Recovering from surgery',
              ),
              ChipOption(
                value: TreatmentStage.adult,
                label: 'Adult with scoliosis',
              ),
              ChipOption(value: TreatmentStage.unsure, label: 'Not sure yet'),
            ],
          ),
        ),
      ],
    );
  }
}
