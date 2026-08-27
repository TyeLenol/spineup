import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

import '../models/learn_topic.dart';
import '../models/external_content.dart';
import '../services/routine_service.dart';
import 'external_content_screen.dart';
import 'routine_library_screen.dart';
import '../widgets/quick_tour.dart';

class LearnScreen extends StatefulWidget {
  final QuickTourTargetRegistry? tutorialRegistry;

  const LearnScreen({super.key, this.tutorialRegistry});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';
  String _section = 'Topics';
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _query = _searchController.text.trim());
    });
    _scheduleTutorial();
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled || widget.tutorialRegistry == null) return;
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showPageQuickTourIfNeeded(
          context,
          page: QuickTourPage.learn,
          registry: widget.tutorialRegistry!,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final categories = spineUpLearnTopics
        .map((topic) => topic.category)
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<void> _openRoutineLibrary() async {
    final routine = await RoutineService.loadActiveRoutine();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoutineLibraryScreen(currentRoutine: routine),
      ),
    );
  }

  List<LearnTopic> get _filteredTopics {
    final query = _query.toLowerCase();
    return spineUpLearnTopics.where((topic) {
      final categoryMatches = _category == 'All' || topic.category == _category;
      final queryMatches =
          query.isEmpty ||
          topic.title.toLowerCase().contains(query) ||
          topic.shortExplanation.toLowerCase().contains(query) ||
          topic.category.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text('Learn', style: theme.textTheme.titleLarge),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clear guides, trusted sources, and room to explore.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Practice',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  quickTourTarget(
                    registry: widget.tutorialRegistry,
                    page: QuickTourPage.learn,
                    id: 'movement-library',
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _openRoutineLibrary,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                foregroundColor: theme.colorScheme.primary,
                                child: const Icon(Icons.playlist_play_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Movement library and My Routine',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Browse movements, preview guidance, and choose what belongs in your routine.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  quickTourTarget(
                    registry: widget.tutorialRegistry,
                    page: QuickTourPage.learn,
                    id: 'search',
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        hintText: _section == 'Topics'
                            ? 'Search topics'
                            : 'Search external content',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  quickTourTarget(
                    registry: widget.tutorialRegistry,
                    page: QuickTourPage.learn,
                    id: 'sections',
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final section = switch (index) {
                            0 => 'Topics',
                            1 => 'Articles',
                            2 => 'Videos',
                            _ => 'Saved',
                          };
                          final selected = _section == section;
                          return ChoiceChip(
                            label: Text(section),
                            selected: selected,
                            showCheckmark: false,
                            side: BorderSide(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: theme.textTheme.labelLarge?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() {
                              _section = section;
                              _category = 'All';
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_section == 'Topics' && _categories.length > 1) ...[
                    const SizedBox(height: 12),
                    const _LearnFilterDivider(label: 'Filter by topic'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  quickTourTarget(
                    registry: widget.tutorialRegistry,
                    page: QuickTourPage.learn,
                    id: 'topic-list',
                    child: _LearnSectionHeader(
                      label: _section == 'Topics'
                          ? 'Topic guides'
                          : '$_section library',
                      detail: _section == 'Topics'
                          ? '${topics.length} clear, source-linked answers'
                          : 'Curated to keep browsing focused',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_section == 'Topics')
            if (topics.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('No Learn topics match that search.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList.separated(
                  itemCount: topics.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                  itemBuilder: (context, index) =>
                      _LearnTopicCard(topic: topics[index]),
                ),
              )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverToBoxAdapter(
                child: ExternalContentSection(
                  key: ValueKey(_section),
                  kindFilter: switch (_section) {
                    'Articles' => ExternalContentKind.article,
                    'Videos' => ExternalContentKind.video,
                    _ => null,
                  },
                  query: _query,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearnFilterDivider extends StatelessWidget {
  final String label;

  const _LearnFilterDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _LearnSectionHeader extends StatelessWidget {
  final String label;
  final String detail;

  const _LearnSectionHeader({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _LearnTopicCard extends StatelessWidget {
  final LearnTopic topic;

  const _LearnTopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showLearnTopicDetail(context, topic),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: theme.colorScheme.primary,
                child: Icon(_topicIcon(topic.category)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.shortExplanation,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _TopicBadge(label: topic.category),
                        _TopicBadge(label: topic.reviewState.label),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicBadge extends StatelessWidget {
  final String label;

  const _TopicBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: theme.textTheme.labelSmall),
      ),
    );
  }
}

class LearnTopicDetailPage extends StatelessWidget {
  final LearnTopic topic;

  const LearnTopicDetailPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              _TopicBadge(label: topic.category),
              const SizedBox(width: 8),
              _TopicBadge(label: topic.reviewState.label),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            topic.shortExplanation,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            topic.body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'Who this is for',
            icon: Icons.people_outline_rounded,
            child: Text(topic.audience, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Keep in mind',
            icon: Icons.info_outline_rounded,
            child: Text(topic.limitations, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Safety note',
            icon: Icons.health_and_safety_outlined,
            child: Text(topic.safetyNote, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          Text('Sources', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...topic.sources.map((source) => _SourceCard(source: source)),
          const SizedBox(height: 12),
          Text(
            'Last verified: ${_formatDate(topic.lastVerified)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (topic.relatedTopicIds.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Related topics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...topic.relatedTopicIds.map((id) {
              final related = learnTopicById(id);
              if (related == null) return const SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(related.title),
                subtitle: Text(related.shortExplanation),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLearnTopicDetail(context, related),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final LearnSource source;

  const _SourceCard({required this.source});

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: source.url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Source URL copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(source.organization, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(source.title, style: theme.textTheme.bodySmall),
                  if (source.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Author: ${source.author}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  SelectableText(source.url, style: theme.textTheme.labelSmall),
                  if (source.license != null) ...[
                    const SizedBox(height: 4),
                    Text(source.license!, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy source URL',
              onPressed: () => _copyUrl(context),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class ContextualHelpIcon extends StatelessWidget {
  final String topicId;
  final String? tooltip;

  const ContextualHelpIcon({super.key, required this.topicId, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final topic = learnTopicById(topicId);
    if (topic == null) return const SizedBox.shrink();
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip ?? 'Learn about ${topic.title}',
      onPressed: () => _showContextualHelp(context, topic),
      icon: const Icon(Icons.help_outline_rounded, size: 19),
    );
  }
}

void _showContextualHelp(BuildContext context, LearnTopic topic) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              topic.shortExplanation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                Future<void>.delayed(Duration.zero, () {
                  if (context.mounted) showLearnTopicDetail(context, topic);
                });
              },
              child: const Text('Learn more'),
            ),
          ],
        ),
      ),
    ),
  );
}

void showLearnTopicDetail(BuildContext context, LearnTopic topic) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LearnTopicDetailPage(topic: topic)),
  );
}

IconData _topicIcon(String category) {
  switch (category) {
    case 'Measurements':
      return Icons.straighten_rounded;
    case 'Braces':
      return Icons.accessibility_new_rounded;
    case 'Movement':
      return Icons.directions_run_rounded;
    case 'Privacy and portability':
      return Icons.lock_outline_rounded;
    case 'Profile and privacy':
      return Icons.person_outline_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
