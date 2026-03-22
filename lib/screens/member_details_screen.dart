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
          _section(
            title: 'Basic',
            children: <Widget>[
              _row('Name', member.name),
              _row('Official Name', member.officialName),
              _row('Role', member.role),
              _row('Mobile', member.mobileNumber),
              _row('Whatsapp', member.whatsappNumber),
              _row('Calling Contact', member.callingContactNumber),
              _row('Emergency Contact', member.emergencyContact),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Posting Details',
            children: <Widget>[
              _row('Department', member.department),
              _row('Post / Rank', member.postRank),
              _row('Batch Year', member.batchYear),
              _row('Posting District', member.postingDistrict),
              _row('Posting Place', member.postingLocation),
              _row('Posting Place Location', member.postingPlaceLocation),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            title: 'Live Location',
            children: <Widget>[
              _row(
                'Updated At',
                member.liveLocationUpdatedAt == null
                    ? '-'
                    : member.liveLocationUpdatedAt!.toLocal().toString(),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: (member.liveLatitude == null || member.liveLongitude == null)
                        ? null
                        : () => _openMap(member.liveLatitude!, member.liveLongitude!),
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Open Live Location'),
                  ),
                ],
              ),
            ],
          ),
          if (_showHomeDetails) ...<Widget>[
            const SizedBox(height: 12),
            _section(
              title: 'Home Details (Admin Only)',
              children: <Widget>[
                _row('Home District Name', member.homeDistrict),
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
}
