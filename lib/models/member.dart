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
    this.homeState,
    required this.postingDistrict,
    this.postingState,
    required this.postingLocation,
    this.department,
    this.postRank,
    this.officialName,
    this.batchYear,
    this.whatsappNumber,
    this.callingContactNumber,
    this.postingPlaceLocation,
    this.emergencyContact,
    this.homeVillageMohalla,
    this.homeGaliNo,
    this.homePostOffice,
    this.homePoliceStation,
    this.homeTehsil,
    this.homeVillageLocation,
    this.gender,
    this.maritalStatus,
    this.postingCategory,
    this.postingWorkAs,
    this.liveLatitude,
    this.liveLongitude,
    this.liveLocationUpdatedAt,
    this.lastLoginAt,
    required this.appointmentDate,
    required this.role,
    required this.lastUpdated,
    required this.passwordUpdatedAt,
    this.selfiePath,
    this.idCardPhotoPath,
    this.isAdmin = false,
    this.isBlocked = false,
    this.isApproved = false,
    this.isRetired = false,
    this.isDeleted = false,
    this.retiredAt,
    this.deletedAt,
    this.pendingUpdatePayload,
    this.previousPublicProfileSnapshot,
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
  final String? homeState;
  final String postingDistrict;
  final String? postingState;
  final String postingLocation;
  final String? department;
  final String? postRank;
  final String? officialName;
  final String? batchYear;
  final String? whatsappNumber;
  final String? callingContactNumber;
  final String? postingPlaceLocation;
  final String? emergencyContact;
  final String? homeVillageMohalla;
  final String? homeGaliNo;
  final String? homePostOffice;
  final String? homePoliceStation;
  final String? homeTehsil;
  final String? homeVillageLocation;
  final String? gender;
  final String? maritalStatus;
  final String? postingCategory;
  final String? postingWorkAs;
  final double? liveLatitude;
  final double? liveLongitude;
  final DateTime? liveLocationUpdatedAt;
  final DateTime? lastLoginAt;
  final DateTime appointmentDate;
  final String role;
  final DateTime lastUpdated;
  final DateTime passwordUpdatedAt;
  final bool isAdmin;
  final bool isBlocked;
  final bool isApproved;
  final bool isRetired;
  final bool isDeleted;
  final DateTime? retiredAt;
  final DateTime? deletedAt;
  final String? pendingUpdatePayload;
  final String? previousPublicProfileSnapshot;

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
    bool clearSelfiePath = false,
    String? idCardPhotoPath,
    bool clearIdCardPhotoPath = false,
    String? homeDistrict,
    String? homeState,
    String? postingDistrict,
    String? postingState,
    String? postingLocation,
    String? department,
    String? postRank,
    String? officialName,
    String? batchYear,
    String? whatsappNumber,
    String? callingContactNumber,
    String? postingPlaceLocation,
    String? emergencyContact,
    String? homeVillageMohalla,
    String? homeGaliNo,
    String? homePostOffice,
    String? homePoliceStation,
    String? homeTehsil,
    String? homeVillageLocation,
    String? gender,
    String? maritalStatus,
    String? postingCategory,
    String? postingWorkAs,
    double? liveLatitude,
    bool clearLiveLatitude = false,
    double? liveLongitude,
    bool clearLiveLongitude = false,
    DateTime? liveLocationUpdatedAt,
    bool clearLiveLocationUpdatedAt = false,
    DateTime? lastLoginAt,
    bool clearLastLoginAt = false,
    DateTime? appointmentDate,
    String? role,
    DateTime? lastUpdated,
    DateTime? passwordUpdatedAt,
    bool? isAdmin,
    bool? isBlocked,
    bool? isApproved,
    bool? isRetired,
    bool? isDeleted,
    DateTime? retiredAt,
    bool clearRetiredAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? pendingUpdatePayload,
    bool clearPendingUpdatePayload = false,
    String? previousPublicProfileSnapshot,
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
        selfiePath: clearSelfiePath ? null : (selfiePath ?? this.selfiePath),
        idCardPhotoPath:
          clearIdCardPhotoPath ? null : (idCardPhotoPath ?? this.idCardPhotoPath),
      homeDistrict: homeDistrict ?? this.homeDistrict,
      homeState: homeState ?? this.homeState,
      postingDistrict: postingDistrict ?? this.postingDistrict,
      postingState: postingState ?? this.postingState,
      postingLocation: postingLocation ?? this.postingLocation,
        department: department ?? this.department,
        postRank: postRank ?? this.postRank,
        officialName: officialName ?? this.officialName,
        batchYear: batchYear ?? this.batchYear,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
        callingContactNumber: callingContactNumber ?? this.callingContactNumber,
        postingPlaceLocation: postingPlaceLocation ?? this.postingPlaceLocation,
        emergencyContact: emergencyContact ?? this.emergencyContact,
        homeVillageMohalla: homeVillageMohalla ?? this.homeVillageMohalla,
        homeGaliNo: homeGaliNo ?? this.homeGaliNo,
        homePostOffice: homePostOffice ?? this.homePostOffice,
        homePoliceStation: homePoliceStation ?? this.homePoliceStation,
        homeTehsil: homeTehsil ?? this.homeTehsil,
        homeVillageLocation: homeVillageLocation ?? this.homeVillageLocation,
        gender: gender ?? this.gender,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        postingCategory: postingCategory ?? this.postingCategory,
        postingWorkAs: postingWorkAs ?? this.postingWorkAs,
        liveLatitude: clearLiveLatitude ? null : (liveLatitude ?? this.liveLatitude),
        liveLongitude:
          clearLiveLongitude ? null : (liveLongitude ?? this.liveLongitude),
        liveLocationUpdatedAt: clearLiveLocationUpdatedAt
          ? null
          : (liveLocationUpdatedAt ?? this.liveLocationUpdatedAt),
      lastLoginAt:
          clearLastLoginAt ? null : (lastLoginAt ?? this.lastLoginAt),
      appointmentDate: appointmentDate ?? this.appointmentDate,
      role: role ?? this.role,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      passwordUpdatedAt: passwordUpdatedAt ?? this.passwordUpdatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      isApproved: isApproved ?? this.isApproved,
      isRetired: isRetired ?? this.isRetired,
      isDeleted: isDeleted ?? this.isDeleted,
      retiredAt: clearRetiredAt ? null : (retiredAt ?? this.retiredAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      pendingUpdatePayload: clearPendingUpdatePayload
          ? null
          : (pendingUpdatePayload ?? this.pendingUpdatePayload),
      previousPublicProfileSnapshot:
          previousPublicProfileSnapshot ?? this.previousPublicProfileSnapshot,
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
      'homeState': homeState,
      'postingDistrict': postingDistrict,
      'postingState': postingState,
      'postingLocation': postingLocation,
      'department': department,
      'postRank': postRank,
      'officialName': officialName,
      'batchYear': batchYear,
      'whatsappNumber': whatsappNumber,
      'callingContactNumber': callingContactNumber,
      'postingPlaceLocation': postingPlaceLocation,
      'emergencyContact': emergencyContact,
      'homeVillageMohalla': homeVillageMohalla,
      'homeGaliNo': homeGaliNo,
      'homePostOffice': homePostOffice,
      'homePoliceStation': homePoliceStation,
      'homeTehsil': homeTehsil,
      'homeVillageLocation': homeVillageLocation,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'postingCategory': postingCategory,
      'postingWorkAs': postingWorkAs,
      'liveLatitude': liveLatitude,
      'liveLongitude': liveLongitude,
      'liveLocationUpdatedAt': liveLocationUpdatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'appointmentDate': appointmentDate.toIso8601String(),
      'role': role,
      'lastUpdated': lastUpdated.toIso8601String(),
      'passwordUpdatedAt': passwordUpdatedAt.toIso8601String(),
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'isApproved': isApproved,
      'isRetired': isRetired,
      'isDeleted': isDeleted,
      'retiredAt': retiredAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'pendingUpdatePayload': pendingUpdatePayload,
      'previousPublicProfileSnapshot': previousPublicProfileSnapshot,
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
      homeState: map['homeState'] as String?,
      postingDistrict: map['postingDistrict'] as String,
      postingState: map['postingState'] as String?,
      postingLocation: map['postingLocation'] as String,
        department: map['department'] as String?,
        postRank: map['postRank'] as String?,
        officialName: map['officialName'] as String?,
        batchYear: map['batchYear'] as String?,
        whatsappNumber: map['whatsappNumber'] as String?,
        callingContactNumber: map['callingContactNumber'] as String?,
        postingPlaceLocation: map['postingPlaceLocation'] as String?,
        emergencyContact: map['emergencyContact'] as String?,
        homeVillageMohalla: map['homeVillageMohalla'] as String?,
        homeGaliNo: map['homeGaliNo'] as String?,
        homePostOffice: map['homePostOffice'] as String?,
        homePoliceStation: map['homePoliceStation'] as String?,
        homeTehsil: map['homeTehsil'] as String?,
        homeVillageLocation: map['homeVillageLocation'] as String?,
        gender: map['gender'] as String?,
        maritalStatus: map['maritalStatus'] as String?,
        postingCategory: map['postingCategory'] as String?,
        postingWorkAs: map['postingWorkAs'] as String?,
        liveLatitude: (map['liveLatitude'] as num?)?.toDouble(),
        liveLongitude: (map['liveLongitude'] as num?)?.toDouble(),
        liveLocationUpdatedAt: map['liveLocationUpdatedAt'] == null
          ? null
          : DateTime.parse(map['liveLocationUpdatedAt'] as String),
      lastLoginAt: map['lastLoginAt'] == null
          ? null
          : DateTime.parse(map['lastLoginAt'] as String),
      appointmentDate: DateTime.parse(map['appointmentDate'] as String),
      role: map['role'] as String,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      passwordUpdatedAt: DateTime.parse(map['passwordUpdatedAt'] as String),
      isAdmin: map['isAdmin'] as bool? ?? false,
      isBlocked: map['isBlocked'] as bool? ?? false,
      isApproved: map['isApproved'] as bool? ?? (map['isAdmin'] as bool? ?? false),
      isRetired: map['isRetired'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      retiredAt: map['retiredAt'] == null
          ? null
          : DateTime.parse(map['retiredAt'] as String),
      deletedAt: map['deletedAt'] == null
          ? null
          : DateTime.parse(map['deletedAt'] as String),
        pendingUpdatePayload: map['pendingUpdatePayload'] as String?,
        previousPublicProfileSnapshot:
          map['previousPublicProfileSnapshot'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Member.fromJson(String source) =>
      Member.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
