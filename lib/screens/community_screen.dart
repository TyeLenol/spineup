import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/community_post.dart';
import '../theme/app_theme.dart';
import '../services/gamification_service.dart';
import '../models/user_profile.dart';
import '../widgets/avatar_display.dart';

const String _kUserId = 'local_user_001';
const String _kUserName = 'You';

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
    final snap = await _gs.getSnapshot('local_user_001'); // Using mock auth ID
    
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

  void _reportPost(String postId) {
    final already = _posts.any((p) => p.id == postId && p.reported);
    if (already) return;

    final report = ModerationReport(
      postId: postId,
      reportedByUserId: _kUserId,
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
      authorName: _kUserName,
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
        authorName: _kUserName,
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            title: Text('Community', style: tt.titleLarge),
            actions: [
              IconButton(
                tooltip: 'New post',
                icon: const Icon(Icons.add_rounded),
                onPressed: _createPost,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final post = _posts[i];
                  return _PostCard(
                    post: post,
                    localSnap: _snap,
                    onUpvote: () => _toggleUpvote(post.id),
                    onReport: () => _reportPost(post.id),
                    onOpenReplies: () => _openReplySheet(post),
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New Post'),
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final GamificationSnapshot localSnap;
  final VoidCallback onUpvote;
  final VoidCallback onReport;
  final VoidCallback onOpenReplies;

  const _PostCard({
    required this.post,
    required this.localSnap,
    required this.onUpvote,
    required this.onReport,
    required this.onOpenReplies,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final isMe = post.authorName == _kUserName;
    final displayProfile = isMe
        ? localSnap.userProfile
        : UserProfile(
            presetId: presetAvatars[post.authorName.hashCode.abs() % presetAvatars.length].id,
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
                    style: tt.labelSmall
                        ?.copyWith(color: AppTheme.mutedForeground),
                  ),
                ],
              ),
              const Spacer(),
              if (!post.reported)
                IconButton(
                  tooltip: 'Report post',
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  color: AppTheme.mutedForeground,
                  onPressed: onReport,
                ),
            ],
          ),

          // Milestone badge
          if (post.milestoneBadge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primarySage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                post.milestoneBadge!,
                style: tt.labelSmall?.copyWith(
                  color: AppTheme.primarySage,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  style: tt.labelSmall
                      ?.copyWith(color: AppTheme.mutedForeground),
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
    return '${diff.inDays}d';
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
            Text(label,
                style: tt.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                )),
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
                    style: tt.bodySmall
                        ?.copyWith(color: AppTheme.mutedForeground),
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
                        style: tt.bodyMedium
                            ?.copyWith(color: AppTheme.mutedForeground),
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
                                  Text(r.authorName,
                                      style: tt.titleSmall),
                                  const Spacer(),
                                  Text(
                                    _timeAgo(r.timestamp),
                                    style: tt.labelSmall?.copyWith(
                                        color: AppTheme.mutedForeground),
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
                            horizontal: 16, vertical: 12),
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
    return '${diff.inDays}d';
  }
}
