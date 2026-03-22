import '../models/member.dart';
import 'supabase_service.dart';

class MemberRepository {
  MemberRepository({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);

  List<Member> get pendingApprovals => _members
      .where((member) => !member.isApproved && !member.isAdmin)
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

    final cloudMembers = await _cloudService.fetchMembers();
    if (cloudMembers.isNotEmpty) {
      _members
        ..clear()
        ..addAll(cloudMembers);
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
    final success = await _cloudService.upsertMember(member);
    if (!success) {
      if (index == -1) {
        _members.removeWhere((item) => item.id == member.id);
      } else if (previous != null) {
        _members[index] = previous;
      }
    }
    return success;
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
    final cloudMembers = await _cloudService.fetchMembers();
    if (cloudMembers.isEmpty) {
      return;
    }
    _members
      ..clear()
      ..addAll(cloudMembers);
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
    return member;
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
}
