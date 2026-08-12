import 'dart:convert';

/// A single reply within a community post thread.
class CommunityReply {
  final String id;
  final String authorName;
  final String body;
  final DateTime timestamp;

  const CommunityReply({
    required this.id,
    required this.authorName,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CommunityReply.fromJson(Map<String, dynamic> j) => CommunityReply(
        id: j['id'] as String,
        authorName: j['authorName'] as String,
        body: j['body'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

/// A community post with upvotes, replies, and report state.
class CommunityPost {
  final String id;
  final String authorName;

  /// Optional milestone badge text (e.g. "🏅 7-Day Streak!").
  final String? milestoneBadge;
  final String body;
  final DateTime timestamp;
  final int upvotes;
  final bool upvotedByMe;
  final List<CommunityReply> replies;
  final bool reported;
  final bool isSaved;

  const CommunityPost({
    required this.id,
    required this.authorName,
    this.milestoneBadge,
    required this.body,
    required this.timestamp,
    this.upvotes = 0,
    this.upvotedByMe = false,
    this.replies = const [],
    this.reported = false,
    this.isSaved = false,
  });

  CommunityPost copyWith({
    String? id,
    String? authorName,
    String? milestoneBadge,
    String? body,
    DateTime? timestamp,
    int? upvotes,
    bool? upvotedByMe,
    List<CommunityReply>? replies,
    bool? reported,
    bool? isSaved,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      milestoneBadge: milestoneBadge ?? this.milestoneBadge,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      upvotes: upvotes ?? this.upvotes,
      upvotedByMe: upvotedByMe ?? this.upvotedByMe,
      replies: replies ?? this.replies,
      reported: reported ?? this.reported,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'milestoneBadge': milestoneBadge,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'upvotes': upvotes,
        'upvotedByMe': upvotedByMe,
        'replies': replies.map((r) => r.toJson()).toList(),
        'reported': reported,
        'isSaved': isSaved,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: j['id'] as String,
        authorName: j['authorName'] as String,
        milestoneBadge: j['milestoneBadge'] as String?,
        body: j['body'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        upvotes: (j['upvotes'] as int?) ?? 0,
        upvotedByMe: (j['upvotedByMe'] as bool?) ?? false,
        replies: (j['replies'] as List<dynamic>?)
                ?.map((r) =>
                    CommunityReply.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        reported: (j['reported'] as bool?) ?? false,
        isSaved: (j['isSaved'] as bool?) ?? false,
      );
}

// Seed data so the feed is not empty on first open.
List<CommunityPost> seedCommunityPosts() {
  final now = DateTime.now();
  return [
    CommunityPost(
      id: 'post_seed_1',
      authorName: 'Maya K.',
      milestoneBadge: 'streak_tier2',
      body: 'Two weeks straight. My physio actually noticed a difference in '
          'my posture yesterday — first time in months I felt genuinely proud '
          'of something spine-related.',
      timestamp: now.subtract(const Duration(hours: 2)),
      upvotes: 24,
      replies: [
        CommunityReply(
          id: 'reply_seed_1_1',
          authorName: 'Jordan T.',
          body: "That's HUGE, Maya. Congrats 🎉",
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
      ],
    ),
    CommunityPost(
      id: 'post_seed_2',
      authorName: 'Remi B.',
      body: 'Anyone else find the cat-cow stretch actually helps with morning '
          'stiffness? Used to take 20 min before I could walk properly. Now '
          "it's more like 5.",
      timestamp: now.subtract(const Duration(hours: 6)),
      upvotes: 11,
      replies: [],
    ),
    CommunityPost(
      id: 'post_seed_3',
      authorName: 'Priya S.',
      milestoneBadge: 'angle_tier1',
      body: 'Finally figured out how to use the Cobb angle tool. My curve '
          'went from 32° to 29° over 3 months. Not sure what to feel — '
          'happy but also still processing it.',
      timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      upvotes: 38,
      replies: [
        CommunityReply(
          id: 'reply_seed_3_1',
          authorName: 'Sam L.',
          body: '3 degrees in 3 months is genuinely really good. Be proud.',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        CommunityReply(
          id: 'reply_seed_3_2',
          authorName: 'Maya K.',
          body: "I'm still processing my numbers too. It's weirdly emotional.",
          timestamp: now.subtract(const Duration(days: 1, hours: 1)),
        ),
      ],
    ),
    CommunityPost(
      id: 'post_seed_4',
      authorName: 'Chris N.',
      body: 'Missed 3 days because of a flare-up. Starting over. Not giving up.',
      timestamp: now.subtract(const Duration(days: 2)),
      upvotes: 57,
      replies: [],
    ),
  ];
}

/// A report entry written to the local moderation queue.
class ModerationReport {
  final String postId;
  final String reportedByUserId;
  final DateTime timestamp;

  const ModerationReport({
    required this.postId,
    required this.reportedByUserId,
    required this.timestamp,
  });

  String toJsonString() => jsonEncode({
        'postId': postId,
        'reportedByUserId': reportedByUserId,
        'timestamp': timestamp.toIso8601String(),
      });
}
