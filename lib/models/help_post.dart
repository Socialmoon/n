import 'dart:convert';

class HelpPost {
  const HelpPost({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberMobile,
    required this.category,
    required this.message,
    required this.location,
    required this.createdAt,
    this.requestedAmount,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String memberMobile;
  final String category;
  final String message;
  final String location;
  final DateTime createdAt;
  final double? requestedAmount;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'memberId': memberId,
      'memberName': memberName,
      'memberMobile': memberMobile,
      'category': category,
      'message': message,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'requestedAmount': requestedAmount,
    };
  }

  factory HelpPost.fromMap(Map<String, dynamic> map) {
    return HelpPost(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String,
      memberMobile: map['memberMobile'] as String,
      category: map['category'] as String,
      message: map['message'] as String,
      location: map['location'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      requestedAmount: (map['requestedAmount'] as num?)?.toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HelpPost.fromJson(String source) =>
      HelpPost.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
