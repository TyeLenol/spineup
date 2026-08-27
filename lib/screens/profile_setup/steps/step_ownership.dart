import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/profile_data.dart';
import '../../../theme/app_theme.dart';
import '../profile_fields.dart';

class StepOwnership extends StatefulWidget {
  final ProfileData initialData;
  final bool allowSelf;
  final CareSubjectType? lockedSubjectType;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool> onValidityChanged;

  const StepOwnership({
    super.key,
    required this.initialData,
    this.allowSelf = true,
    this.lockedSubjectType,
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
    _subjectType =
        widget.lockedSubjectType ??
        (widget.allowSelf
            ? widget.initialData.ownership.subjectType
            : CareSubjectType.ward);
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
    final options = <ChipOption<CareSubjectType>>[
      if (widget.lockedSubjectType == null && widget.allowSelf)
        const ChipOption(
          value: CareSubjectType.self,
          label: 'Me',
          hint: 'I am setting up my own profile.',
        ),
      if (widget.lockedSubjectType == null ||
          widget.lockedSubjectType == CareSubjectType.ward)
        const ChipOption(
          value: CareSubjectType.ward,
          label: 'Someone I care for',
          hint: 'I am managing a separate profile for another person.',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PrivateSpaceNote(),
        const SizedBox(height: 18),
        ProfileField(
          label: 'Who is this profile for?',
          hint: widget.lockedSubjectType != null
              ? 'This profile’s ownership stays the same while you update its details.'
              : widget.allowSelf
              ? 'This keeps the person’s records separate. You can add another person you care for later.'
              : 'This creates a new separate profile. Your own profile will not be changed.',
          child: ProfileChipGroup<CareSubjectType>(
            columns: 1,
            selectedValue: _subjectType,
            onChanged: widget.lockedSubjectType == null
                ? (value) {
                    setState(() => _subjectType = value);
                    _save();
                    _validate();
                  }
                : null,
            options: options,
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

class _PrivateSpaceNote extends StatelessWidget {
  const _PrivateSpaceNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppTheme.profileWarm.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.profileWarm.withValues(alpha: 0.48)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppTheme.profileAction),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Private by default. Your information starts on this phone, and you choose if or when to export a protected copy.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.profileMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
