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
      createdAt: _parseUtcDateTime(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HelpComment.fromJson(String source) =>
      HelpComment.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

DateTime _parseUtcDateTime(dynamic raw) {
  final text = (raw ?? '').toString().trim();
  if (text.isEmpty) {
    return DateTime.now().toUtc();
  }

  final hasTimezone = RegExp(r'(Z|[+-][0-9]{2}:[0-9]{2})$').hasMatch(text);
  if (hasTimezone) {
    return DateTime.parse(text).toUtc();
  }

  // Legacy rows were often stored without timezone as India local time.
  // Preserve that wall-clock value by converting IST -> UTC explicitly.
  final parsed = DateTime.parse(text);
  const istOffset = Duration(hours: 5, minutes: 30);
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).subtract(istOffset);
}
