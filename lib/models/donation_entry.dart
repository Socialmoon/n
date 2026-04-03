import 'dart:convert';

import '../core/time_utils.dart';

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
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
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
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => !isVerified && !isRejected;

  DonationEntry copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? memberMobile,
    double? amount,
    String? upiId,
    String? status,
    DateTime? createdAt,
    String? transactionRef,
    String? note,
    String? screenshotPath,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return DonationEntry(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      memberMobile: memberMobile ?? this.memberMobile,
      amount: amount ?? this.amount,
      upiId: upiId ?? this.upiId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      transactionRef: transactionRef ?? this.transactionRef,
      note: note ?? this.note,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

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
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
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
      createdAt: parseServerDateTime(map['createdAt']),
      transactionRef: map['transactionRef'] as String?,
      note: map['note'] as String?,
      screenshotPath: map['screenshotPath'] as String?,
      reviewedAt: map['reviewedAt'] == null
          ? null
          : parseServerDateTime(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DonationEntry.fromJson(String source) =>
      DonationEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
