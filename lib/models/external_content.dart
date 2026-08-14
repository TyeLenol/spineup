import 'dart:convert';

enum ExternalContentKind { article, video }

enum ExternalVideoProvider { youtube, web }

enum ExternalContentDeliveryMode {
  curatedBrief,
  rssDiscovery,
  sourcePage,
  youtubeEmbed,
}

class ContentSection {
  final String heading;
  final String body;

  const ContentSection({required this.heading, required this.body});

  Map<String, dynamic> toJson() => {'heading': heading, 'body': body};

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      heading: json['heading'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class ExternalContentItem {
  final String id;
  final ExternalContentKind kind;
  final String title;
  final String summary;
  final String sourceName;
  final String sourceUrl;
  final String contentUrl;
  final String category;
  final String safetyLabel;
  final DateTime? publishedAt;
  final DateTime fetchedAt;
  final String? videoId;
  final ExternalVideoProvider? videoProvider;
  final String? thumbnailUrl;
  final bool isExerciseVideo;
  final ExternalContentDeliveryMode deliveryMode;
  final String? author;
  final DateTime? reviewedAt;
  final int? readingMinutes;
  final List<String> keyTakeaways;
  final List<ContentSection> sections;
  final String? limitations;

  const ExternalContentItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.sourceName,
    required this.sourceUrl,
    required this.contentUrl,
    required this.category,
    required this.safetyLabel,
    required this.fetchedAt,
    this.publishedAt,
    this.videoId,
    this.videoProvider,
    this.thumbnailUrl,
    this.isExerciseVideo = false,
    this.deliveryMode = ExternalContentDeliveryMode.sourcePage,
    this.author,
    this.reviewedAt,
    this.readingMinutes,
    this.keyTakeaways = const [],
    this.sections = const [],
    this.limitations,
  });

  bool get isVideo => kind == ExternalContentKind.video;

  bool get hasCuratedBrief =>
      deliveryMode == ExternalContentDeliveryMode.curatedBrief &&
      sections.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'summary': summary,
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    'contentUrl': contentUrl,
    'category': category,
    'safetyLabel': safetyLabel,
    'publishedAt': publishedAt?.toIso8601String(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'videoId': videoId,
    'videoProvider': videoProvider?.name,
    'thumbnailUrl': thumbnailUrl,
    'isExerciseVideo': isExerciseVideo,
    'deliveryMode': deliveryMode.name,
    'author': author,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'readingMinutes': readingMinutes,
    'keyTakeaways': keyTakeaways,
    'sections': sections.map((section) => section.toJson()).toList(),
    'limitations': limitations,
  };

  String encode() => jsonEncode(toJson());

  factory ExternalContentItem.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'article';
    final providerName = json['videoProvider'] as String?;
    final deliveryName = json['deliveryMode'] as String?;
    final rawTakeaways = json['keyTakeaways'];
    final rawSections = json['sections'];

    return ExternalContentItem(
      id: json['id'] as String,
      kind: ExternalContentKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => ExternalContentKind.article,
      ),
      title: json['title'] as String? ?? 'Untitled content',
      summary: json['summary'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? 'External source',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      contentUrl: json['contentUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'General health',
      safetyLabel:
          json['safetyLabel'] as String? ??
          'External educational content. It is not a personal prescription.',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.now(),
      videoId: json['videoId'] as String?,
      videoProvider: providerName == null
          ? null
          : ExternalVideoProvider.values.firstWhere(
              (value) => value.name == providerName,
              orElse: () => ExternalVideoProvider.web,
            ),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isExerciseVideo: json['isExerciseVideo'] as bool? ?? false,
      deliveryMode: deliveryName == null
          ? (json['videoProvider'] == 'youtube'
                ? ExternalContentDeliveryMode.youtubeEmbed
                : ExternalContentDeliveryMode.sourcePage)
          : ExternalContentDeliveryMode.values.firstWhere(
              (value) => value.name == deliveryName,
              orElse: () => ExternalContentDeliveryMode.sourcePage,
            ),
      author: json['author'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewedAt'] as String? ?? ''),
      readingMinutes: (json['readingMinutes'] as num?)?.toInt(),
      keyTakeaways: rawTakeaways is List
          ? rawTakeaways.whereType<String>().toList()
          : const [],
      sections: rawSections is List
          ? rawSections
                .whereType<Map>()
                .map(
                  (section) => ContentSection.fromJson(
                    Map<String, dynamic>.from(section),
                  ),
                )
                .toList()
          : const [],
      limitations: json['limitations'] as String?,
    );
  }

  factory ExternalContentItem.decode(String value) =>
      ExternalContentItem.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
}
