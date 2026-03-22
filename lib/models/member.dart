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
    this.liveLatitude,
    this.liveLongitude,
    this.liveLocationUpdatedAt,
    required this.appointmentDate,
    required this.role,
    required this.lastUpdated,
    required this.passwordUpdatedAt,
    this.selfiePath,
    this.idCardPhotoPath,
    this.isAdmin = false,
    this.isBlocked = false,
    this.isApproved = true,
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
  final double? liveLatitude;
  final double? liveLongitude;
  final DateTime? liveLocationUpdatedAt;
  final DateTime appointmentDate;
  final String role;
  final DateTime lastUpdated;
  final DateTime passwordUpdatedAt;
  final bool isAdmin;
  final bool isBlocked;
  final bool isApproved;

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
    String? postingDistrict,
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
    double? liveLatitude,
    bool clearLiveLatitude = false,
    double? liveLongitude,
    bool clearLiveLongitude = false,
    DateTime? liveLocationUpdatedAt,
    bool clearLiveLocationUpdatedAt = false,
    DateTime? appointmentDate,
    String? role,
    DateTime? lastUpdated,
    DateTime? passwordUpdatedAt,
    bool? isAdmin,
    bool? isBlocked,
    bool? isApproved,
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
      postingDistrict: postingDistrict ?? this.postingDistrict,
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
        liveLatitude: clearLiveLatitude ? null : (liveLatitude ?? this.liveLatitude),
        liveLongitude:
          clearLiveLongitude ? null : (liveLongitude ?? this.liveLongitude),
        liveLocationUpdatedAt: clearLiveLocationUpdatedAt
          ? null
          : (liveLocationUpdatedAt ?? this.liveLocationUpdatedAt),
      appointmentDate: appointmentDate ?? this.appointmentDate,
      role: role ?? this.role,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      passwordUpdatedAt: passwordUpdatedAt ?? this.passwordUpdatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      isApproved: isApproved ?? this.isApproved,
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
      'liveLatitude': liveLatitude,
      'liveLongitude': liveLongitude,
      'liveLocationUpdatedAt': liveLocationUpdatedAt?.toIso8601String(),
      'appointmentDate': appointmentDate.toIso8601String(),
      'role': role,
      'lastUpdated': lastUpdated.toIso8601String(),
      'passwordUpdatedAt': passwordUpdatedAt.toIso8601String(),
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'isApproved': isApproved,
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
        liveLatitude: (map['liveLatitude'] as num?)?.toDouble(),
        liveLongitude: (map['liveLongitude'] as num?)?.toDouble(),
        liveLocationUpdatedAt: map['liveLocationUpdatedAt'] == null
          ? null
          : DateTime.parse(map['liveLocationUpdatedAt'] as String),
      appointmentDate: DateTime.parse(map['appointmentDate'] as String),
      role: map['role'] as String,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      passwordUpdatedAt: DateTime.parse(map['passwordUpdatedAt'] as String),
      isAdmin: map['isAdmin'] as bool? ?? false,
      isBlocked: map['isBlocked'] as bool? ?? false,
      isApproved: map['isApproved'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Member.fromJson(String source) =>
      Member.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
