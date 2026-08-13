import 'dart:convert';

enum ExternalContentKind { article, video }

enum ExternalVideoProvider { youtube, web }

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
  });

  bool get isVideo => kind == ExternalContentKind.video;

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
  };

  String encode() => jsonEncode(toJson());

  factory ExternalContentItem.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'article';
    final providerName = json['videoProvider'] as String?;
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
    );
  }

  factory ExternalContentItem.decode(String value) =>
      ExternalContentItem.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
}
