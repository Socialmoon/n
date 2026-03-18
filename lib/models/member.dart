import 'dart:convert';

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.userId,
    required this.passwordHash,
    required this.mpin,
    required this.referenceMobileNumber,
    required this.referenceMemberName,
    required this.homeDistrict,
    required this.postingDistrict,
    required this.postingLocation,
    required this.appointmentDate,
    required this.role,
    required this.lastUpdated,
    required this.passwordUpdatedAt,
    this.selfiePath,
    this.idCardPhotoPath,
    this.isAdmin = false,
    this.isBlocked = false,
  });

  final String id;
  final String name;
  final String mobileNumber;
  final String userId;
  final String passwordHash;
  final String mpin;
  final String referenceMobileNumber;
  final String? referenceMemberName;
  final String? selfiePath;
  final String? idCardPhotoPath;
  final String homeDistrict;
  final String postingDistrict;
  final String postingLocation;
  final DateTime appointmentDate;
  final String role;
  final DateTime lastUpdated;
  final DateTime passwordUpdatedAt;
  final bool isAdmin;
  final bool isBlocked;

  Member copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    String? userId,
    String? passwordHash,
    String? mpin,
    String? referenceMobileNumber,
    String? referenceMemberName,
    String? selfiePath,
    String? idCardPhotoPath,
    String? homeDistrict,
    String? postingDistrict,
    String? postingLocation,
    DateTime? appointmentDate,
    String? role,
    DateTime? lastUpdated,
    DateTime? passwordUpdatedAt,
    bool? isAdmin,
    bool? isBlocked,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      userId: userId ?? this.userId,
      passwordHash: passwordHash ?? this.passwordHash,
      mpin: mpin ?? this.mpin,
      referenceMobileNumber:
          referenceMobileNumber ?? this.referenceMobileNumber,
      referenceMemberName: referenceMemberName ?? this.referenceMemberName,
      selfiePath: selfiePath ?? this.selfiePath,
      idCardPhotoPath: idCardPhotoPath ?? this.idCardPhotoPath,
      homeDistrict: homeDistrict ?? this.homeDistrict,
      postingDistrict: postingDistrict ?? this.postingDistrict,
      postingLocation: postingLocation ?? this.postingLocation,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      role: role ?? this.role,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      passwordUpdatedAt: passwordUpdatedAt ?? this.passwordUpdatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  bool get needsProfileRefresh =>
      DateTime.now().difference(lastUpdated).inDays >= 180;

  bool get needsPasswordRefresh =>
      DateTime.now().difference(passwordUpdatedAt).inDays >= 365;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'userId': userId,
      'passwordHash': passwordHash,
      'mpin': mpin,
      'referenceMobileNumber': referenceMobileNumber,
      'referenceMemberName': referenceMemberName,
      'selfiePath': selfiePath,
      'idCardPhotoPath': idCardPhotoPath,
      'homeDistrict': homeDistrict,
      'postingDistrict': postingDistrict,
      'postingLocation': postingLocation,
      'appointmentDate': appointmentDate.toIso8601String(),
      'role': role,
      'lastUpdated': lastUpdated.toIso8601String(),
      'passwordUpdatedAt': passwordUpdatedAt.toIso8601String(),
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      mobileNumber: map['mobileNumber'] as String,
      userId: map['userId'] as String,
      passwordHash: map['passwordHash'] as String,
      mpin: map['mpin'] as String,
      referenceMobileNumber: map['referenceMobileNumber'] as String? ?? '',
      referenceMemberName: map['referenceMemberName'] as String?,
      selfiePath: map['selfiePath'] as String?,
      idCardPhotoPath: map['idCardPhotoPath'] as String?,
      homeDistrict: map['homeDistrict'] as String,
      postingDistrict: map['postingDistrict'] as String,
      postingLocation: map['postingLocation'] as String,
      appointmentDate: DateTime.parse(map['appointmentDate'] as String),
      role: map['role'] as String,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      passwordUpdatedAt: DateTime.parse(map['passwordUpdatedAt'] as String),
      isAdmin: map['isAdmin'] as bool? ?? false,
      isBlocked: map['isBlocked'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Member.fromJson(String source) =>
      Member.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
