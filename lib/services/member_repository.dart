import 'dart:convert';

import '../models/member.dart';
import 'supabase_service.dart';

class MemberRepository {
  MemberRepository({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);

  List<Member> get activeMembers => _members
      .where((member) => !member.isDeleted)
      .toList()
    ..sort((left, right) => left.name.compareTo(right.name));

  List<Member> get pendingApprovals => _members
      .where((member) => !member.isApproved && !member.isAdmin && !member.isDeleted)
      .toList()
    ..sort((left, right) => left.name.compareTo(right.name));

  List<Member> get retiredMembers => _members
      .where((member) => member.isRetired && !member.isDeleted)
      .toList()
    ..sort((left, right) => left.name.compareTo(right.name));

  List<Member> get deletedMembers => _members
      .where((member) => member.isDeleted)
      .toList()
    ..sort((left, right) => right.lastUpdated.compareTo(left.lastUpdated));

  List<Member> get inactiveOver30Days => _members
      .where((member) {
        final lastSeen = member.lastLoginAt ?? member.appointmentDate;
        return !member.isDeleted && DateTime.now().difference(lastSeen).inDays >= 30;
      })
      .toList()
    ..sort((left, right) {
      final leftSeen = left.lastLoginAt ?? left.appointmentDate;
      final rightSeen = right.lastLoginAt ?? right.appointmentDate;
      return leftSeen.compareTo(rightSeen);
    });

  List<Member> get pendingUpdateApprovals => _members
      .where((member) =>
          !member.isDeleted &&
          !member.isAdmin &&
        _hasPendingProfileUpdate(member.pendingUpdatePayload))
      .toList()
    ..sort((left, right) => left.name.compareTo(right.name));

  Member? getById(String id) {
    for (final member in _members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }

    try {
      final cloudMembers = await _cloudService.fetchMembers();
      if (cloudMembers.isNotEmpty) {
        _members
          ..clear()
          ..addAll(cloudMembers);
        return;
      }
    } catch (_) {
      return;
    }
  }

  Future<bool> saveMember(Member member) async {
    if (!_cloudService.isConfigured) {
      return false;
    }
    final index = _members.indexWhere((item) => item.id == member.id);
    Member? previous;
    if (index == -1) {
      _members.add(member);
    } else {
      previous = _members[index];
      _members[index] = member;
    }
    try {
      final success = await _cloudService.upsertMember(member);
      if (!success) {
        if (index == -1) {
          _members.removeWhere((item) => item.id == member.id);
        } else if (previous != null) {
          _members[index] = previous;
        }
      }
      return success;
    } catch (_) {
      if (index == -1) {
        _members.removeWhere((item) => item.id == member.id);
      } else if (previous != null) {
        _members[index] = previous;
      }
      return false;
    }
  }

  Future<void> seedAdminIfNeeded() async {
    if (_members.isNotEmpty || !_cloudService.isConfigured) {
      return;
    }

    // No hardcoded admin credentials in app builds.
    // Admin/member bootstrap should be done directly in Supabase.
    final cloudMembers = await _cloudService.fetchMembers();
    if (cloudMembers.isEmpty) {
      return;
    }

    _members
      ..clear()
      ..addAll(cloudMembers);
  }

  Future<void> refreshFromCloud() async {
    if (!_cloudService.isConfigured) {
      return;
    }
    try {
      final cloudMembers = await _cloudService.fetchMembers();
      if (cloudMembers.isEmpty) {
        return;
      }
      _members
        ..clear()
        ..addAll(cloudMembers);
    } catch (_) {
      return;
    }
  }

  Future<Member?> fetchByMobileFromCloud(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final member = await _cloudService.fetchMemberByMobile(normalized);
      if (member == null) {
        return null;
      }
      final index = _members.indexWhere((item) => item.id == member.id);
      if (index == -1) {
        _members.add(member);
      } else {
        _members[index] = member;
      }
      return member;
    } catch (_) {
      return null;
    }
  }

  Future<Member?> fetchByEmailFromCloud(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final member = await _cloudService.fetchMemberByEmail(normalized);
      if (member == null) {
        return null;
      }
      final index = _members.indexWhere((item) => item.id == member.id);
      if (index == -1) {
        _members.add(member);
      } else {
        _members[index] = member;
      }
      return member;
    } catch (_) {
      return null;
    }
  }

  Member? findByMobile(String mobileNumber) {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
    Member? latest;
    for (final member in _members) {
      if (_normalizeMobile(member.mobileNumber) == normalized) {
        if (latest == null || member.lastUpdated.isAfter(latest.lastUpdated)) {
          latest = member;
        }
      }
    }
    return latest;
  }

  Member? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    Member? latest;
    for (final member in _members) {
      final memberEmail = member.email?.trim().toLowerCase() ?? '';
      if (memberEmail == normalized) {
        if (latest == null || member.lastUpdated.isAfter(latest.lastUpdated)) {
          latest = member;
        }
      }
    }
    return latest;
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Member? findById(String id) {
    return getById(id);
  }

  Future<bool> setMemberBlocked({
    required Member actor,
    required String memberId,
    required bool blocked,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final current = getById(memberId);
    if (current == null) {
      return false;
    }

    if (current.isAdmin) {
      return false;
    }

    final updated = current.copyWith(
      isBlocked: blocked,
      lastUpdated: DateTime.now(),
    );
    return saveMember(updated);
  }

  Future<bool> setMemberApproved({
    required Member actor,
    required String memberId,
    required bool approved,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final current = getById(memberId);
    if (current == null) {
      return false;
    }

    final updated = current.copyWith(
      isApproved: approved,
      lastUpdated: DateTime.now(),
    );
    return saveMember(updated);
  }

  List<Member> search({required String query, required String districtFilter}) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedDistrict = districtFilter.trim().toLowerCase();

    return _members.where((member) {
      if (member.isDeleted) {
        return false;
      }
      final matchesQuery = normalizedQuery.isEmpty ||
          member.name.toLowerCase().contains(normalizedQuery) ||
          member.postingLocation.toLowerCase().contains(normalizedQuery) ||
          member.role.toLowerCase().contains(normalizedQuery);
      final matchesDistrict = normalizedDistrict.isEmpty ||
          member.postingDistrict.toLowerCase().contains(normalizedDistrict);
      return matchesQuery && matchesDistrict;
    }).toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  SupabaseService get cloudService => _cloudService;

  Future<bool> setMemberRetired({
    required Member actor,
    required String memberId,
    required bool retired,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final current = getById(memberId);
    if (current == null) {
      return false;
    }

    if (current.isAdmin) {
      return false;
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      isRetired: retired,
      retiredAt: retired ? now : null,
      clearRetiredAt: !retired,
      lastUpdated: now,
    );
    return saveMember(updated);
  }

  Future<bool> setMemberDeleted({
    required Member actor,
    required String memberId,
    required bool deleted,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final current = getById(memberId);
    if (current == null) {
      return false;
    }

    if (current.isAdmin) {
      return false;
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      isDeleted: deleted,
      deletedAt: deleted ? now : null,
      clearDeletedAt: !deleted,
      lastUpdated: now,
    );
    return saveMember(updated);
  }

  Future<bool> resolvePendingUpdate({
    required Member actor,
    required String memberId,
    required bool approve,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final current = getById(memberId);
    if (current == null) {
      return false;
    }

    final raw = current.pendingUpdatePayload?.trim() ?? '';
    if (raw.isEmpty) {
      return false;
    }

    final parsedPayload = _decodePayload(raw);
    final securityPayload = _extractSecurityPayload(parsedPayload);

    if (!approve) {
      final rejected = current.copyWith(
        pendingUpdatePayload:
            securityPayload.isEmpty ? null : jsonEncode(securityPayload),
        clearPendingUpdatePayload: securityPayload.isEmpty,
        lastUpdated: DateTime.now(),
      );
      return saveMember(rejected);
    }

    try {
      final map = parsedPayload;
      final approved = current.copyWith(
        name: _stringOrCurrent(map, 'name', current.name),
        homeState: _stringOrCurrent(map, 'homeState', current.homeState),
        homeDistrict: _stringOrCurrent(map, 'homeDistrict', current.homeDistrict),
        postingState: _stringOrCurrent(map, 'postingState', current.postingState),
        postingDistrict:
            _stringOrCurrent(map, 'postingDistrict', current.postingDistrict),
        postingLocation:
            _stringOrCurrent(map, 'postingLocation', current.postingLocation),
        department: _stringOrCurrent(map, 'department', current.department),
        postRank: _stringOrCurrent(map, 'postRank', current.postRank),
        officialName:
            _stringOrCurrent(map, 'officialName', current.officialName),
        batchYear: _stringOrCurrent(map, 'batchYear', current.batchYear),
        gender: _stringOrCurrent(map, 'gender', current.gender),
        maritalStatus:
            _stringOrCurrent(map, 'maritalStatus', current.maritalStatus),
        postingCategory:
            _stringOrCurrent(map, 'postingCategory', current.postingCategory),
        postingWorkAs:
            _stringOrCurrent(map, 'postingWorkAs', current.postingWorkAs),
        whatsappNumber:
            _stringOrCurrent(map, 'whatsappNumber', current.whatsappNumber),
        callingContactNumber: _stringOrCurrent(
          map,
          'callingContactNumber',
          current.callingContactNumber,
        ),
        postingPlaceLocation: _stringOrCurrent(
          map,
          'postingPlaceLocation',
          current.postingPlaceLocation,
        ),
        homeVillageMohalla: _stringOrCurrent(
          map,
          'homeVillageMohalla',
          current.homeVillageMohalla,
        ),
        homeGaliNo: _stringOrCurrent(map, 'homeGaliNo', current.homeGaliNo),
        homePostOffice:
            _stringOrCurrent(map, 'homePostOffice', current.homePostOffice),
        homePoliceStation: _stringOrCurrent(
          map,
          'homePoliceStation',
          current.homePoliceStation,
        ),
        homeTehsil: _stringOrCurrent(map, 'homeTehsil', current.homeTehsil),
        homeVillageLocation: _stringOrCurrent(
          map,
          'homeVillageLocation',
          current.homeVillageLocation,
        ),
        selfiePath: _stringOrCurrent(map, 'selfiePath', current.selfiePath),
        pendingUpdatePayload:
            securityPayload.isEmpty ? null : jsonEncode(securityPayload),
        clearPendingUpdatePayload: securityPayload.isEmpty,
        lastUpdated: DateTime.now(),
      );
      return saveMember(approved);
    } catch (_) {
      return false;
    }
  }

  String? _stringOrCurrent(
    Map<String, dynamic> map,
    String key,
    String? currentValue,
  ) {
    final value = map[key] as String?;
    if (value == null) {
      return currentValue;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return currentValue;
    }
    return trimmed;
  }

  bool _hasPendingProfileUpdate(String? payload) {
    final parsed = _decodePayload(payload);
    if (parsed.isEmpty) {
      return false;
    }
    parsed.removeWhere(
      (key, _) => _securityPayloadKeys.contains(key),
    );
    return parsed.isNotEmpty;
  }

  Map<String, dynamic> _extractSecurityPayload(Map<String, dynamic> payload) {
    final security = <String, dynamic>{};
    for (final key in _securityPayloadKeys) {
      if (payload.containsKey(key)) {
        security[key] = payload[key];
      }
    }
    return security;
  }

  Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static const Set<String> _securityPayloadKeys = <String>{
    'biometricEnabled',
    'biometricEnrolledAt',
    'trustedDeviceId',
    'trustedDeviceFingerprint',
    'trustedDeviceBoundAt',
  };
}
