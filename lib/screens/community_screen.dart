import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/community_post.dart';
import '../models/milestone.dart';
import '../theme/app_theme.dart';
import '../services/gamification_service.dart';
import '../services/session_service.dart';
import '../models/user_profile.dart';
import '../widgets/avatar_display.dart';
import '../widgets/badge_icon.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _gs = GamificationService();
  GamificationSnapshot _snap = GamificationSnapshot.empty;
  List<CommunityPost> _posts = [];
  String _feedFilter = 'All'; // 'All' or 'Saved'

  // Moderation queue — stored in memory (would be persisted to SQLite in production).
  final List<ModerationReport> _moderationQueue = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Simulate network delay for fetching community posts
    await Future.delayed(const Duration(milliseconds: 600));
    final snap = await _gs.getSnapshot(SessionService.currentCareSubjectId);

    if (mounted) {
      setState(() {
        _snap = snap;
        _posts = seedCommunityPosts();
      });
    }
  }

  void _toggleUpvote(String postId) {
    setState(() {
      _posts = _posts.map((p) {
        if (p.id != postId) return p;
        final wasUpvoted = p.upvotedByMe;
        return p.copyWith(
          upvotes: wasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
          upvotedByMe: !wasUpvoted,
        );
      }).toList();
    });
  }

  void _toggleSave(String postId) {
    bool nowSaved = false;
    setState(() {
      _posts = _posts.map((p) {
        if (p.id != postId) return p;
        nowSaved = !p.isSaved;
        return p.copyWith(isSaved: nowSaved);
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowSaved ? 'Post saved to bookmarks.' : 'Post removed from saved.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _reportPost(String postId) {
    final already = _posts.any((p) => p.id == postId && p.reported);
    if (already) return;

    final report = ModerationReport(
      postId: postId,
      reportedByUserId: SessionService.currentUserId,
      timestamp: DateTime.now(),
    );
    _moderationQueue.add(report);
    debugPrint('[Moderation Queue] ${report.toJsonString()}');

    setState(() {
      _posts = _posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(reported: true);
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post reported for review. Thank you.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _addReply(String postId, String body) {
    if (body.trim().isEmpty) return;
    final reply = CommunityReply(
      id: const Uuid().v4(),
      authorName: SessionService.displayName,
      body: body.trim(),
      timestamp: DateTime.now(),
    );
    setState(() {
      _posts = _posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(replies: [...p.replies, reply]);
      }).toList();
    });
  }

  void _openReplySheet(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReplySheet(
        post: post,
        onReply: (body) {
          _addReply(post.id, body);
          // Refresh the sheet by rebuilding — post is passed by value so we
          // close and let parent rebuild naturally.
          Navigator.of(ctx).pop();
          // Reopen updated sheet
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              final updated = _posts.firstWhere((p) => p.id == post.id);
              _openReplySheet(updated);
            }
          });
        },
      ),
    );
  }

  Future<void> _createPost() async {
    final bodyCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share with the community'),
        content: TextField(
          controller: bodyCtrl,
          maxLines: 4,
          maxLength: 280,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(bodyCtrl.text),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final newPost = CommunityPost(
        id: const Uuid().v4(),
        authorName: SessionService.displayName,
        body: result.trim(),
        timestamp: DateTime.now(),
        upvotes: 0,
      );
      setState(() => _posts = [newPost, ..._posts]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;
    final displayedPosts = _posts
        .where((p) => _feedFilter == 'All' || p.isSaved)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text('Community', style: tt.titleLarge),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'All',
                    label: Text('All Posts'),
                    icon: Icon(Icons.forum_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'Saved',
                    label: Text('Saved'),
                    icon: Icon(Icons.bookmark_border_rounded, size: 16),
                  ),
                ],
                selected: {_feedFilter},
                onSelectionChanged: (set) =>
                    setState(() => _feedFilter = set.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          if (displayedPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _feedFilter == 'Saved'
                        ? 'No saved posts yet.\nTap the bookmark icon on any post to save it for later!'
                        : 'No community posts yet.',
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final post = displayedPosts[i];
                  return _PostCard(
                    post: post,
                    localSnap: _snap,
                    onUpvote: () => _toggleUpvote(post.id),
                    onSave: () => _toggleSave(post.id),
                    onReport: () => _reportPost(post.id),
                    onOpenReplies: () => _openReplySheet(post),
                  );
                }, childCount: displayedPosts.length),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton.extended(
          onPressed: _createPost,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('New Post'),
        ),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final GamificationSnapshot localSnap;
  final VoidCallback onUpvote;
  final VoidCallback onSave;
  final VoidCallback onReport;
  final VoidCallback onOpenReplies;

  const _PostCard({
    required this.post,
    required this.localSnap,
    required this.onUpvote,
    required this.onSave,
    required this.onReport,
    required this.onOpenReplies,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final isMe = post.authorName == SessionService.displayName;
    final displayProfile = isMe
        ? localSnap.userProfile
        : UserProfile(
            presetId:
                presetAvatars[post.authorName.hashCode.abs() %
                        presetAvatars.length]
                    .id,
            customPhotoPath: null,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCream),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              AvatarDisplay(
                profile: displayProfile,
                size: 36,
                forcePreset: true,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName, style: tt.titleSmall),
                  Text(
                    _timeAgo(post.timestamp),
                    style: tt.labelSmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!post.reported)
                IconButton(
                  tooltip: 'Report post',
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  color: AppTheme.mutedForeground,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onReport,
                ),
            ],
          ),

          // Milestone badge
          if (post.milestoneBadge != null) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (_) {
                final milestone = allMilestones.firstWhere(
                  (m) => m.id == post.milestoneBadge,
                  orElse: () => Milestone(
                    id: 'custom',
                    label: post.milestoneBadge!,
                    iconFamily: 'milestone',
                    tier: 1,
                  ),
                );
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySage.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BadgeIcon(milestone: milestone, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        milestone.label,
                        style: tt.labelSmall?.copyWith(
                          color: AppTheme.primarySage,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 10),

          // Post body
          Text(post.body, style: tt.bodyMedium),
          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              // Upvote
              _ActionChip(
                icon: post.upvotedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.upvotes}',
                color: post.upvotedByMe
                    ? AppTheme.secondaryCoral
                    : AppTheme.mutedForeground,
                onTap: onUpvote,
              ),
              const SizedBox(width: 10),

              // Bookmark / Save
              _ActionChip(
                icon: post.isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: post.isSaved ? 'Saved' : 'Save',
                color: post.isSaved
                    ? AppTheme.primarySage
                    : AppTheme.mutedForeground,
                onTap: onSave,
              ),
              const SizedBox(width: 10),

              // Replies
              _ActionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.replies.length}',
                color: AppTheme.mutedForeground,
                onTap: onOpenReplies,
              ),

              if (post.reported) ...[
                const Spacer(),
                Text(
                  'Reported',
                  style: tt.labelSmall?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(dt);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reply Sheet ──────────────────────────────────────────────────────────────

class _ReplySheet extends StatefulWidget {
  final CommunityPost post;
  final void Function(String body) onReply;

  const _ReplySheet({required this.post, required this.onReply});

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Replies', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    widget.post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),

            // Reply list
            Expanded(
              child: widget.post.replies.isEmpty
                  ? Center(
                      child: Text(
                        'No replies yet. Be the first!',
                        style: tt.bodyMedium?.copyWith(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: widget.post.replies.length,
                      itemBuilder: (_, i) {
                        final r = widget.post.replies[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(r.authorName, style: tt.titleSmall),
                                  const Spacer(),
                                  Text(
                                    _timeAgo(r.timestamp),
                                    style: tt.labelSmall?.copyWith(
                                      color: AppTheme.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(r.body, style: tt.bodyMedium),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Reply input
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Write a reply…',
                        filled: true,
                        fillColor: cs.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => widget.onReply(_ctrl.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(dt);
  }
}
