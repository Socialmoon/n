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

  List<HelpPost> get posts => List.unmodifiable(_posts.reversed);

  List<HelpComment> commentsFor(String postId) {
    final matching = _comments.where((item) => item.postId == postId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(matching);
  }

  Future<void> load() async {
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
  }

  Future<bool> createPost({
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
    final saved = await _cloudService.insertHelpPost(post);
    if (!saved) {
      _posts.removeWhere((item) => item.id == post.id);
      return false;
    }
    return true;
  }

  Future<bool> addComment({
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
    final saved = await _cloudService.insertHelpComment(comment);
    if (!saved) {
      _comments.removeWhere((item) => item.id == comment.id);
      return false;
    }
    return true;
  }

  Future<bool> deletePost(String postId) async {
    final previousPosts = List<HelpPost>.from(_posts);
    final previousComments = List<HelpComment>.from(_comments);
    _posts.removeWhere((post) => post.id == postId);
    _comments.removeWhere((comment) => comment.postId == postId);
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
    return true;
  }
}
