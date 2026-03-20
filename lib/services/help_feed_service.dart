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
    await _cloudService.insertHelpComment(comment);
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post.id == postId);
    _comments.removeWhere((comment) => comment.postId == postId);
    await _cloudService.deleteHelpPost(postId);
  }
}
