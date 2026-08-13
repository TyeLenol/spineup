import 'package:flutter/material.dart';

import '../../../models/profile_data.dart';
import '../profile_fields.dart';

class StepGoals extends StatefulWidget {
  final ProfileData initialData;
  final ValueChanged<ProfileData> onSave;
  final ValueChanged<bool> onValidityChanged;

  const StepGoals({
    super.key,
    required this.initialData,
    required this.onSave,
    required this.onValidityChanged,
  });

  @override
  State<StepGoals> createState() => _StepGoalsState();
}

class _StepGoalsState extends State<StepGoals> {
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _goals = List.from(widget.initialData.goals);

    WidgetsBinding.instance.addPostFrameCallback((_) => _validate());
  }

  void _validate() {
    widget.onValidityChanged(_goals.isNotEmpty);
  }

  void _toggle(Goal g) {
    setState(() {
      if (_goals.contains(g)) {
        _goals.remove(g);
      } else {
        _goals.add(g);
      }
    });
    _validate();
    _save();
  }

  void _save() {
    widget.onSave(
      widget.initialData.copyWith(goals: _goals, completedAt: DateTime.now()),
    );
  }

  @override
  void didUpdateWidget(covariant StepGoals oldWidget) {
    super.didUpdateWidget(oldWidget);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileField(
          label: 'Your goals (choose one or more)',
          child: ProfileChipGroup<Goal>(
            multi: true,
            columns: 1,
            selectedValues: _goals,
            onChanged: _toggle,
            options: const [
              ChipOption(
                value: Goal.reducePain,
                label: 'Reduce pain',
                hint: 'Gentler days, better sleep',
              ),
              ChipOption(
                value: Goal.braceHours,
                label: 'Hit my brace-hour targets',
              ),
              ChipOption(
                value: Goal.ptConsistency,
                label: 'Stay consistent with physio',
              ),
              ChipOption(value: Goal.prepSurgery, label: 'Prepare for surgery'),
              ChipOption(
                value: Goal.trackProgression,
                label: 'Track how my curve is changing',
              ),
              ChipOption(
                value: Goal.exploring,
                label: 'Just exploring for now',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
