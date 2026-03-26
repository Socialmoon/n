import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/member.dart';

class MemberDetailsScreen extends StatelessWidget {
  const MemberDetailsScreen({
    required this.currentUser,
    required this.member,
    super.key,
  });

  final Member currentUser;
  final Member member;

  bool get _showHomeDetails => currentUser.isAdmin;
  bool get _hasPreviousDetails =>
      (member.previousPublicProfileSnapshot ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: <Widget>[
          if (currentUser.isAdmin)
            IconButton(
              onPressed: () => _downloadMemberDetails(context),
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Download member details',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildProfileHeader(),
          const SizedBox(height: 12),
          _section(
            title: 'Member Details',
            children: <Widget>[
              _row('Sub Department Name', member.department),
              _row('Batch Year', member.batchYear),
              _row('Rank', member.postRank),
              _row('Name', member.officialName ?? member.name),
              _row('Gender', member.gender),
              _row('Married Status', member.maritalStatus),
              _row('Posting District', member.postingDistrict),
              _row('Posting Category', member.postingCategory),
              _row('Posting Place Name', member.postingLocation),
              _row('Posting Work As', member.postingWorkAs),
              _row('Whatsapp Mob. No.', member.whatsappNumber),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _postingLocationUri(member.postingPlaceLocation) == null
                        ? null
                        : () => _openUri(_postingLocationUri(member.postingPlaceLocation)!),
                    icon: const Icon(Icons.pin_drop_outlined),
                    label: const Text('Posting Location Link'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: (member.liveLatitude == null || member.liveLongitude == null)
                        ? null
                        : () => _openMap(member.liveLatitude!, member.liveLongitude!),
                    icon: const Icon(Icons.location_searching_outlined),
                    label: const Text('Current Location Link'),
                  ),
                ],
              ),
              if (member.liveLocationUpdatedAt != null)
                _row('Current Location Updated', member.liveLocationUpdatedAt!.toLocal().toString()),
            ],
          ),
          if (_hasPreviousDetails) ...<Widget>[
            const SizedBox(height: 12),
            _buildPreviousDetailsOption(),
          ],
          if (_showHomeDetails) ...<Widget>[
            const SizedBox(height: 12),
            _section(
              title: 'Home Details (Admin Only)',
              children: <Widget>[
                _row('Home District Name', member.homeDistrict),
                _row('Home State', member.homeState),
                _row('Village / Mohalla', member.homeVillageMohalla),
                _row('Gali No.', member.homeGaliNo),
                _row('Post Office', member.homePostOffice),
                _row('Home Police Station', member.homePoliceStation),
                _row('Home Tehsil', member.homeTehsil),
                _row('Home Village Location', member.homeVillageLocation),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _previousInfoRows() {
    final raw = member.previousPublicProfileSnapshot?.trim() ?? '';
    if (raw.isEmpty) {
      return const <Widget>[];
    }
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return <Widget>[
        _row('Name', _snapshotValue(parsed, 'name')),
        _row('Sub Department', _snapshotValue(parsed, 'department')),
        _row('Rank', _snapshotValue(parsed, 'postRank')),
        _row('Batch Year', _snapshotValue(parsed, 'batchYear')),
        _row('Posting Place Name', _snapshotValue(parsed, 'postingLocation')),
        _row('Posting District', _snapshotValue(parsed, 'postingDistrict')),
        _row('Whatsapp Mob. No.', _snapshotValue(parsed, 'whatsappNumber')),
        _row('Calling Contact', _snapshotValue(parsed, 'callingContactNumber')),
        _row('Emergency Contact', _snapshotValue(parsed, 'emergencyContact')),
      ];
    } catch (_) {
      return <Widget>[
        _row('Snapshot', raw),
      ];
    }
  }

  Widget _buildPreviousDetailsOption() {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        title: const Text(
          'Previous Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Visible to all members. View details before the latest profile update.',
          style: TextStyle(color: Color(0xFF5A6B74)),
        ),
        leading: const Icon(Icons.history_toggle_off_outlined),
        children: _previousInfoRows(),
      ),
    );
  }

  String? _snapshotValue(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw == null) {
      return null;
    }
    return raw.toString();
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final selfieUrl = member.selfiePath?.trim() ?? '';
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            if (selfieUrl.isEmpty)
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE8F0F5),
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              )
            else
              ClipOval(
                child: Image.network(
                  selfieUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE8F0F5),
                    child: Text(
                      initial,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(member.role),
                  Text('${member.postingLocation}, ${member.postingDistrict}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 150, child: Text(label, style: const TextStyle(color: Color(0xFF5A6B74)))),
          Expanded(child: Text((value == null || value.trim().isEmpty) ? '-' : value)),
        ],
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Uri? _postingLocationUri(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final raw = value.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    final coords = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(raw);
    if (coords == null) {
      return null;
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coords.group(1)},${coords.group(2)}',
    );
  }

  Future<void> _openUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadMemberDetails(BuildContext context) async {
    final lines = <String>[
      'Member Details Export',
      'Generated: ${DateTime.now().toLocal()}',
      '',
      ..._exportRows()
          .map((entry) => '${entry.key}: ${entry.value.isEmpty ? '-' : entry.value}'),
    ];

    final content = lines.join('\n');
    final fileName =
        'member_${member.id}_details_${DateTime.now().millisecondsSinceEpoch}.txt';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Member details export (home details excluded).',
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(content)),
              mimeType: 'text/plain',
              name: fileName,
            ),
          ],
          fileNameOverrides: <String>[fileName],
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export member details. Please retry.')),
      );
    }
  }

  List<MapEntry<String, String>> _exportRows() {
    final rows = <MapEntry<String, String>>[
      MapEntry<String, String>('Member ID', member.id),
      MapEntry<String, String>('Name', member.name),
      MapEntry<String, String>('Official Name', member.officialName ?? ''),
      MapEntry<String, String>('Mobile Number', member.mobileNumber),
      MapEntry<String, String>('Role', member.role),
      MapEntry<String, String>('Sub Department', member.department ?? ''),
      MapEntry<String, String>('Rank', member.postRank ?? ''),
      MapEntry<String, String>('Batch Year', member.batchYear ?? ''),
      MapEntry<String, String>('Gender', member.gender ?? ''),
      MapEntry<String, String>('Marital Status', member.maritalStatus ?? ''),
      MapEntry<String, String>('Posting District', member.postingDistrict),
      MapEntry<String, String>('Posting Place', member.postingLocation),
      MapEntry<String, String>('Posting Category', member.postingCategory ?? ''),
      MapEntry<String, String>('Posting Work As', member.postingWorkAs ?? ''),
      MapEntry<String, String>(
        'Posting Location Link/Coords',
        member.postingPlaceLocation ?? '',
      ),
      MapEntry<String, String>('Whatsapp Number', member.whatsappNumber ?? ''),
      MapEntry<String, String>(
        'Calling Contact Number',
        member.callingContactNumber ?? '',
      ),
      MapEntry<String, String>('Emergency Contact', member.emergencyContact ?? ''),
      MapEntry<String, String>('Is Approved', member.isApproved ? 'Yes' : 'No'),
      MapEntry<String, String>('Is Blocked', member.isBlocked ? 'Yes' : 'No'),
      MapEntry<String, String>('Is Retired', member.isRetired ? 'Yes' : 'No'),
      MapEntry<String, String>('Is Deleted', member.isDeleted ? 'Yes' : 'No'),
      MapEntry<String, String>('Last Updated', member.lastUpdated.toLocal().toString()),
      MapEntry<String, String>(
        'Last Login',
        member.lastLoginAt?.toLocal().toString() ?? '',
      ),
      MapEntry<String, String>(
        'Live Latitude',
        member.liveLatitude?.toString() ?? '',
      ),
      MapEntry<String, String>(
        'Live Longitude',
        member.liveLongitude?.toString() ?? '',
      ),
      MapEntry<String, String>(
        'Live Location Updated At',
        member.liveLocationUpdatedAt?.toLocal().toString() ?? '',
      ),
      MapEntry<String, String>(
        'Previous Public Snapshot',
        (member.previousPublicProfileSnapshot ?? '').trim(),
      ),
    ];

    return rows;
  }
}
