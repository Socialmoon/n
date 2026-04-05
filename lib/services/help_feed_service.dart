import '../models/help_comment.dart';
import '../models/help_post.dart';
import '../models/member.dart';
import 'supabase_service.dart';

class HelpFeedService {
  HelpFeedService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final List<HelpPost> _posts = <HelpPost>[];
  final List<HelpComment> _comments = <HelpComment>[];
  static const Duration _postExpiry = Duration(days: 7);

  List<HelpPost> get posts {
    final now = DateTime.now().toUtc();
    final active = _posts
        .where((post) => now.difference(post.createdAt.toUtc()) < _postExpiry)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(active);
  }

  List<HelpComment> commentsFor(String postId) {
    final matching = _comments.where((item) => item.postId == postId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matching);
  }

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }
    try {
      final cloudPosts = await _cloudService.fetchHelpPosts();
      final cloudComments = await _cloudService.fetchHelpComments();
      final now = DateTime.now().toUtc();
      final activePosts = cloudPosts
          .where((post) => now.difference(post.createdAt.toUtc()) < _postExpiry)
          .toList();
      final activePostIds = activePosts.map((post) => post.id).toSet();
      final activeComments = cloudComments
          .where((comment) => activePostIds.contains(comment.postId))
          .toList();

      _posts
        ..clear()
        ..addAll(activePosts);
      _comments
        ..clear()
        ..addAll(activeComments);
    } catch (_) {
      return;
    }
  }

  Future<bool> createPost({
    required Member member,
    required String category,
    required String message,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final post = HelpPost(
      id: nowUtc.microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      memberMobile: member.mobileNumber,
      category: category,
      message: message,
      location: member.postingLocation,
      createdAt: nowUtc,
    );

    _posts.add(post);
    try {
      final saved = await _cloudService.insertHelpPost(post);
      if (!saved) {
        _posts.removeWhere((item) => item.id == post.id);
        return false;
      }
      await load();
      return true;
    } catch (_) {
      _posts.removeWhere((item) => item.id == post.id);
      return false;
    }
  }

  Future<bool> addComment({
    required String postId,
    required Member member,
    required String message,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final comment = HelpComment(
      id: nowUtc.microsecondsSinceEpoch.toString(),
      postId: postId,
      memberId: member.id,
      memberName: member.name,
      message: message,
      createdAt: nowUtc,
    );

    _comments.add(comment);
    try {
      final saved = await _cloudService.insertHelpComment(comment);
      if (!saved) {
        _comments.removeWhere((item) => item.id == comment.id);
        return false;
      }
      await load();
      return true;
    } catch (_) {
      _comments.removeWhere((item) => item.id == comment.id);
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    final previousPosts = List<HelpPost>.from(_posts);
    final previousComments = List<HelpComment>.from(_comments);
    _posts.removeWhere((post) => post.id == postId);
    _comments.removeWhere((comment) => comment.postId == postId);
    try {
      final deleted = await _cloudService.deleteHelpPost(postId);
      if (!deleted) {
        _posts
          ..clear()
          ..addAll(previousPosts);
        _comments
          ..clear()
          ..addAll(previousComments);
        return false;
      }
      await load();
      return true;
    } catch (_) {
      _posts
        ..clear()
        ..addAll(previousPosts);
      _comments
        ..clear()
        ..addAll(previousComments);
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    final previousComments = List<HelpComment>.from(_comments);
    _comments.removeWhere((comment) => comment.id == commentId);
    try {
      final deleted = await _cloudService.deleteHelpComment(commentId);
      if (!deleted) {
        _comments
          ..clear()
          ..addAll(previousComments);
        return false;
      }
      await load();
      return true;
    } catch (_) {
      _comments
        ..clear()
        ..addAll(previousComments);
      return false;
    }
  }
}
