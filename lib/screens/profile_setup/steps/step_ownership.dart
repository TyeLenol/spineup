import 'package:flutter/material.dart';

import '../../../models/profile_data.dart';
import '../profile_fields.dart';

class StepOwnership extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool> onValidityChanged;

  const StepOwnership({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.onValidityChanged,
  });

  @override
  State<StepOwnership> createState() => _StepOwnershipState();
}

class _StepOwnershipState extends State<StepOwnership> {
  late CareSubjectType _subjectType;
  late TextEditingController _relationshipController;

  @override
  void initState() {
    super.initState();
    _subjectType = widget.initialData.ownership.subjectType;
    _relationshipController = TextEditingController(
      text: widget.initialData.ownership.relationship ?? '',
    );
    _relationshipController.addListener(_save);
    _relationshipController.addListener(_validate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _save();
      _validate();
    });
  }

  @override
  void dispose() {
    _relationshipController.dispose();
    super.dispose();
  }

  void _validate() {
    final isValid =
        _subjectType == CareSubjectType.self ||
        _relationshipController.text.trim().isNotEmpty;
    widget.onValidityChanged(isValid);
  }

  void _save() {
    widget.onSave(
      widget.initialData.copyWith(
        ownership: ProfileOwnership(
          subjectType: _subjectType,
          relationship: _subjectType == CareSubjectType.ward
              ? _relationshipController.text.trim()
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWard = _subjectType == CareSubjectType.ward;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileField(
          label: 'Who is this profile for?',
          hint:
              'This keeps the person’s records separate. You can add another person you care for later.',
          child: ProfileChipGroup<CareSubjectType>(
            columns: 1,
            selectedValue: _subjectType,
            onChanged: (value) {
              setState(() => _subjectType = value);
              _save();
              _validate();
            },
            options: const [
              ChipOption(
                value: CareSubjectType.self,
                label: 'Me',
                hint: 'I am setting up my own profile.',
              ),
              ChipOption(
                value: CareSubjectType.ward,
                label: 'Someone I care for',
                hint: 'I am managing a separate profile for another person.',
              ),
            ],
          ),
        ),
        if (isWard) ...[
          const SizedBox(height: 24),
          ProfileField(
            label: 'How are you connected to them?',
            hint:
                'This is stored with the profile so ownership is clear. It does not change their care plan.',
            child: ProfileChipGroup<String>(
              columns: 2,
              selectedValue: _relationshipController.text.trim().isEmpty
                  ? null
                  : _relationshipController.text.trim(),
              onChanged: (value) {
                setState(() => _relationshipController.text = value);
              },
              options: const [
                ChipOption(value: 'Parent', label: 'Parent'),
                ChipOption(value: 'Guardian', label: 'Guardian'),
                ChipOption(value: 'Family member', label: 'Family member'),
                ChipOption(value: 'Caregiver', label: 'Caregiver'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
