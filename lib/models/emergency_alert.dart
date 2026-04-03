import 'dart:convert';

import '../core/time_utils.dart';

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.timestamp,
    required this.message,
    required this.location,
  });

  final String id;
  final String memberId;
  final String memberName;
  final DateTime timestamp;
  final String message;
  final String location;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberId': memberId,
      'memberName': memberName,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'location': location,
    };
  }

  factory EmergencyAlert.fromMap(Map<String, dynamic> map) {
    return EmergencyAlert(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String,
      timestamp: parseServerDateTime(map['timestamp']),
      message: map['message'] as String,
      location: map['location'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory EmergencyAlert.fromJson(String source) =>
      EmergencyAlert.fromMap(jsonDecode(source) as Map<String, dynamic>);
}