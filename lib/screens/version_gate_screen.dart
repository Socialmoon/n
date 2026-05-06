// lib/screens/version_gate_screen.dart
// Shows blocking update screen when app version is too old

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/version_gate_service.dart';

class VersionGateScreen extends StatelessWidget {
  const VersionGateScreen({
    required this.blockReason,
    super.key,
  });

  final VersionBlockReason blockReason;

  static const Color _inkColor = Color(0xFF0F2638);
  static const Color _tealColor = Color(0xFF2E7D83);
  static const Color _goldColor = Color(0xFFD4994A);
  static const Color _softTealColor = Color(0xFF5AAFB5);

  Future<void> _launchDownload() async {
    final downloadUrl = blockReason.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) return;

    final uri = Uri.tryParse(downloadUrl);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: blockReason.canSkip,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'logos/logo2.png',
                      width: 96,
                      height: 96,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      blockReason.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _inkColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      blockReason.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _tealColor,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _softTealColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _softTealColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          _buildVersionRow(
                            context,
                            label: 'Your version',
                            value: blockReason.currentVersion,
                          ),
                          const SizedBox(height: 10),
                          _buildVersionRow(
                            context,
                            label: 'Required',
                            value: blockReason.minimumVersion,
                            valueColor: _goldColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _launchDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tealColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (blockReason.canSkip) ...<Widget>[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _tealColor,
                            side: const BorderSide(color: _tealColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Skip for Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'We require updates to protect your data and keep media delivery under control.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _tealColor.withValues(alpha: 0.75),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? _inkColor,
              ),
        ),
      ],
    );
  }
}
