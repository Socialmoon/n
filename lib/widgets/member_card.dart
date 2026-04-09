import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/supabase_image_headers.dart';
import '../models/member.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.member,
    this.showAdminFields = false,
    super.key,
  });

  final Member member;
  final bool showAdminFields;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildAvatar(member),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.role,
                        style: const TextStyle(color: Color(0xFF586E79)),
                      ),
                      Text(
                        '${member.postingLocation} • ${member.postingDistrict}',
                        style: const TextStyle(color: Color(0xFF586E79)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _launchUri(Uri.parse('tel:${member.mobileNumber}')),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _launchUri(
                    Uri.parse('https://wa.me/91${member.mobileNumber}'),
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WhatsApp'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: member.mobileNumber));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy Number'),
                ),
              ],
            ),
            if (showAdminFields) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Home district: ${member.homeDistrict}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildAvatar(Member member) {
    final selfieUrl = member.selfieUrl;
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();

    if (selfieUrl.isEmpty) {
      return _buildInitialAvatar(initial);
    }

    return ClipOval(
      child: Image.network(
        selfieUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        headers: supabaseImageHeaders(),
        errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
      ),
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF0F3A4A), Color(0xFF2E7D83)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}