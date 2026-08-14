import 'package:flutter/material.dart';

import '../models/external_content.dart';
import '../models/routine.dart';
import '../services/external_content_service.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';
import 'external_content_screen.dart';

class RoutineLibraryScreen extends StatefulWidget {
  final CareSubjectRoutine currentRoutine;

  const RoutineLibraryScreen({super.key, required this.currentRoutine});

  @override
  State<RoutineLibraryScreen> createState() => _RoutineLibraryScreenState();
}

class _RoutineLibraryScreenState extends State<RoutineLibraryScreen> {
  late CareSubjectRoutine _routine;
  final _searchController = TextEditingController();
  List<ExternalContentItem> _content = const [];
  int _section = 0;
  String _category = 'All';
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _routine = widget.currentRoutine;
    _loadReferenceContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceContent() async {
    final content = await ExternalContentService.loadContent();
    if (!mounted) return;
    setState(() => _content = content);
  }

  Future<void> _saveRoutine() async {
    await RoutineService.saveActiveRoutine(_routine);
    if (!mounted) return;
    setState(() => _changed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('My Routine saved on this device.')),
    );
  }

  void _useTemplate(RoutineTemplate template) {
    setState(() {
      _routine = CareSubjectRoutine(
        name: template.name,
        exerciseIds: [...template.exerciseIds],
      );
      _changed = true;
    });
    _saveRoutine();
  }

  void _addExercise(RoutineExercise exercise) {
    if (_routine.exerciseIds.contains(exercise.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That movement is already in My Routine.'),
        ),
      );
      return;
    }
    setState(() {
      _routine = _routine.copyWith(
        exerciseIds: [..._routine.exerciseIds, exercise.id],
      );
      _changed = true;
    });
    _saveRoutine();
  }

  void _removeExercise(String exerciseId) {
    setState(() {
      _routine = _routine.copyWith(
        exerciseIds: _routine.exerciseIds
            .where((id) => id != exerciseId)
            .toList(),
      );
      _changed = true;
    });
    _saveRoutine();
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    final ids = [..._routine.exerciseIds];
    if (newIndex > oldIndex) newIndex -= 1;
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    setState(() {
      _routine = _routine.copyWith(exerciseIds: ids);
      _changed = true;
    });
    _saveRoutine();
  }

  Future<void> _renameRoutine() async {
    final controller = TextEditingController(text: _routine.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Routine name',
            hintText: 'e.g. Evening movement break',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    setState(() {
      _routine = _routine.copyWith(name: name);
      _changed = true;
    });
    await _saveRoutine();
  }

  void _close() => Navigator.of(context).pop(_changed);

  List<RoutineExercise> get _visibleExercises {
    final query = _searchController.text.trim().toLowerCase();
    return RoutineService.catalog.where((exercise) {
      final categoryMatches =
          _category == 'All' || exercise.category == _category;
      final queryMatches =
          query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.description.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();
  }

  List<String> get _categories {
    final values =
        RoutineService.catalog
            .map((exercise) => exercise.category)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  ExternalContentItem? _referenceVideo(String? id) {
    if (id == null) return null;
    for (final item in _content) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _close();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Routine'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'Save routine',
              onPressed: _saveRoutine,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _sectionPicker(),
            Expanded(
              child: IndexedStack(
                index: _section,
                children: [
                  _buildMyRoutine(),
                  _buildTemplateLibrary(),
                  _buildMovementLibrary(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 0,
            label: Text('My Routine'),
            icon: Icon(Icons.playlist_play_rounded),
          ),
          ButtonSegment(
            value: 1,
            label: Text('Templates'),
            icon: Icon(Icons.auto_awesome_rounded),
          ),
          ButtonSegment(
            value: 2,
            label: Text('Movements'),
            icon: Icon(Icons.search_rounded),
          ),
        ],
        selected: {_section},
        onSelectionChanged: (values) => setState(() => _section = values.first),
      ),
    );
  }

  Widget _buildMyRoutine() {
    final exercises = RoutineService.exercisesForIds(_routine.exerciseIds);
    final totalSeconds = exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.durationSeconds,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _routine.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${exercises.length} movements · ${(totalSeconds / 60).ceil()} min estimated',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rename routine',
                  onPressed: _renameRoutine,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your routine is saved only for the active care profile on this device.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          _emptyRoutine()
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            onReorder: _reorderExercise,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                key: ValueKey(exercise.id),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primarySage.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(exercise.icon, color: AppTheme.primarySage),
                  ),
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.durationLabel} · ${exercise.equipment}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Remove movement',
                        onPressed: () => _removeExercise(exercise.id),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                  onTap: () => _showExerciseDetails(exercise),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _section = 2),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add movement'),
        ),
      ],
    );
  }

  Widget _emptyRoutine() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.playlist_add_rounded, size: 42),
            const SizedBox(height: 10),
            Text(
              'Build a routine that feels right for you',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Start with a template or browse movements to add your own selections.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateLibrary() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Start with a template',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          'Choose a curated starting point, then edit it to make it yours.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 14),
        ...RoutineService.templates.map(_templateCard),
      ],
    );
  }

  Widget _templateCard(RoutineTemplate template) {
    final video = _referenceVideo(template.referenceVideoId);
    final exercises = RoutineService.exercisesForIds(template.exerciseIds);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(
              template.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${exercises.length} movements · ${exercises.map((e) => e.durationSeconds).fold<int>(0, (a, b) => a + b) ~/ 60 + 1} min estimated',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () => _useTemplate(template),
                  child: const Text('Use this routine'),
                ),
                if (video != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExternalContentDetailPage(item: video),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Preview'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementLibrary() {
    final exercises = _visibleExercises;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search movements or equipment',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: category == _category,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${exercises.length} movements',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...exercises.map(_movementCard),
      ],
    );
  }

  Widget _movementCard(RoutineExercise exercise) {
    final inRoutine = _routine.exerciseIds.contains(exercise.id);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primarySage.withValues(alpha: 0.14),
          child: Icon(exercise.icon, color: AppTheme.primarySage),
        ),
        title: Text(exercise.name),
        subtitle: Text(
          '${exercise.category} · ${exercise.durationLabel} · ${exercise.equipment}',
        ),
        trailing: IconButton(
          tooltip: inRoutine ? 'Remove from My Routine' : 'Add to My Routine',
          onPressed: () =>
              inRoutine ? _removeExercise(exercise.id) : _addExercise(exercise),
          icon: Icon(
            inRoutine
                ? Icons.check_circle_rounded
                : Icons.add_circle_outline_rounded,
          ),
          color: inRoutine ? AppTheme.primarySage : null,
        ),
        onTap: () => _showExerciseDetails(exercise),
      ),
    );
  }

  void _showExerciseDetails(RoutineExercise exercise) {
    final inRoutine = _routine.exerciseIds.contains(exercise.id);
    final referenceVideo = _referenceVideo(exercise.videoContentId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primarySage.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      exercise.icon,
                      color: AppTheme.primarySage,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exercise.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(exercise.durationLabel)),
                  Chip(label: Text(exercise.category)),
                  Chip(label: Text(exercise.equipment)),
                  Chip(label: Text(exercise.effort)),
                ],
              ),
              if (referenceVideo != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ExternalContentDetailPage(item: referenceVideo),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Preview movement video'),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'How to try it',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...exercise.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 13, child: Text('${entry.key + 1}')),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.value.stepText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.safetyLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (inRoutine) {
                    _removeExercise(exercise.id);
                  } else {
                    _addExercise(exercise);
                  }
                },
                icon: Icon(
                  inRoutine
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_rounded,
                ),
                label: Text(
                  inRoutine ? 'Remove from My Routine' : 'Add to My Routine',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
