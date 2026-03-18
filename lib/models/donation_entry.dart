import 'dart:convert';

class DonationEntry {
  const DonationEntry({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberMobile,
    required this.amount,
    required this.upiId,
    required this.status,
    required this.createdAt,
    this.transactionRef,
    this.note,
    this.screenshotPath,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String memberMobile;
  final double amount;
  final String upiId;
  final String status;
  final DateTime createdAt;
  final String? transactionRef;
  final String? note;
  final String? screenshotPath;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'memberId': memberId,
      'memberName': memberName,
      'memberMobile': memberMobile,
      'amount': amount,
      'upiId': upiId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'transactionRef': transactionRef,
      'note': note,
      'screenshotPath': screenshotPath,
    };
  }

  factory DonationEntry.fromMap(Map<String, dynamic> map) {
    return DonationEntry(
      id: map['id'] as String,
      memberId: map['memberId'] as String,
      memberName: map['memberName'] as String,
      memberMobile: map['memberMobile'] as String,
      amount: (map['amount'] as num).toDouble(),
      upiId: map['upiId'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      transactionRef: map['transactionRef'] as String?,
      note: map['note'] as String?,
      screenshotPath: map['screenshotPath'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DonationEntry.fromJson(String source) =>
      DonationEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
