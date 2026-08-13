import 'package:flutter_test/flutter_test.dart';

import 'package:spineup/models/external_content.dart';

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
    );

    final decoded = ExternalContentItem.decode(item.encode());

    expect(decoded.id, item.id);
    expect(decoded.kind, ExternalContentKind.video);
    expect(decoded.videoId, 'abc123');
    expect(decoded.videoProvider, ExternalVideoProvider.youtube);
    expect(decoded.isExerciseVideo, isTrue);
    expect(decoded.title, item.title);
  });
}
