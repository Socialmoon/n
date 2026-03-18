import 'package:shared_preferences/shared_preferences.dart';

import '../models/help_comment.dart';
import '../models/help_post.dart';
import '../models/member.dart';
import 'supabase_service.dart';

class HelpFeedService {
  HelpFeedService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  static const _postsKey = 'help_feed_posts';
  static const _commentsKey = 'help_feed_comments';

  final SupabaseService _cloudService;
  SharedPreferences? _preferences;
  final List<HelpPost> _posts = <HelpPost>[];
  final List<HelpComment> _comments = <HelpComment>[];

  List<HelpPost> get posts => List.unmodifiable(_posts.reversed);

  List<HelpComment> commentsFor(String postId) {
    final matching = _comments.where((item) => item.postId == postId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matching);
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final rawPosts = _preferences?.getStringList(_postsKey) ?? <String>[];
    final rawComments = _preferences?.getStringList(_commentsKey) ?? <String>[];
    _posts
      ..clear()
      ..addAll(rawPosts.map(HelpPost.fromJson));
    _comments
      ..clear()
      ..addAll(rawComments.map(HelpComment.fromJson));

    if (!_cloudService.isConfigured) {
      return;
    }

    final cloudPosts = await _cloudService.fetchHelpPosts();
    final cloudComments = await _cloudService.fetchHelpComments();
    if (cloudPosts.isEmpty) {
      return;
    }

    _posts
      ..clear()
      ..addAll(cloudPosts.reversed);
    _comments
      ..clear()
      ..addAll(cloudComments.reversed);
    await _persist();
  }

  Future<void> createPost({
    required Member member,
    required String category,
    required String message,
  }) async {
    final post = HelpPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      memberMobile: member.mobileNumber,
      category: category,
      message: message,
      location: member.postingLocation,
      createdAt: DateTime.now(),
    );

    _posts.add(post);
    await _persist();
    await _cloudService.insertHelpPost(post);
  }

  Future<void> addComment({
    required String postId,
    required Member member,
    required String message,
  }) async {
    final comment = HelpComment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      postId: postId,
      memberId: member.id,
      memberName: member.name,
      message: message,
      createdAt: DateTime.now(),
    );

    _comments.add(comment);
    await _persist();
    await _cloudService.insertHelpComment(comment);
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post.id == postId);
    _comments.removeWhere((comment) => comment.postId == postId);
    await _persist();
    await _cloudService.deleteHelpPost(postId);
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _postsKey,
      _posts.map((entry) => entry.toJson()).toList(),
    );
    await _preferences!.setStringList(
      _commentsKey,
      _comments.map((entry) => entry.toJson()).toList(),
    );
  }
}
