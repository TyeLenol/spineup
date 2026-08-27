import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_profile.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/dicebear_avatar.dart';

class AvatarStudioScreen extends StatefulWidget {
  final String userId;
  final UserProfile profile;
  final GamificationService gamificationService;

  const AvatarStudioScreen({
    super.key,
    required this.userId,
    required this.profile,
    required this.gamificationService,
  });

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  late String _styleId;
  late Map<String, String> _selections;
  late String _avatarMode;
  late String? _photoPath;
  late final String _seed;
  bool _dirty = false;
  bool _saving = false;

  AvatarStyleDefinition get _definition =>
      avatarStyleDefinitionFor(_styleId) ?? avatarStyleDefinitions.first;

  UserProfile get _previewProfile => UserProfile(
    presetId: widget.profile.presetId,
    customPhotoPath: _photoPath,
    avatarStyleId: _styleId,
    avatarOptions: _selections,
    avatarSeed: _seed,
    avatarMode: _avatarMode,
    name: widget.profile.name,
    diagnosis: widget.profile.diagnosis,
    braceStatus: widget.profile.braceStatus,
    ageRange: widget.profile.ageRange,
  );

  @override
  void initState() {
    super.initState();
    final requestedStyle = avatarStyleDefinitionFor(
      widget.profile.avatarStyleId,
    );
    _styleId = requestedStyle?.id ?? avatarStyleDefinitions.first.id;
    _selections = {
      ..._definition.defaults,
      if (widget.profile.avatarStyleId == _styleId)
        ...widget.profile.avatarOptions,
    };
    _avatarMode =
        widget.profile.avatarMode == 'preset' &&
            widget.profile.customPhotoPath == null
        ? 'illustrated'
        : widget.profile.avatarMode;
    _photoPath = widget.profile.customPhotoPath;
    _seed = widget.profile.avatarSeed == 'spineup-avatar'
        ? 'spineup-${widget.userId}'
        : widget.profile.avatarSeed;
  }

  Future<void> _handleBack() async {
    if (await _confirmExit() && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmExit() async {
    if (!_dirty || _saving) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('Your avatar changes have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard changes'),
          ),
        ],
      ),
    );
    return shouldLeave == true;
  }

  void _selectStyle(String styleId) {
    if (styleId == _styleId) return;
    final definition = avatarStyleDefinitionFor(styleId);
    if (definition == null) return;
    setState(() {
      _styleId = styleId;
      _selections = {...definition.defaults};
      _avatarMode = 'illustrated';
      _dirty = true;
    });
  }

  void _selectFeature(AvatarFeature feature, String value) {
    setState(() {
      _selections[feature.id] = value;
      _avatarMode = 'illustrated';
      _dirty = true;
    });
  }

  void _randomize() {
    final random = Random();
    final next = <String, String>{};
    for (final feature in _definition.features) {
      final values = [
        if (feature.canBeNone) const AvatarChoice(id: 'none', label: 'None'),
        ...feature.choices,
      ];
      next[feature.id] = values[random.nextInt(values.length)].id;
    }
    setState(() {
      _selections = next;
      _avatarMode = 'illustrated';
      _dirty = true;
    });
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final sizeBytes = await file.length();
    if (sizeBytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image is too large (cap is ~5MB).')),
      );
      return;
    }

    setState(() {
      _photoPath = pickedFile.path;
      _avatarMode = 'photo';
      _dirty = true;
    });
  }

  void _useIllustratedAvatar() {
    setState(() {
      _avatarMode = 'illustrated';
      _dirty = true;
    });
  }

  void _removePhoto() {
    setState(() {
      _photoPath = null;
      _avatarMode = 'illustrated';
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.gamificationService.updateProfile(
        userId: widget.userId,
        presetId: widget.profile.presetId,
        customPhotoPath: _photoPath,
        clearCustomPhotoPath: _photoPath == null,
        avatarMode: _avatarMode,
        avatarStyleId: _styleId,
        avatarOptions: _selections,
        avatarSeed: _seed,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: AppTheme.profileCanvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Avatar Studio'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _PreviewCard(
                profile: _previewProfile,
                definition: _definition,
                mode: _avatarMode,
              ),
              const SizedBox(height: 18),
              Text(
                'Make this care space yours',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.foregroundDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your avatar is created and saved on this device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel(label: 'Choose a style'),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatarStyleDefinitions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final definition = avatarStyleDefinitions[index];
                    final selected = definition.id == _styleId;
                    return _StyleCard(
                      definition: definition,
                      selected: selected,
                      seed: _seed,
                      onTap: () => _selectStyle(definition.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Personalize it'),
              const SizedBox(height: 10),
              ..._definition.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _FeatureRow(
                    feature: feature,
                    definition: _definition,
                    seed: _seed,
                    selections: _selections,
                    onSelected: (value) => _selectFeature(feature, value),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _randomize,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Randomize this style'),
              ),
              const SizedBox(height: 18),
              _PhotoSection(
                profile: _previewProfile,
                onPick: _pickPhoto,
                onUseIllustrated: _useIllustratedAvatar,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: 18),
              Text(
                _definition.credit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save avatar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final UserProfile profile;
  final AvatarStyleDefinition definition;
  final String mode;

  const _PreviewCard({
    required this.profile,
    required this.definition,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        children: [
          Container(
            width: 190,
            height: 190,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryCoral.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AvatarDisplay(profile: profile, size: 166),
          ),
          const SizedBox(height: 12),
          Text(
            mode == 'photo' ? 'Your local photo' : definition.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final AvatarStyleDefinition definition;
  final bool selected;
  final String seed;
  final VoidCallback onTap;

  const _StyleCard({
    required this.definition,
    required this.selected,
    required this.seed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentLavender.withValues(alpha: 0.16)
              : cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.accentLavender : AppTheme.borderCream,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: DiceBearAvatar(
                styleId: definition.id,
                seed: seed,
                selections: definition.defaults,
                size: 72,
              ),
            ),
            Text(
              definition.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? AppTheme.accentLavender : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final AvatarFeature feature;
  final AvatarStyleDefinition definition;
  final String seed;
  final Map<String, String> selections;
  final ValueChanged<String> onSelected;

  const _FeatureRow({
    required this.feature,
    required this.definition,
    required this.seed,
    required this.selections,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final current = selections[feature.id] ?? definition.defaults[feature.id];
    final choices = [
      if (feature.canBeNone) const AvatarChoice(id: 'none', label: 'None'),
      ...feature.choices,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: choices.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final choice = choices[index];
              final selected = choice.id == current;
              final preview = choice.id == 'none'
                  ? selections
                  : {...selections, feature.id: choice.id};
              return InkWell(
                onTap: () => onSelected(choice.id),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 70,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.secondaryCoral.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.secondaryCoral
                          : AppTheme.borderCream,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: choice.id == 'none'
                            ? const Icon(Icons.block_outlined, size: 30)
                            : DiceBearAvatar(
                                styleId: definition.id,
                                seed: seed,
                                selections: preview,
                                size: 48,
                              ),
                      ),
                      Text(
                        choice.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onPick;
  final VoidCallback onUseIllustrated;
  final VoidCallback onRemove;

  const _PhotoSection({
    required this.profile,
    required this.onPick,
    required this.onUseIllustrated,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.customPhotoPath != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prefer a photo?',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('Photos stay on this device too.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhoto ? 'Replace photo' : 'Use a photo'),
              ),
              if (profile.avatarMode == 'photo' && hasPhoto)
                TextButton(
                  onPressed: onUseIllustrated,
                  child: const Text('Use illustrated avatar'),
                ),
              if (hasPhoto)
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove photo'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppTheme.foregroundDark,
      ),
    );
  }
}
