import 'package:http/http.dart' as http;
import 'package:rss_dart/dart_rss.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/external_content.dart';
import 'session_service.dart';

class ExternalContentService {
  ExternalContentService._();

  static const _cacheKey = 'spineup_external_content_cache';
  static const _savedKeyPrefix = 'spineup_saved_content_';
  static const _routineKeyPrefix = 'spineup_routine_content_';

  static const _feedSources = [
    (
      url: 'https://medlineplus.gov/feeds/topics/scoliosis.xml',
      name: 'MedlinePlus · Scoliosis',
      category: 'Scoliosis education',
    ),
    (
      url: 'https://medlineplus.gov/feeds/topics/spineinjuriesanddisorders.xml',
      name: 'MedlinePlus · Spine',
      category: 'Spine and back',
    ),
    (
      url: 'https://medlineplus.gov/feeds/topics/backpain.xml',
      name: 'MedlinePlus · Back pain',
      category: 'Pain and movement',
    ),
    (
      url: 'https://patient.info/health/rss',
      name: 'Patient.info · Health guides',
      category: 'Health guides',
    ),
    (
      url: 'https://patient.info/rss',
      name: 'Patient.info · Wellbeing',
      category: 'Mindfulness and wellbeing',
    ),
  ];

  static final curatedItems = <ExternalContentItem>[
    ExternalContentItem(
      id: 'curated-nhs-scoliosis-pilates',
      kind: ExternalContentKind.video,
      title: 'Pilates for scoliosis',
      summary:
          'A 32-minute Pilates-inspired class from the NHS, with explicit exercise safety guidance.',
      sourceName: 'NHS',
      sourceUrl:
          'https://www.nhs.uk/live-well/exercise/pilates-and-yoga/scoliosis-pilates-exercise-video/',
      contentUrl:
          'https://www.nhs.uk/live-well/exercise/pilates-and-yoga/scoliosis-pilates-exercise-video/',
      category: 'Scoliosis movement',
      safetyLabel:
          'External general exercise content. Check that it is suitable for you and stop if you feel pain or become unwell.',
      fetchedAt: _seedDate,
      videoProvider: ExternalVideoProvider.web,
      deliveryMode: ExternalContentDeliveryMode.sourcePage,
      isExerciseVideo: true,
    ),
    ExternalContentItem(
      id: 'curated-srs-dialogues',
      kind: ExternalContentKind.video,
      title: 'Scoliosis Dialogues: SRS podcast',
      summary:
          'Educational scoliosis content from the Scoliosis Research Society.',
      sourceName: 'Scoliosis Research Society',
      sourceUrl: 'https://www.srs.org/',
      contentUrl: 'https://www.youtube.com/watch?v=LrEqpGsaT68',
      category: 'Scoliosis education',
      safetyLabel:
          'External educational content. It is not a personal diagnosis or treatment recommendation.',
      fetchedAt: _seedDate,
      videoId: 'LrEqpGsaT68',
      videoProvider: ExternalVideoProvider.youtube,
      deliveryMode: ExternalContentDeliveryMode.youtubeEmbed,
      thumbnailUrl: 'https://i.ytimg.com/vi/LrEqpGsaT68/hqdefault.jpg',
    ),
    ExternalContentItem(
      id: 'curated-youtube-scoliosis-movement',
      kind: ExternalContentKind.video,
      title: 'Scoliosis exercises for pain and posture',
      summary:
          'A general movement video from a physical therapist and Pilates teacher, shown as an external reference.',
      sourceName: 'YouTube · Jessica Valant Pilates',
      sourceUrl: 'https://www.youtube.com/watch?v=Xc1TuZ_14lQ',
      contentUrl: 'https://www.youtube.com/watch?v=Xc1TuZ_14lQ',
      category: 'Scoliosis movement',
      safetyLabel:
          'External general exercise content. It is not a SpineUp prescription; check suitability and stop if you feel pain or become unwell.',
      fetchedAt: _seedDate,
      videoId: 'Xc1TuZ_14lQ',
      videoProvider: ExternalVideoProvider.youtube,
      deliveryMode: ExternalContentDeliveryMode.youtubeEmbed,
      thumbnailUrl: 'https://i.ytimg.com/vi/Xc1TuZ_14lQ/hqdefault.jpg',
      isExerciseVideo: true,
    ),
    ExternalContentItem(
      id: 'curated-medlineplus-posture',
      kind: ExternalContentKind.article,
      title: 'Guide to good posture',
      summary:
          'A MedlinePlus health topic about posture and back-care information.',
      sourceName: 'MedlinePlus',
      sourceUrl: 'https://medlineplus.gov/',
      contentUrl: 'https://medlineplus.gov/guidetogoodposture.html',
      category: 'Movement and posture',
      safetyLabel:
          'External health information. Use it to prepare questions, not as a substitute for personal care.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Posture is a habit that can be supported with small, comfortable adjustments.',
        'A useful posture is one that lets you breathe and move without unnecessary strain.',
        'Persistent or worrying symptoms should be discussed with a qualified professional.',
      ],
      sections: const [
        ContentSection(
          heading: 'A practical starting point',
          body:
              'Posture is not one rigid position that you must hold all day. A more useful goal is to notice how you sit, stand, and move, then make small adjustments that feel comfortable and sustainable.',
        ),
        ContentSection(
          heading: 'Use this as a conversation starter',
          body:
              'General posture information can help you prepare questions for a clinician, physiotherapist, or other qualified professional. It cannot explain the cause of an individual person\'s symptoms.',
        ),
      ],
      limitations:
          'This is a SpineUp reading brief based on the linked MedlinePlus source, not a diagnosis or treatment plan.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-scoliosis-overview',
      kind: ExternalContentKind.article,
      title: 'Scoliosis: the basics',
      summary:
          'A short SpineUp reading brief based on the NHS scoliosis information page.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/conditions/scoliosis/',
      contentUrl: 'https://www.nhs.uk/conditions/scoliosis/',
      category: 'Scoliosis education',
      safetyLabel:
          'Educational information only. It does not diagnose scoliosis or predict how a curve will change.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 3,
      keyTakeaways: const [
        'Scoliosis describes a sideways curve of the spine.',
        'A clinician is the right person to assess symptoms, measurements, and treatment questions.',
        'A health app can help you record experiences and prepare for conversations; it cannot replace assessment.',
      ],
      sections: const [
        ContentSection(
          heading: 'What this brief covers',
          body:
              'This brief introduces the term scoliosis and explains why personal assessment belongs with a qualified healthcare professional. SpineUp records what a person chooses to track; it does not diagnose or predict progression.',
        ),
        ContentSection(
          heading: 'When to seek help',
          body:
              'If pain, weakness, numbness, breathing difficulty, or other worrying symptoms are new, severe, or worsening, seek appropriate medical advice rather than relying on an app.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS source. Read the original source for the complete information and review date.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-mindfulness',
      kind: ExternalContentKind.article,
      title: 'Mindfulness-based stress reduction exercises',
      summary:
          'NHS information about mindfulness-based stress reduction and guided practice ideas.',
      sourceName: 'Guy\'s and St Thomas\' NHS Foundation Trust',
      sourceUrl: 'https://www.guysandstthomas.nhs.uk/',
      contentUrl:
          'https://www.guysandstthomas.nhs.uk/health-information/mindfulness-based-stress-reduction-mbsr/mbsr-exercises',
      category: 'Mindfulness and stress',
      safetyLabel:
          'External wellbeing information. Mindfulness is not a replacement for help with severe or worsening distress.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 5,
      keyTakeaways: const [
        'Mindfulness exercises can be used as gentle wellbeing practices, not as a substitute for care.',
        'Short, repeatable practices are often easier to fit into a routine than long sessions.',
        'Stop and seek support if an exercise increases distress or feels unsafe.',
      ],
      sections: const [
        ContentSection(
          heading: 'A gentle way to begin',
          body:
              'Mindfulness is the practice of noticing present-moment experience with curiosity. A short breathing or body-awareness exercise can be a low-pressure way to explore whether this kind of practice feels useful for you.',
        ),
        ContentSection(
          heading: 'Keep the boundary clear',
          body:
              'Mindfulness can support wellbeing, but it is not a replacement for professional help with severe, persistent, or worsening distress. Choose a comfortable pace and stop if the exercise feels unhelpful.',
        ),
      ],
      limitations:
          'This is a SpineUp reading brief based on the linked NHS Foundation Trust source, not medical or mental-health treatment.',
    ),
  ];

  static final _seedDate = DateTime(2026, 8, 13);
  static final _reviewedDate = DateTime(2026, 8, 14);

  static Future<List<ExternalContentItem>> loadContent({
    bool refresh = false,
  }) async {
    final cached = await _loadCachedContent();
    final items = <String, ExternalContentItem>{
      for (final item in [...curatedItems, ...cached]) item.id: item,
    };

    if (refresh) {
      final fetched = await _fetchFeeds();
      for (final item in fetched) {
        items[item.id] = item;
      }
      await _saveCachedContent(fetched);
    }

    final result = items.values.toList()
      ..sort((a, b) {
        if (a.isVideo != b.isVideo) return a.isVideo ? -1 : 1;
        final aDate = a.publishedAt ?? a.fetchedAt;
        final bDate = b.publishedAt ?? b.fetchedAt;
        return bDate.compareTo(aDate);
      });
    return result;
  }

  static Future<List<ExternalContentItem>> savedItems() async {
    final all = await loadContent();
    final ids = await _loadIds(_savedKeyPrefix);
    return all.where((item) => ids.contains(item.id)).toList();
  }

  static Future<List<ExternalContentItem>> savedRoutineVideos() async {
    final all = await loadContent();
    final ids = await _loadIds(_routineKeyPrefix);
    return all.where((item) => ids.contains(item.id) && item.isVideo).toList();
  }

  static Future<bool> isSaved(String itemId) async {
    final ids = await _loadIds(_savedKeyPrefix);
    return ids.contains(itemId);
  }

  static Future<bool> isInRoutine(String itemId) async {
    final ids = await _loadIds(_routineKeyPrefix);
    return ids.contains(itemId);
  }

  static Future<void> setSaved(ExternalContentItem item, bool saved) async {
    final ids = await _loadIds(_savedKeyPrefix);
    if (saved) {
      ids.add(item.id);
    } else {
      ids.remove(item.id);
      final routineIds = await _loadIds(_routineKeyPrefix);
      routineIds.remove(item.id);
      await _saveIds(_routineKeyPrefix, routineIds);
    }
    await _saveIds(_savedKeyPrefix, ids);
  }

  static Future<void> setInRoutine(
    ExternalContentItem item,
    bool included,
  ) async {
    if (!item.isVideo) return;
    final ids = await _loadIds(_routineKeyPrefix);
    if (included) {
      ids.add(item.id);
      final savedIds = await _loadIds(_savedKeyPrefix);
      savedIds.add(item.id);
      await _saveIds(_savedKeyPrefix, savedIds);
    } else {
      ids.remove(item.id);
    }
    await _saveIds(_routineKeyPrefix, ids);
  }

  static Future<List<ExternalContentItem>> _fetchFeeds() async {
    final fetched = <ExternalContentItem>[];
    for (final source in _feedSources) {
      try {
        final response = await http
            .get(Uri.parse(source.url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final feed = RssFeed.parse(response.body);
        for (final item in feed.items.take(20)) {
          final title = item.title?.trim();
          final url = item.link?.trim();
          if (title == null || title.isEmpty || url == null || url.isEmpty) {
            continue;
          }
          final summary = _stripMarkup(item.description ?? '');
          if (!_isRelevant('$title $summary')) continue;
          final id = 'feed-${_stableId(url)}';
          fetched.add(
            ExternalContentItem(
              id: id,
              kind: ExternalContentKind.article,
              title: title,
              summary: summary.isEmpty
                  ? 'External health information from ${source.name}.'
                  : summary,
              sourceName: source.name,
              sourceUrl: source.url,
              contentUrl: url,
              category: source.category,
              safetyLabel:
                  'External health information. Review the source and speak with a qualified professional about personal concerns.',
              publishedAt: DateTime.tryParse(item.pubDate ?? ''),
              fetchedAt: DateTime.now(),
              deliveryMode: ExternalContentDeliveryMode.rssDiscovery,
            ),
          );
        }
      } catch (_) {
        // Curated content remains available when a feed is offline or blocked.
      }
    }
    return fetched;
  }

  static Future<List<ExternalContentItem>> _loadCachedContent() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_cacheKey) ?? const [];
    return values
        .map((value) {
          try {
            return ExternalContentItem.decode(value);
          } catch (_) {
            return null;
          }
        })
        .whereType<ExternalContentItem>()
        .toList();
  }

  static Future<void> _saveCachedContent(
    List<ExternalContentItem> items,
  ) async {
    if (items.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadCachedContent();
    final merged = <String, ExternalContentItem>{
      for (final item in [...existing, ...items]) item.id: item,
    };
    final values = merged.values.toList()
      ..sort((a, b) => b.fetchedAt.compareTo(a.fetchedAt));
    await prefs.setStringList(
      _cacheKey,
      values.take(60).map((item) => item.encode()).toList(),
    );
  }

  static Future<Set<String>> _loadIds(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _scopedKey(prefix);
    return (prefs.getStringList(key) ?? const []).toSet();
  }

  static Future<void> _saveIds(String prefix, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scopedKey(prefix), ids.toList());
  }

  static String _scopedKey(String prefix) =>
      '$prefix${SessionService.currentUserId}_${SessionService.currentCareSubjectId}';

  static bool _isRelevant(String value) {
    final lower = value.toLowerCase();
    const keywords = [
      'scoliosis',
      'spine',
      'back',
      'posture',
      'muscle',
      'exercise',
      'mindfulness',
      'stress',
      'wellness',
      'wellbeing',
      'pain',
      'mental health',
      'mindful',
    ];
    return keywords.any(lower.contains);
  }

  static String _stripMarkup(String value) {
    final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _stableId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash << 5) - hash + codeUnit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
