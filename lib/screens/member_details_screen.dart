import 'dart:convert';

import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
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
          if ((member.previousPublicProfileSnapshot ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _section(
              title: 'Previous Public Info',
              children: _previousInfoRows(),
            ),
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
        _row('Name', parsed['name'] as String?),
        _row('Sub Department', parsed['department'] as String?),
        _row('Rank', parsed['postRank'] as String?),
        _row('Batch Year', parsed['batchYear'] as String?),
        _row('Posting Place Name', parsed['postingLocation'] as String?),
        _row('Whatsapp Mob. No.', parsed['whatsappNumber'] as String?),
        _row('Calling Contact', parsed['callingContactNumber'] as String?),
        _row('Posting Place Location', parsed['postingPlaceLocation'] as String?),
      ];
    } catch (_) {
      return <Widget>[
        _row('Snapshot', raw),
      ];
    }
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
}
