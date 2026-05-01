import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/cdn_config.dart';
import '../core/time_utils.dart';
import '../models/member.dart';
import '../services/member_repository.dart';
import 'member_details_screen.dart';

class AdminAllMembersScreen extends StatefulWidget {
  const AdminAllMembersScreen({
    required this.currentUser,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  State<AdminAllMembersScreen> createState() => _AdminAllMembersScreenState();
}

class _AdminAllMembersScreenState extends State<AdminAllMembersScreen> {
  bool _refreshing = false;
  bool _adminsOnly = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const BrandedScreenTitle('All Members (Admin)')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can access this screen.'),
          ),
        ),
      );
    }

    final members = widget.repository.members
      .where((member) => member.isApproved)
      .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final query = _query.trim().toLowerCase();
    final filtered = members.where((member) {
      if (_adminsOnly && !member.isAdmin) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return member.name.toLowerCase().contains(query) ||
          member.mobileNumber.toLowerCase().contains(query) ||
          member.postingLocation.toLowerCase().contains(query) ||
          member.postingDistrict.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query) ||
          (member.isAdmin && 'admin'.contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('All Members (Admin)'),
        actions: <Widget>[
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh members',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search member',
              hintText: 'Name, mobile, posting location, district, role',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilterChip(
                label: const Text('Admins only'),
                selected: _adminsOnly,
                onSelected: (selected) {
                  setState(() {
                    _adminsOnly = selected;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total members: ${filtered.length}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No members found.'),
              ),
            ),
          ...filtered.map(_buildMemberCard),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    final postingLocationUpdated =
        (member.postingPlaceLocation ?? '').trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GestureDetector(
          onTap: () => _openMemberProfile(member),
          child: _avatar(member),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${member.postingLocation}, ${member.postingDistrict}\n'
          'Posting location updated: ${postingLocationUpdated ? 'Yes' : 'No'}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openMemberDetails(member),
      ),
    );
  }

  Widget _avatar(Member member) {
    final selfieUrl = member.selfieUrl;
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();

    if (selfieUrl.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFE8F0F5),
        child: Text(initial),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: selfieUrl,
        httpHeaders: CdnConfig.headersFor(selfieUrl),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE8F0F5),
          child: Text(initial),
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE8F0F5),
          child: Text(initial),
        ),
      ),
    );
  }

  Future<void> _openMemberDetails(Member member) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _AdminMemberDetailsScreen(
          member: member,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _openMemberProfile(Member member) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MemberDetailsScreen(
          currentUser: widget.currentUser,
          member: member,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
    });
    await widget.repository.refreshFromCloud();
    if (!mounted) {
      return;
    }
    setState(() {
      _refreshing = false;
    });
  }
}

class _AdminMemberDetailsScreen extends StatelessWidget {
  const _AdminMemberDetailsScreen({
    required this.member,
    required this.currentUser,
  });

  final Member member;
  final Member currentUser;

  @override
  Widget build(BuildContext context) {
    final postingLocationUpdated =
        (member.postingPlaceLocation ?? '').trim().isNotEmpty;
    final whatsapp = (member.whatsappNumber ?? '').trim().isEmpty
        ? member.mobileNumber
        : member.whatsappNumber!;

    return Scaffold(
      appBar: AppBar(title: const BrandedScreenTitle('Member Full Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _buildProfileAvatar(member),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${member.postingLocation}, ${member.postingDistrict}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _statusChip('Approved', member.isApproved),
                      _statusChip('Blocked', member.isBlocked),
                      _statusChip('Retired', member.isRetired),
                      _statusChip('Deleted', member.isDeleted),
                      _statusChip('Posting Location Updated', postingLocationUpdated),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _openPhone(member.mobileNumber),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openWhatsApp(whatsapp),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _postingLocationUri(member.postingPlaceLocation) == null
                        ? null
                        : () => _openUri(_postingLocationUri(member.postingPlaceLocation)!),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Posting Map Link'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _row('ID', member.id),
                  _row('User ID', member.userId),
                  _row('Email', member.email),
                  _row('Role', member.role),
                  _row('MPIN', member.mpin),
                  _row('Mobile Number', member.mobileNumber),
                  _row('Whatsapp Number', member.whatsappNumber),
                  _row('Calling Contact Number', member.callingContactNumber),
                  _row('Reference Mobile Number', member.referenceMobileNumber),
                  _row('Reference Member Name', member.referenceMemberName),
                  _row('Official Name', member.officialName),
                  _row('Department', member.department),
                  _row('Post Rank', member.postRank),
                  _row('Batch Year', member.batchYear),
                  _row('Gender', member.gender),
                  _row('Marital Status', member.maritalStatus),
                  _row('Home State', member.homeState),
                  _row('Home District', member.homeDistrict),
                  _row('Home Village / Mohalla', member.homeVillageMohalla),
                  _row('Home Gali No', member.homeGaliNo),
                  _row('Home Post Office', member.homePostOffice),
                  _row('Home Police Station', member.homePoliceStation),
                  _row('Home Tehsil', member.homeTehsil),
                  _row('Home Village Location', member.homeVillageLocation),
                  _row('Posting State', member.postingState),
                  _row('Posting District', member.postingDistrict),
                  _row('Posting Location', member.postingLocation),
                  _row('Posting Category', _displayValue(member.postingCategory)),
                  _row('Posting Work As', _displayValue(member.postingWorkAs)),
                  _row('Posting Place Location Link', member.postingPlaceLocation),
                  _row('Posting Location Updated?', postingLocationUpdated ? 'Yes' : 'No'),
                  _row('Emergency Contact', member.emergencyContact),
                  _row('Selfie Path', member.selfiePath),
                  _row('ID Card Path', member.idCardPhotoPath),
                  _row('Live Latitude', member.liveLatitude?.toString()),
                  _row('Live Longitude', member.liveLongitude?.toString()),
                  _row(
                    'Live Location Updated At',
                    member.liveLocationUpdatedAt == null ? '-' : formatIstDateTime(member.liveLocationUpdatedAt!),
                  ),
                  _row(
                    'Last Login',
                    member.lastLoginAt == null ? '-' : formatIstDateTime(member.lastLoginAt!),
                  ),
                  _row('Appointment Date', formatIstDateTime(member.appointmentDate)),
                  _row('Last Updated', formatIstDateTime(member.lastUpdated)),
                  _row('Password Updated At', formatIstDateTime(member.passwordUpdatedAt)),
                  _row('Retired At', member.retiredAt == null ? '-' : formatIstDateTime(member.retiredAt!)),
                  _row('Deleted At', member.deletedAt == null ? '-' : formatIstDateTime(member.deletedAt!)),
                  _row(
                    'Pending Update Payload',
                    (member.pendingUpdatePayload ?? '').trim().isEmpty ? '-' : 'Available',
                  ),
                  _row(
                    'Previous Profile Snapshot',
                    (member.previousPublicProfileSnapshot ?? '').trim().isEmpty ? '-' : 'Available',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(String label, bool enabled) {
    return Chip(
      label: Text('$label: ${enabled ? 'Yes' : 'No'}'),
      backgroundColor: enabled ? const Color(0xFFE8F5EA) : const Color(0xFFF2F4F7),
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget _buildProfileAvatar(Member member) {
    final selfieUrl = member.selfieUrl;
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();

    if (selfieUrl.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFFE8F0F5),
        child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: selfieUrl,
        httpHeaders: CdnConfig.headersFor(selfieUrl),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (_, __) => CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE8F0F5),
          child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE8F0F5),
          child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  static Widget _row(String label, String? value) {
    final text = (value ?? '').trim().isEmpty ? '-' : value!.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 180,
            child: Text(label, style: const TextStyle(color: Color(0xFF5A6B74))),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  static Uri? _postingLocationUri(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(text);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final direct = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(text);
    if (direct != null) {
      final lat = direct.group(1)!;
      final lng = direct.group(2)!;
      return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    }

    final encoded = Uri.encodeComponent(text);
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  }

  static Future<void> _openPhone(String mobile) async {
    try {
      final uri = Uri.parse('tel:$mobile');
      await launchUrl(uri);
    } catch (_) {
      return;
    }
  }

  static Future<void> _openWhatsApp(String mobile) async {
    try {
      final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        return;
      }
      final normalized = digits.length > 10 ? digits : '91$digits';
      final uri = Uri.parse('https://wa.me/$normalized');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return;
    }
  }

  static Future<void> _openUri(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return;
    }
  }

  static String? _displayValue(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return value;
    }
    final normalized = raw.toLowerCase();
    if (normalized == 'n/a' || normalized == 'na') {
      return 'Others';
    }
    return value;
  }
}
