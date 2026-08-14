import 'package:flutter_test/flutter_test.dart';

import 'package:spineup/models/external_content.dart';
import 'package:spineup/services/external_content_service.dart';

void main() {
  test('external content metadata round-trips without media bytes', () {
    final item = ExternalContentItem(
      id: 'video-1',
      kind: ExternalContentKind.video,
      title: 'A saved video',
      summary: 'A source-linked video.',
      sourceName: 'Example source',
      sourceUrl: 'https://example.com',
      contentUrl: 'https://www.youtube.com/watch?v=abc123',
      category: 'Movement',
      safetyLabel: 'External educational content.',
      fetchedAt: DateTime(2026, 8, 13),
      publishedAt: DateTime(2026, 8, 12),
      videoId: 'abc123',
      videoProvider: ExternalVideoProvider.youtube,
      thumbnailUrl: 'https://i.ytimg.com/vi/abc123/hqdefault.jpg',
      isExerciseVideo: true,
      deliveryMode: ExternalContentDeliveryMode.youtubeEmbed,
    );

    final decoded = ExternalContentItem.decode(item.encode());

    expect(decoded.id, item.id);
    expect(decoded.kind, ExternalContentKind.video);
    expect(decoded.videoId, 'abc123');
    expect(decoded.videoProvider, ExternalVideoProvider.youtube);
    expect(decoded.deliveryMode, ExternalContentDeliveryMode.youtubeEmbed);
    expect(decoded.isExerciseVideo, isTrue);
    expect(decoded.title, item.title);
  });

  test('curated briefs preserve readable sections and metadata', () {
    final item = ExternalContentItem(
      id: 'article-brief',
      kind: ExternalContentKind.article,
      title: 'A reviewed brief',
      summary: 'A concise source-aware brief.',
      sourceName: 'Example source',
      sourceUrl: 'https://example.com/source',
      contentUrl: 'https://example.com/source',
      category: 'Education',
      safetyLabel: 'Educational content.',
      fetchedAt: DateTime(2026, 8, 13),
      deliveryMode: ExternalContentDeliveryMode.curatedBrief,
      readingMinutes: 4,
      keyTakeaways: const ['Takeaway one'],
      sections: const [
        ContentSection(heading: 'A heading', body: 'A readable body.'),
      ],
      limitations: 'A limitation.',
    );

    final decoded = ExternalContentItem.decode(item.encode());

    expect(decoded.hasCuratedBrief, isTrue);
    expect(decoded.readingMinutes, 4);
    expect(decoded.keyTakeaways, ['Takeaway one']);
    expect(decoded.sections.single.heading, 'A heading');
    expect(decoded.limitations, 'A limitation.');
  });

  test('curated catalog includes relevant self-management briefs', () {
    final curatedIds = ExternalContentService.curatedItems
        .where((item) => item.hasCuratedBrief)
        .map((item) => item.id)
        .toSet();

    expect(
      curatedIds,
      containsAll([
        'curated-nhs-mindfulness-everyday',
        'curated-nhs-breathing-stress',
        'curated-nhs-five-steps-wellbeing',
        'curated-nhs-sleep-routine',
        'curated-nhs-active-mental-health',
        'curated-nhs-adult-scoliosis-active',
        'curated-nhs-back-pain-active',
      ]),
    );
    expect(
      ExternalContentService.curatedItems
          .where((item) => item.category == 'Mindfulness and stress')
          .length,
      greaterThanOrEqualTo(4),
    );
  });
}
