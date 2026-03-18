import 'dart:convert';

class HelpComment {
  const HelpComment({
    required this.id,
    required this.postId,
    required this.memberId,
    required this.memberName,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String memberId;
  final String memberName;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'postId': postId,
      'memberId': memberId,
      'memberName': memberName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HelpComment.fromMap(Map<String, dynamic> map) {
    return HelpComment(
      id: map['id'] as String,
      postId: map['postId'] as String,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HelpComment.fromJson(String source) =>
      HelpComment.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
