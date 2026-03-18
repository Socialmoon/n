import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import 'supabase_service.dart';

class MemberRepository {
  MemberRepository({required SupabaseService cloudService})
      : _cloudService = cloudService;

  static const _membersKey = 'members';

  final SupabaseService _cloudService;
  SharedPreferences? _preferences;
  final List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);

  Member? getById(String id) {
    for (final member in _members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final items = _preferences?.getStringList(_membersKey) ?? <String>[];
    _members
      ..clear()
      ..addAll(items.map(Member.fromJson));

    if (!_cloudService.isConfigured) {
      return;
    }

    final cloudMembers = await _cloudService.fetchMembers();
    if (cloudMembers.isNotEmpty) {
      _members
        ..clear()
        ..addAll(cloudMembers);
      await _persist();
      return;
    }
  }

  Future<void> saveMember(Member member) async {
    final index = _members.indexWhere((item) => item.id == member.id);
    if (index == -1) {
      _members.add(member);
    } else {
      _members[index] = member;
    }
    await _persist();
    await _cloudService.upsertMember(member);
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
    await _persist();
  }

  Future<void> refreshFromCloud() async {
    if (!_cloudService.isConfigured) {
      return;
    }
    final cloudMembers = await _cloudService.fetchMembers();
    if (cloudMembers.isEmpty) {
      return;
    }
    _members
      ..clear()
      ..addAll(cloudMembers);
    await _persist();
  }

  Future<Member?> fetchByMobileFromCloud(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
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
    await _persist();
    return member;
  }

  Member? findByMobile(String mobileNumber) {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
    for (final member in _members) {
      if (_normalizeMobile(member.mobileNumber) == normalized) {
        return member;
      }
    }
    return null;
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
    await saveMember(updated);
    return true;
  }

  List<Member> search({required String query, required String districtFilter}) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedDistrict = districtFilter.trim().toLowerCase();

    return _members.where((member) {
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

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _membersKey,
      _members.map((member) => member.toJson()).toList(),
    );
  }
}
