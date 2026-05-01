import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/cdn_config.dart';
import '../core/time_utils.dart';
import '../models/help_comment.dart';
import '../models/help_post.dart';
import '../models/member.dart';
import '../services/help_feed_service.dart';
import '../services/member_repository.dart';
import 'member_details_screen.dart';
import 'post_new_request_screen.dart';

class HelpFeedScreen extends StatefulWidget {
  const HelpFeedScreen({
    required this.currentUser,
    required this.helpFeedService,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final HelpFeedService helpFeedService;
  final MemberRepository repository;

  @override
  State<HelpFeedScreen> createState() => _HelpFeedScreenState();
}

class _HelpFeedScreenState extends State<HelpFeedScreen> {
  static const List<String> _helpCategories = <String>[
    'Emergency',
    'Medical',
    'Accident',
    'Financial',
    'Travel',
    'Other',
  ];
  final Map<String, String> _avatarUrlByMobile = <String, String>{};
  final Set<String> _avatarLookupInFlight = <String>{};

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final posts = widget.helpFeedService.posts;

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(isHindi ? 'मदद फीड' : 'Help Feed'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'help-feed-post-fab',
        onPressed: _createHelpPost,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(isHindi ? 'नई रिक्वेस्ट' : 'Post Request'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF6F9FC), Color(0xFFEFF5F0)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                isHindi ? 'हाल की मदद रिक्वेस्ट' : 'Recent help requests',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (posts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    isHindi
                        ? 'अभी कोई रिक्वेस्ट नहीं है। पहली मदद पोस्ट करें।'
                        : 'No requests yet. Share the first update to activate nearby support.',
                  ),
                ),
              ),
            ...posts.map(_buildHelpPostCard),
          ],
        ),
      ),
    );
  }

  String _timestampLabel(DateTime value) {
    return formatIstDateTime(value);
  }

  int _daysRemaining(HelpPost post) {
    final now = istNow();
    final elapsedDays = now.difference(toIst(post.createdAt)).inDays;
    final remaining = 7 - elapsedDays;
    return remaining < 0 ? 0 : remaining;
  }

  Widget _buildHelpPostCard(HelpPost post) {
    final comments = widget.helpFeedService.commentsFor(post.id);
    final commentCount = comments.length;
    final member = _resolvePostMember(post);
    final profileUrl = _resolveProfileUrl(post, member);
    final initial = post.memberName.isEmpty
      ? '?'
      : post.memberName.substring(0, 1).toUpperCase();
    final timestamp = _timestampLabel(post.createdAt);
    final remainingDays = _daysRemaining(post);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDDE6EC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openPostDetail(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: member == null
                        ? null
                        : () => _openMemberProfile(member),
                    child: profileUrl.isEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8F0F5),
                          child: Text(
                            initial,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        )
                      : ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profileUrl,
                            httpHeaders: CdnConfig.headersFor(profileUrl),
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFE8F0F5),
                              child: Text(
                                initial,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            errorWidget: (_, __, ___) => CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFE8F0F5),
                              child: Text(
                                initial,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          post.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.location,
                          style: const TextStyle(color: Color(0xFF5A6B74)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openPhone(post.memberMobile),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    tooltip: 'Call',
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      post.category,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2EAF0)),
                ),
                child: Text(
                  post.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  const Icon(Icons.schedule, size: 15, color: Color(0xFF5A6B74)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timestamp,
                      style: const TextStyle(
                        color: Color(0xFF5A6B74),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.timelapse_outlined, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$remainingDays',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4F8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$commentCount comments',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Member? _resolvePostMember(HelpPost post) {
    final byId = widget.repository.findById(post.memberId);
    if (byId != null) {
      return byId;
    }
    return widget.repository.findByMobile(post.memberMobile);
  }

  String _resolveProfileUrl(HelpPost post, Member? member) {
    final local = member?.selfieUrl ?? '';
    if (local.isNotEmpty) {
      return local;
    }

    final normalizedMobile = _normalizeMobile(post.memberMobile);
    final cached = _avatarUrlByMobile[normalizedMobile]?.trim() ?? '';
    if (cached.isNotEmpty) {
      return cached;
    }

    _ensureAvatarResolved(post.memberMobile);
    return '';
  }

  void _ensureAvatarResolved(String mobile) {
    final normalized = _normalizeMobile(mobile);
    if (normalized.isEmpty || _avatarLookupInFlight.contains(normalized)) {
      return;
    }

    _avatarLookupInFlight.add(normalized);
    widget.repository.fetchByMobileFromCloud(mobile).then((member) {
      if (!mounted) {
        return;
      }
      final selfieUrl = member?.selfieUrl ?? '';
      if (selfieUrl.isNotEmpty) {
        setState(() {
          _avatarUrlByMobile[normalized] = selfieUrl;
        });
      }
    }).catchError((_) {
      // Ignore lookup errors and keep the local fallback avatar.
    }).whenComplete(() {
      _avatarLookupInFlight.remove(normalized);
    });
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<void> _createHelpPost() async {
    final result = await Navigator.of(context).push<PostNewRequestResult>(
      MaterialPageRoute<PostNewRequestResult>(
        builder: (context) => PostNewRequestScreen(categories: _helpCategories),
      ),
    );

    if (result == null) {
      return;
    }

    bool created = false;
    try {
      created = await widget.helpFeedService.createPost(
        member: widget.currentUser,
        category: result.category,
        message: result.message,
      );
    } catch (_) {
      created = false;
    }

    if (!mounted) {
      return;
    }
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to post request to cloud. Please retry.')),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Help request posted.')));
  }

  Future<void> _openPhone(String mobile) async {
    try {
      final uri = Uri.parse('tel:$mobile');
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer.')),
      );
    }
  }

  Future<void> _openPostDetail(HelpPost post) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _HelpPostDetailScreen(
          post: post,
          currentUser: widget.currentUser,
          helpFeedService: widget.helpFeedService,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _openMemberProfile(Member member) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MemberDetailsScreen(
          currentUser: widget.currentUser,
          member: member,
        ),
      ),
    );
  }
}

class _HelpPostDetailScreen extends StatefulWidget {
  const _HelpPostDetailScreen({
    required this.post,
    required this.currentUser,
    required this.helpFeedService,
    required this.repository,
  });

  final HelpPost post;
  final Member currentUser;
  final HelpFeedService helpFeedService;
  final MemberRepository repository;

  @override
  State<_HelpPostDetailScreen> createState() => _HelpPostDetailScreenState();
}

class _HelpPostDetailScreenState extends State<_HelpPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _refreshComments();
  }

  Future<void> _refreshComments() async {
    await widget.helpFeedService.load();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _timestampLabel(DateTime value) {
    return formatIstDateTime(value);
  }

  String _commentTimeLabel(DateTime value) {
    return formatIstTime12(value);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.helpFeedService.commentsFor(widget.post.id).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final canDelete = widget.currentUser.isAdmin ||
        widget.currentUser.id == widget.post.memberId;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const BrandedScreenTitle('Help Post Details'),
        actions: <Widget>[
          if (canDelete)
            IconButton(
              onPressed: _deletePost,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete feed post',
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Chip(label: Text(widget.post.category)),
                        const SizedBox(height: 10),
                        Text(
                          widget.post.message,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${widget.post.memberName} • ${widget.post.location}'),
                        const SizedBox(height: 4),
                        Text(
                          _timestampLabel(widget.post.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF5A6B74),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () => _openPhone(widget.post.memberMobile),
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('Call'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openWhatsApp(widget.post.memberMobile),
                              icon: const Icon(Icons.chat_outlined),
                              label: const Text('WhatsApp'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (comments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No comments yet. Start the conversation.'),
                    ),
                  ),
                ..._buildCommentsWithDateSeparators(comments),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Write a comment',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _postingComment ? null : _submitComment,
                  child: Text(_postingComment ? 'Posting...' : 'Post'),
                ),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommentsWithDateSeparators(List<HelpComment> comments) {
    final widgets = <Widget>[];
    DateTime? lastDate;
    for (final comment in comments) {
      final createdIst = toIst(comment.createdAt);
      final day = DateTime(createdIst.year, createdIst.month, createdIst.day);
      if (lastDate == null || day != lastDate) {
        widgets.add(_buildDateSeparator(day));
        lastDate = day;
      }

      final canDeleteComment = widget.currentUser.isAdmin ||
          widget.currentUser.id == comment.memberId;
      final commentMember = widget.repository.findById(comment.memberId);
      final commentSelfie = commentMember?.selfieUrl ?? '';
      final commentInitial = comment.memberName.isEmpty
          ? '?'
          : comment.memberName[0].toUpperCase();
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: GestureDetector(
              onTap: commentMember == null
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => MemberDetailsScreen(
                            currentUser: widget.currentUser,
                            member: commentMember,
                          ),
                        ),
                      );
                    },
              child: commentSelfie.isEmpty
                  ? CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE8F0F5),
                      child: Text(
                        commentInitial,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    )
                  : ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: commentSelfie,
                        httpHeaders: CdnConfig.headersFor(commentSelfie),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8F0F5),
                          child: Text(
                            commentInitial,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        errorWidget: (_, __, ___) => CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8F0F5),
                          child: Text(
                            commentInitial,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
            ),
            title: Text(comment.memberName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(comment.message),
                const SizedBox(height: 4),
                Text(
                  _commentTimeLabel(comment.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A6B74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: canDeleteComment
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete comment',
                    onPressed: () => _deleteComment(comment.id),
                  )
                : null,
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = istNow();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == yesterday) {
      label = 'Yesterday';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      label = '$day/$month/$year';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5C67),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }
    setState(() {
      _postingComment = true;
    });
    final added = await widget.helpFeedService.addComment(
      postId: widget.post.id,
      member: widget.currentUser,
      message: message,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _postingComment = false;
    });
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to post comment to cloud. Please retry.')),
      );
      return;
    }
    _commentController.clear();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment posted.')),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete feed post'),
          content: const Text('This will remove this post and all comments.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await widget.helpFeedService.deletePost(widget.post.id);
    if (!mounted) {
      return;
    }
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete post in cloud. Please retry.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete comment'),
          content: const Text('This will permanently remove this comment.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await widget.helpFeedService.deleteComment(commentId);
    if (!mounted) {
      return;
    }
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete comment in cloud. Please retry.')),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment deleted.')),
    );
  }

  Future<void> _openPhone(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String mobile) async {
    final uri = Uri.parse('https://wa.me/91$mobile');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
