import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/external_content.dart';
import '../services/external_content_service.dart';
import '../theme/app_theme.dart';

class ExternalContentSection extends StatefulWidget {
  final ExternalContentKind? kindFilter;
  final String query;

  const ExternalContentSection({
    super.key,
    required this.kindFilter,
    required this.query,
  });

  @override
  State<ExternalContentSection> createState() => _ExternalContentSectionState();
}

class _ExternalContentSectionState extends State<ExternalContentSection> {
  List<ExternalContentItem> _items = const [];
  Set<String> _savedIds = const {};
  Set<String> _routineIds = const {};
  String _category = 'All';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(ExternalContentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kindFilter != widget.kindFilter) {
      _category = 'All';
      _loadContent();
    }
  }

  Future<void> _loadContent({bool refresh = false}) async {
    if (refresh) {
      setState(() => _refreshing = true);
    } else if (_items.isEmpty) {
      setState(() => _loading = true);
    }
    final items = await ExternalContentService.loadContent(refresh: refresh);
    final saved = await ExternalContentService.savedItems();
    final routine = await ExternalContentService.savedRoutineVideos();
    if (!mounted) return;
    setState(() {
      _items = items;
      _savedIds = saved.map((item) => item.id).toSet();
      _routineIds = routine.map((item) => item.id).toSet();
      _loading = false;
      _refreshing = false;
    });
  }

  List<ExternalContentItem> get _visibleItems {
    final query = widget.query.toLowerCase();
    final filtered = _items.where((item) {
      final kindMatches =
          widget.kindFilter == null || item.kind == widget.kindFilter;
      final categoryMatches = _category == 'All' || item.category == _category;
      final queryMatches =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.sourceName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final savedMatches = widget.kindFilter == null
          ? _savedIds.contains(item.id)
          : true;
      return kindMatches && categoryMatches && queryMatches && savedMatches;
    }).toList();
    return filtered;
  }

  List<String> get _categories {
    final categories =
        _items
            .where(
              (item) =>
                  widget.kindFilter == null || item.kind == widget.kindFilter,
            )
            .map((item) => item.category)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories];
  }

  Future<void> _toggleSaved(ExternalContentItem item) async {
    final shouldSave = !_savedIds.contains(item.id);
    await ExternalContentService.setSaved(item, shouldSave);
    if (!mounted) return;
    setState(() {
      final updated = {..._savedIds};
      if (shouldSave) {
        updated.add(item.id);
      } else {
        updated.remove(item.id);
      }
      _savedIds = updated;
      if (!shouldSave) {
        _routineIds = {..._routineIds}..remove(item.id);
      }
    });
  }

  Future<void> _toggleRoutine(ExternalContentItem item) async {
    final shouldInclude = !_routineIds.contains(item.id);
    await ExternalContentService.setInRoutine(item, shouldInclude);
    if (!mounted) return;
    setState(() {
      final updated = {..._routineIds};
      if (shouldInclude) {
        updated.add(item.id);
        _savedIds = {..._savedIds, item.id};
      } else {
        updated.remove(item.id);
      }
      _routineIds = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categories;
    final items = _visibleItems;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_refreshing) const LinearProgressIndicator(minHeight: 2),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ChoiceChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              widget.kindFilter == null
                  ? 'Saved content'
                  : 'From trusted sources',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _refreshing ? null : () => _loadContent(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
            ),
          ],
        ),
        if (items.isEmpty)
          _ExternalContentEmptyState(savedOnly: widget.kindFilter == null)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExternalContentCard(
                item: item,
                saved: _savedIds.contains(item.id),
                inRoutine: _routineIds.contains(item.id),
                onToggleSaved: () => _toggleSaved(item),
                onToggleRoutine: item.isExerciseVideo
                    ? () => _toggleRoutine(item)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class ExternalContentCard extends StatelessWidget {
  final ExternalContentItem item;
  final bool saved;
  final bool inRoutine;
  final VoidCallback onToggleSaved;
  final VoidCallback? onToggleRoutine;

  const ExternalContentCard({
    super.key,
    required this.item,
    required this.saved,
    required this.inRoutine,
    required this.onToggleSaved,
    required this.onToggleRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kindLabel = item.isVideo ? 'VIDEO' : 'ARTICLE';
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExternalContentDetailPage(item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContentThumbnail(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ContentBadge(label: kindLabel),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.sourceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ContentBadge(label: item.category),
                        if (saved) const _ContentBadge(label: 'Saved'),
                        if (inRoutine)
                          const _ContentBadge(label: 'In My Routine'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: saved ? 'Remove saved item' : 'Save item',
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleSaved,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                  if (onToggleRoutine != null)
                    IconButton(
                      tooltip: inRoutine
                          ? 'Remove from My Routine'
                          : 'Add to My Routine',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggleRoutine,
                      icon: Icon(
                        inRoutine
                            ? Icons.playlist_add_check_rounded
                            : Icons.playlist_add_rounded,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExternalContentDetailPage extends StatefulWidget {
  final ExternalContentItem item;

  const ExternalContentDetailPage({super.key, required this.item});

  @override
  State<ExternalContentDetailPage> createState() =>
      _ExternalContentDetailPageState();
}

class _ExternalContentDetailPageState extends State<ExternalContentDetailPage> {
  YoutubePlayerController? _youtubeController;
  bool _saved = false;
  bool _inRoutine = false;

  @override
  void initState() {
    super.initState();
    _loadState();
    final videoId = widget.item.videoId;
    if (widget.item.videoProvider == ExternalVideoProvider.youtube &&
        videoId != null &&
        videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          privacyEnhancedMode: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  Future<void> _loadState() async {
    final saved = await ExternalContentService.isSaved(widget.item.id);
    final routine = await ExternalContentService.isInRoutine(widget.item.id);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _inRoutine = routine;
    });
  }

  Future<void> _toggleSaved() async {
    final next = !_saved;
    await ExternalContentService.setSaved(widget.item, next);
    if (!mounted) return;
    setState(() {
      _saved = next;
      if (!next) _inRoutine = false;
    });
  }

  Future<void> _toggleRoutine() async {
    final next = !_inRoutine;
    await ExternalContentService.setInRoutine(widget.item, next);
    if (!mounted) return;
    setState(() {
      _inRoutine = next;
      if (next) _saved = true;
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.item.contentUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SpineUp could not open that source.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(item.isVideo ? 'Video' : 'Article'),
        actions: [
          IconButton(
            tooltip: _saved ? 'Remove saved item' : 'Save item',
            onPressed: _toggleSaved,
            icon: Icon(
              _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_youtubeController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: YoutubePlayer(
                controller: _youtubeController!,
                aspectRatio: 16 / 9,
              ),
            )
          else if (item.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                item.thumbnailUrl!,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _ExternalMediaPlaceholder(
                  label: 'Open original source',
                  onOpenSource: _openExternal,
                ),
              ),
            )
          else
            _ExternalMediaPlaceholder(
              label: item.isVideo ? 'Watch on source' : 'Open original source',
              onOpenSource: _openExternal,
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContentBadge(label: item.isVideo ? 'VIDEO' : 'ARTICLE'),
              _ContentBadge(label: item.category),
              _ContentBadge(label: 'External source'),
            ],
          ),
          const SizedBox(height: 14),
          Text(item.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            item.summary,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (!item.isVideo) ...[
            const SizedBox(height: 18),
            _ExternalArticleReader(item: item),
          ],
          const SizedBox(height: 14),
          Text(
            item.sourceName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.primarySage,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (item.publishedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Published ${DateFormat.yMMMd().format(item.publishedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _ExternalSafetyCard(label: item.safetyLabel),
          const SizedBox(height: 18),
          if (item.isExerciseVideo)
            FilledButton.icon(
              onPressed: _toggleRoutine,
              icon: Icon(
                _inRoutine
                    ? Icons.playlist_add_check_rounded
                    : Icons.playlist_add_rounded,
              ),
              label: Text(
                _inRoutine ? 'Remove from My Routine' : 'Add to My Routine',
              ),
            ),
          if (item.isExerciseVideo) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              item.isVideo ? 'Open video source' : 'Open article source',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Source link',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            item.contentUrl,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentThumbnail extends StatelessWidget {
  final ExternalContentItem item;

  const _ContentThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          item.thumbnailUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _iconPlaceholder(context),
        ),
      );
    }
    return _iconPlaceholder(context);
  }

  Widget _iconPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        item.isVideo
            ? Icons.play_circle_outline_rounded
            : Icons.article_outlined,
        color: theme.colorScheme.primary,
        size: 30,
      ),
    );
  }
}

class _ContentBadge extends StatelessWidget {
  final String label;

  const _ContentBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(label, style: theme.textTheme.labelSmall),
      ),
    );
  }
}

class _ExternalSafetyCard extends StatelessWidget {
  final String label;

  const _ExternalSafetyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primarySage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primarySage.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ExternalArticleReader extends StatefulWidget {
  final ExternalContentItem item;

  const _ExternalArticleReader({required this.item});

  @override
  State<_ExternalArticleReader> createState() => _ExternalArticleReaderState();
}

class _ExternalArticleReaderState extends State<_ExternalArticleReader> {
  String? _body;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(widget.item.contentUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Source returned ${response.statusCode}.');
      }
      final body = _extractReadableText(response.body);
      if (body.length < 120) {
        throw Exception('This source does not expose readable text here.');
      }
      if (!mounted) return;
      setState(() {
        _body = body;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This source could not be read inside SpineUp right now.';
        _loading = false;
      });
    }
  }

  String _extractReadableText(String html) {
    var source = html;
    final article = RegExp(
      r'<article[\s\S]*?</article>',
      caseSensitive: false,
    ).firstMatch(source);
    if (article != null) source = article.group(0)!;
    source = source.replaceAll(
      RegExp(
        r'<(script|style|nav|header|footer|aside)[^>]*>[\s\S]*?</\1>',
        caseSensitive: false,
      ),
      ' ',
    );
    source = source.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    source = source.replaceAll(
      RegExp(r'</(p|h1|h2|h3|h4|li|section|div)>', caseSensitive: false),
      '\n',
    );
    source = source.replaceAll(RegExp(r'<[^>]+>'), ' ');
    source = source
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'");
    return source
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _loading
          ? const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(child: Text('Loading the source article…')),
              ],
            )
          : _error != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loadArticle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            )
          : Text(
              _body!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
    );
  }
}

class _ExternalMediaPlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback onOpenSource;

  const _ExternalMediaPlaceholder({
    required this.label,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline_rounded, size: 52),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenSource,
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}

class _ExternalContentEmptyState extends StatelessWidget {
  final bool savedOnly;

  const _ExternalContentEmptyState({required this.savedOnly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            savedOnly
                ? Icons.bookmark_border_rounded
                : Icons.library_books_outlined,
            size: 42,
            color: AppTheme.mutedForeground,
          ),
          const SizedBox(height: 10),
          Text(
            savedOnly
                ? 'Nothing saved yet.'
                : 'No content matches this search.',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            savedOnly
                ? 'Save an article or video and it will appear here.'
                : 'Try a different category or search term.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
