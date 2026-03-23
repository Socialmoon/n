import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../models/help_post.dart';
import '../models/member.dart';
import '../services/help_feed_service.dart';
import 'post_new_request_screen.dart';

class HelpFeedScreen extends StatefulWidget {
  const HelpFeedScreen({
    required this.currentUser,
    required this.helpFeedService,
    super.key,
  });

  final Member currentUser;
  final HelpFeedService helpFeedService;

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

  final TextEditingController _feedSearchController = TextEditingController();
  String _activeCategory = 'All';

  @override
  void dispose() {
    _feedSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPosts = widget.helpFeedService.posts;
    final emergencyCount =
        allPosts.where((post) => post.category == 'Emergency').length;
    final query = _feedSearchController.text.trim().toLowerCase();

    final posts = allPosts.where((post) {
      final matchesCategory =
          _activeCategory == 'All' || post.category == _activeCategory;
      if (!matchesCategory) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return post.memberName.toLowerCase().contains(query) ||
          post.location.toLowerCase().contains(query) ||
          post.category.toLowerCase().contains(query) ||
          post.message.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('Help Feed'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF103A4A), Color(0xFF2C6E7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x290A2A38),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Community Support Feed',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Real-time requests, comments, and direct contact in one place.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.forum_outlined,
                        label: 'Total posts',
                        value: '${posts.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.warning_amber_outlined,
                        label: 'Emergency',
                        value: '$emergencyCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _feedSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search posts by name, category, place, or message',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _feedSearchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _feedSearchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _helpCategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = index == 0 ? 'All' : _helpCategories[index - 1];
                final count = category == 'All'
                    ? allPosts.length
                    : allPosts.where((post) => post.category == category).length;
                return FilterChip(
                  selected: category == _activeCategory,
                  onSelected: (_) {
                    setState(() {
                      _activeCategory = category;
                    });
                  },
                  label: Text('$category ($count)'),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _createHelpPost,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Post New Request'),
          ),
          const SizedBox(height: 14),
          if (posts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  (query.isNotEmpty || _activeCategory != 'All')
                      ? 'No requests match the current search/filter.'
                      : 'No requests yet. Share the first update so nearby members can respond quickly.',
                ),
              ),
            ),
          ...posts.map(_buildHelpPostCard),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x2EFFFFFF),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF0F3A4A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpPostCard(HelpPost post) {
    final comments = widget.helpFeedService.commentsFor(post.id);
    final commentCount = comments.length;
    final timestamp =
        '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year} ${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openPostDetail(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE8F0F5),
                    child: Text(
                      post.memberName.isEmpty ? '?' : post.memberName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          post.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          post.location,
                          style: const TextStyle(color: Color(0xFF5A6B74)),
                        ),
                      ],
                    ),
                  ),
                  Chip(label: Text(post.category)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                timestamp,
                style: const TextStyle(color: Color(0xFF5A6B74)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(
                    avatar: const Icon(Icons.mode_comment_outlined, size: 16),
                    label: Text('$commentCount comments'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openPhone(post.memberMobile),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openWhatsApp(post.memberMobile),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openPostDetail(post),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Discuss'),
                  ),
                  if (widget.currentUser.isAdmin ||
                      widget.currentUser.id == post.memberId)
                    IconButton(
                      onPressed: () => _deletePost(post),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete feed post',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

    await widget.helpFeedService.createPost(
      member: widget.currentUser,
      category: result.category,
      message: result.message,
    );

    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help request posted.')),
    );
  }

  Future<void> _deletePost(HelpPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete feed post'),
          content: const Text('This will remove the post and related comments.'),
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

    await widget.helpFeedService.deletePost(post.id);

    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feed post deleted.')),
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

  Future<void> _openPostDetail(HelpPost post) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _HelpPostDetailScreen(
          post: post,
          currentUser: widget.currentUser,
          helpFeedService: widget.helpFeedService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }
}

class _HelpPostDetailScreen extends StatefulWidget {
  const _HelpPostDetailScreen({
    required this.post,
    required this.currentUser,
    required this.helpFeedService,
  });

  final HelpPost post;
  final Member currentUser;
  final HelpFeedService helpFeedService;

  @override
  State<_HelpPostDetailScreen> createState() => _HelpPostDetailScreenState();
}

class _HelpPostDetailScreenState extends State<_HelpPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.helpFeedService.commentsFor(widget.post.id);
    final canDelete = widget.currentUser.isAdmin ||
        widget.currentUser.id == widget.post.memberId;

    return Scaffold(
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
                ...comments.map(
                  (comment) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(comment.memberName),
                      subtitle: Text(comment.message),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
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
                  onPressed: _submitComment,
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }
    await widget.helpFeedService.addComment(
      postId: widget.post.id,
      member: widget.currentUser,
      message: message,
    );
    _commentController.clear();
    if (!mounted) {
      return;
    }
    setState(() {});
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

    await widget.helpFeedService.deletePost(widget.post.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}
