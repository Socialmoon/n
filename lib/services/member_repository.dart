import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';

class MemberRepository {
  static const _membersKey = 'members';

  SharedPreferences? _preferences;
  final List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final items = _preferences?.getStringList(_membersKey) ?? <String>[];
    _members
      ..clear()
      ..addAll(items.map(Member.fromJson));
  }

  Future<void> saveMember(Member member) async {
    final index = _members.indexWhere((item) => item.id == member.id);
    if (index == -1) {
      _members.add(member);
    } else {
      _members[index] = member;
    }
    await _persist();
  }

  Future<void> seedAdminIfNeeded() async {
    if (_members.isNotEmpty) {
      return;
    }
    final admin = Member(
      id: 'seed-admin',
      name: 'Control Room Admin',
      mobileNumber: '9000000000',
      userId: 'admin',
      passwordHash:
          '240be518fabd2724ddb6f04eeb2e1e7d3973e87d2a7f9f46f1d0993f76de7ef8',
      mpin: '123456',
      referenceMobileNumber: '',
      referenceMemberName: null,
      homeDistrict: 'Headquarters',
      postingDistrict: 'Headquarters',
      postingLocation: 'Central Desk',
      appointmentDate: DateTime(2020, 1, 1),
      role: 'Administrator',
      lastUpdated: DateTime.now(),
      passwordUpdatedAt: DateTime.now(),
      isAdmin: true,
    );
    _members.add(admin);
    await _persist();
  }

  Member? findByMobile(String mobileNumber) {
    for (final member in _members) {
      if (member.mobileNumber == mobileNumber) {
        return member;
      }
    }
    return null;
  }

  Member? findById(String id) {
    for (final member in _members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
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