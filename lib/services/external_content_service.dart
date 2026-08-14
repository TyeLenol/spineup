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
    ExternalContentItem(
      id: 'curated-nhs-mindfulness-everyday',
      kind: ExternalContentKind.article,
      title: 'Mindfulness for everyday moments',
      summary:
          'A gentle introduction to noticing thoughts, feelings, body sensations, and the world around you.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/',
      contentUrl:
          'https://www.nhs.uk/mental-health/self-help/tips-and-support/mindfulness/',
      category: 'Mindfulness and stress',
      safetyLabel:
          'Wellbeing information only. Mindfulness is not right for everyone; stop if it makes you feel worse and seek appropriate support.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Mindfulness means noticing present-moment thoughts, feelings, body sensations, and surroundings.',
        'The goal is not to force thoughts away; it is to notice when attention wanders and gently return it.',
        'A short, regular practice can be more approachable than trying to be mindful perfectly all day.',
      ],
      sections: const [
        ContentSection(
          heading: 'What mindfulness means',
          body:
              'Mindfulness is paying attention to what is happening inside and around you, moment by moment. It can include noticing sounds, sights, breathing, body sensations, thoughts, and feelings with curiosity rather than immediately judging them.',
        ),
        ContentSection(
          heading: 'Try a low-pressure practice',
          body:
              'Choose an ordinary moment, such as walking, eating, or washing your hands. Notice one or two sensations, name a thought or feeling if it appears, and gently bring your attention back whenever your mind wanders.',
        ),
        ContentSection(
          heading: 'Keep the boundary clear',
          body:
              'Many people find mindfulness useful, but it is not helpful for everyone. It is not a replacement for mental-health care, and you can stop a practice that feels distressing or unsafe.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS mindfulness guidance, not a mental-health treatment plan.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-breathing-stress',
      kind: ExternalContentKind.article,
      title: 'A calm breathing reset',
      summary:
          'A short, practical breathing exercise from the NHS that can be practised in a comfortable position.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/',
      contentUrl:
          'https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/',
      category: 'Mindfulness and stress',
      safetyLabel:
          'A general relaxation exercise, not emergency care or a treatment for panic or another condition. Do not force your breathing.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 3,
      keyTakeaways: const [
        'The exercise can be done sitting, standing, or lying down in a comfortable position.',
        'Let the breath move as deeply as feels comfortable rather than forcing a larger breath.',
        'Some people find a gentle count from 1 to 5 while breathing in and out helpful.',
      ],
      sections: const [
        ContentSection(
          heading: 'A simple reset',
          body:
              'Settle into a supported position and place both feet on the floor if you are sitting or standing. Breathe in gently through your nose and out through your mouth, allowing the breath to move comfortably.',
        ),
        ContentSection(
          heading: 'Practise without pressure',
          body:
              'If counting helps, try counting slowly from 1 to 5 on the inhale and again on the exhale. Continue for a few minutes if it feels comfortable, then return to your normal breathing.',
        ),
        ContentSection(
          heading: 'Use it as one option',
          body:
              'A breathing practice may be a useful pause during a stressful day, but it will not solve every source of stress. If distress is persistent, severe, or affecting daily life, seek appropriate support.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS breathing guidance. It is not a diagnosis, crisis intervention, or personalised breathing prescription.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-five-steps-wellbeing',
      kind: ExternalContentKind.article,
      title: 'Five small steps for mental wellbeing',
      summary:
          'A source-linked overview of connection, movement, learning, kindness, and present-moment awareness.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/',
      contentUrl:
          'https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/five-steps-to-mental-wellbeing/',
      category: 'Mindfulness and stress',
      safetyLabel:
          'General wellbeing information. Choose actions that fit your situation and seek professional help when you need more support.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Connection, physical activity, learning, giving, and present-moment awareness are five practical wellbeing themes.',
        'Small actions that fit everyday life are more useful than a rigid checklist you cannot sustain.',
        'Wellbeing habits complement support from trusted people and qualified professionals; they do not replace it.',
      ],
      sections: const [
        ContentSection(
          heading: 'The five themes',
          body:
              'The NHS describes five broad ways to support wellbeing: connect with people, be physically active, learn something new, give or help others, and pay attention to the present moment.',
        ),
        ContentSection(
          heading: 'Make it realistic',
          body:
              'You do not need to change everything at once. You might message someone you trust, take a short walk, learn a small skill, do one kind thing, or pause to notice what is around you.',
        ),
        ContentSection(
          heading: 'Keep it personal',
          body:
              'Different activities suit different people, bodies, cultures, schedules, and support networks. Use the ideas as prompts, not as a scorecard for whether you are coping well enough.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS wellbeing guidance, not a mental-health assessment or treatment plan.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-sleep-routine',
      kind: ExternalContentKind.article,
      title: 'Sleep as part of self-management',
      summary:
          'Practical NHS guidance on regular routines, winding down, managing worries, and creating a sleep-friendly space.',
      sourceName: 'NHS Every Mind Matters',
      sourceUrl: 'https://www.nhs.uk/every-mind-matters/',
      contentUrl:
          'https://www.nhs.uk/every-mind-matters/mental-wellbeing-tips/how-to-fall-asleep-faster-and-sleep-better/',
      category: 'Rest and recovery',
      safetyLabel:
          'General sleep-habit information. Ongoing or severe sleep problems deserve support from a qualified professional.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Similar bedtimes and wake times can help the body recognise when it is time to sleep.',
        'A calmer wind-down routine can include reading, meditation, breathing exercises, or quiet music.',
        'Managing worries, making the bedroom comfortable, and moving regularly can support better sleep.',
      ],
      sections: const [
        ContentSection(
          heading: 'Build a repeatable rhythm',
          body:
              'Try to keep your bedtime and wake time reasonably consistent, including on days when your schedule changes. A routine can help your body anticipate sleep without requiring perfection.',
        ),
        ContentSection(
          heading: 'Wind down and unload worries',
          body:
              'Give yourself time to relax before bed. If thoughts keep circling, writing down worries or tomorrow\'s tasks may help create a little distance from them.',
        ),
        ContentSection(
          heading: 'Know when to seek help',
          body:
              'Small habit changes may help, but they cannot address every cause of poor sleep. If sleep problems continue or make daily life difficult, speak with a qualified professional.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS Every Mind Matters guidance, not an insomnia diagnosis or treatment plan.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-active-mental-health',
      kind: ExternalContentKind.article,
      title: 'Move at your own pace for mental wellbeing',
      summary:
          'A gentle source-linked guide to using enjoyable movement, realistic goals, and rest to support wellbeing.',
      sourceName: 'NHS Every Mind Matters',
      sourceUrl: 'https://www.nhs.uk/every-mind-matters/',
      contentUrl:
          'https://www.nhs.uk/every-mind-matters/mental-wellbeing-tips/be-active-for-your-mental-health/',
      category: 'Movement and wellbeing',
      safetyLabel:
          'General wellbeing information. Start gently, listen to your body, and check with a qualified professional before a new programme if you have concerns.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 5,
      keyTakeaways: const [
        'Any amount of enjoyable movement can be a useful starting point; you do not have to be an athlete.',
        'Small, realistic goals are easier to repeat than demanding targets that make you want to stop.',
        'Rest, hydration, sleep, pacing, and listening to your body are part of a sustainable routine.',
      ],
      sections: const [
        ContentSection(
          heading: 'Start with what feels possible',
          body:
              'Movement can include walking, stretching, gardening, dancing, yoga, tai chi, Pilates, or another activity you enjoy. A few minutes can be a meaningful beginning when the alternative is doing nothing.',
        ),
        ContentSection(
          heading: 'Make the habit sustainable',
          body:
              'Choose a small goal that fits your routine and increase it only when it feels manageable. A pause or missed day does not erase your progress; it is an opportunity to adjust what works.',
        ),
        ContentSection(
          heading: 'Balance movement with care',
          body:
              'Take breaks, allow time to recover, and stop if something feels wrong. If you have a health condition, take medicines, or are unsure about a new activity, get appropriate advice first.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS Every Mind Matters guidance, not an exercise prescription or mental-health treatment.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-adult-scoliosis-active',
      kind: ExternalContentKind.article,
      title: 'Staying active with adult scoliosis',
      summary:
          'A source-linked overview of movement and professional guidance for adults living with scoliosis.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/',
      contentUrl:
          'https://www.nhs.uk/conditions/scoliosis/treatment-in-adults/',
      category: 'Scoliosis self-management',
      safetyLabel:
          'Educational information only. SpineUp cannot decide which exercise or treatment is suitable for an individual person.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Adults with scoliosis may experience back pain, but not everyone needs treatment if symptoms are not causing problems.',
        'Enjoyable strengthening, stretching, and general movement may help some people manage discomfort and keep moving.',
        'Exercise guidance should be individualised when needed, so discuss a new programme with a qualified professional.',
      ],
      sections: const [
        ContentSection(
          heading: 'The aim is supported movement',
          body:
              'For adults with scoliosis, care may focus on symptoms and day-to-day function. The NHS notes that activities which strengthen and stretch the back may help some people with pain, while general movement can support overall health.',
        ),
        ContentSection(
          heading: 'Do not treat a brief as a prescription',
          body:
              'A general article cannot tell you which movements, intensity, or equipment are right for your body. A physiotherapist, scoliosis specialist, or another qualified professional can help tailor advice when needed.',
        ),
        ContentSection(
          heading: 'Use SpineUp as a conversation aid',
          body:
              'Recording symptoms, activities, and questions can help you describe patterns during a care conversation. It cannot confirm a cause, measure progression, or replace assessment.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS adult-scoliosis guidance, not a treatment recommendation or prediction about an individual curve.',
    ),
    ExternalContentItem(
      id: 'curated-nhs-back-pain-active',
      kind: ExternalContentKind.article,
      title: 'Back discomfort: staying gently active',
      summary:
          'A practical NHS brief on continuing everyday activity, avoiding prolonged bed rest, and knowing when to seek help.',
      sourceName: 'NHS',
      sourceUrl: 'https://www.nhs.uk/',
      contentUrl: 'https://www.nhs.uk/conditions/back-pain/',
      category: 'Pain and movement',
      safetyLabel:
          'General educational information. Stop an activity that makes pain worse and seek appropriate medical help for severe or worrying symptoms.',
      fetchedAt: _seedDate,
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      reviewedAt: _reviewedDate,
      readingMinutes: 4,
      keyTakeaways: const [
        'Back pain is common and often improves over a few weeks, although it can return or last longer.',
        'The NHS generally advises staying active and continuing daily activities rather than remaining in bed for long periods.',
        'Worsening pain, new weakness or numbness, or bladder and bowel changes need prompt professional attention.',
      ],
      sections: const [
        ContentSection(
          heading: 'Keep everyday movement in view',
          body:
              'When back discomfort allows, gentle continuation of ordinary activities may support recovery. Walking, swimming, yoga, Pilates, or other suitable movement can be options, but no single activity is right for everyone.',
        ),
        ContentSection(
          heading: 'Use comfort and response as guides',
          body:
              'Avoid staying in bed for long periods, but do not push through worsening pain. A pharmacist, clinician, or physiotherapist can help you understand suitable options when self-care is not enough.',
        ),
        ContentSection(
          heading: 'Know the safety boundary',
          body:
              'Seek urgent help for severe rapidly worsening pain, or new symptoms such as weakness or numbness in both legs, loss of feeling around the genitals or anus, or changes in bladder or bowel control.',
        ),
      ],
      limitations:
          'This is a concise SpineUp summary of the linked NHS back-pain guidance, not a diagnosis, medication instruction, or personalised exercise plan.',
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
