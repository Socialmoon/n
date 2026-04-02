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
              _row('Posting Work As', _displayValue(member.postingWorkAs)),
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
    final rows = _exportRows();
    final content = _buildExportHtml(rows);
    final fileName =
        'member_${member.id}_details_${DateTime.now().millisecondsSinceEpoch}.html';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Member details export (home details excluded).',
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(content)),
              mimeType: 'text/html',
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
    final postingDetails = <String>[
      member.postingDistrict,
      member.postingLocation,
      if ((member.postingCategory ?? '').trim().isNotEmpty)
        'Category: ${member.postingCategory}',
      if ((member.postingWorkAs ?? '').trim().isNotEmpty)
        'Work As: ${_displayValue(member.postingWorkAs)}',
    ].where((item) => item.trim().isNotEmpty).join(' | ');

    final contactDetails = <String>[
      'Whatsapp: ${member.whatsappNumber ?? ''}',
      'Calling: ${member.callingContactNumber ?? ''}',
    ].join(' | ');

    final rows = <MapEntry<String, String>>[
      MapEntry<String, String>('Name', member.officialName ?? member.name),
      MapEntry<String, String>('Mobile Number', member.mobileNumber),
      MapEntry<String, String>('Sub Department', member.department ?? ''),
      MapEntry<String, String>('Rank', member.postRank ?? ''),
      MapEntry<String, String>('Batch Year', member.batchYear ?? ''),
      MapEntry<String, String>('Gender', member.gender ?? ''),
      MapEntry<String, String>('Posting Details', postingDetails),
      MapEntry<String, String>('Calling Contacts', contactDetails),
    ];

    return rows;
  }

  String _buildExportHtml(List<MapEntry<String, String>> rows) {
    final details = rows
        .map(
          (entry) => '''
            <div class="row">
              <div class="label">${_escapeHtml(entry.key)}</div>
              <div class="value">${entry.value.isEmpty ? '-' : _escapeHtml(entry.value)}</div>
            </div>
          ''',
        )
        .join();

    final profileUrl = _safePhotoUrl(member.selfiePath);
    final profileHtml = profileUrl == null
        ? '<div class="avatar-fallback">No Photo</div>'
        : '<img class="avatar" src="$profileUrl" alt="Member photo" />';

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Member Details Export</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; font-family: Arial, sans-serif; background: #f4f7fb; color: #123; }
    .page { padding: 14px; }
    .card { width: 100%; max-width: 760px; margin: 0 auto; background: #fff; border: 1px solid #dde6ec; border-radius: 14px; overflow: hidden; }
    .head { background: linear-gradient(135deg, #123c56, #266d7a); color: #fff; padding: 16px 18px; }
    .head h1 { margin: 0; font-size: 20px; }
    .head p { margin: 6px 0 0; font-size: 13px; color: #e2eef3; }
    .photo-wrap { padding: 16px 16px 0; display: flex; justify-content: center; }
    .avatar { width: 120px; height: 120px; border-radius: 50%; object-fit: cover; object-position: center; border: 2px solid #d6e2ea; image-rendering: auto; }
    .avatar-fallback { width: 120px; height: 120px; border-radius: 50%; border: 2px dashed #c4d2db; color: #5a6b74; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; background: #f7fbfd; }
    .body { padding: 14px 16px; }
    .row { display: grid; grid-template-columns: 220px 1fr; gap: 10px; padding: 8px 0; border-bottom: 1px dashed #e6edf2; }
    .row:last-child { border-bottom: none; }
    .label { font-size: 12px; color: #5a6b74; font-weight: 600; }
    .value { font-size: 13px; color: #1c2f38; }
    @media (max-width: 560px) {
      .page { padding: 8px; }
      .head h1 { font-size: 18px; }
      .row { grid-template-columns: 1fr; gap: 4px; }
      .label { font-size: 11px; }
      .value { font-size: 14px; word-break: break-word; }
      .avatar, .avatar-fallback { width: 96px; height: 96px; }
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="card">
      <div class="head">
        <h1>Member Details Export</h1>
        <p>Generated: ${DateTime.now().toLocal()}</p>
      </div>
      <div class="photo-wrap">
        $profileHtml
      </div>
      <div class="body">
        $details
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  String? _safePhotoUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return _escapeHtml(url);
    }
    return null;
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String? _displayValue(String? value) {
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
