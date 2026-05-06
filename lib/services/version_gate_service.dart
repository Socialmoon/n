// lib/services/version_gate_service.dart
// Enforces app version requirements and blocks old clients

import 'package:package_info_plus/package_info_plus.dart';
import 'supabase_service.dart';

class VersionGateService {
  const VersionGateService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  final SupabaseService _supabaseService;

  /// Check if current app version meets minimum requirement
  /// If not, returns VersionBlockReason with blocking details
  Future<VersionBlockReason?> checkVersionGate() async {
    if (!_supabaseService.isConfigured) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "0.1.4"

      // Fetch minimum required version from Supabase
      final minVersionString = await _supabaseService.fetchAppSetting(
        key: 'min_app_version',
      );

      if (minVersionString == null || minVersionString.isEmpty) {
        return null; // No version requirement set
      }

      // Check if update is required
      if (_isVersionTooOld(currentVersion, minVersionString)) {
        // Fetch update messaging
        final title = await _supabaseService.fetchAppSetting(
          key: 'update_required_title',
        );
        final message = await _supabaseService.fetchAppSetting(
          key: 'update_required_message',
        );
        final downloadUrl = await _supabaseService.fetchAppSetting(
          key: 'app_download_url',
        );
        final canSkip = await _supabaseService.fetchAppSetting(
          key: 'can_skip_update',
        );

        return VersionBlockReason(
          isBlocked: true,
          currentVersion: currentVersion,
          minimumVersion: minVersionString,
          title: title ?? 'Update Required',
          message: message ?? 'Please update to continue using the app.',
          downloadUrl: downloadUrl,
          canSkip: canSkip?.toLowerCase() == 'true' ? true : false,
        );
      }

      return null; // Version is acceptable
    } catch (_) {
      return null; // Error checking version - don't block
    }
  }

  /// Check if app can load images/media
  /// Returns false if version is too old (saves egress)
  Future<bool> canLoadMedia() async {
    final blockReason = await checkVersionGate();
    return blockReason == null || !blockReason.isBlocked;
  }

  static bool _isVersionTooOld(String current, String minimum) {
    final c = _parseVersion(current);
    final m = _parseVersion(minimum);

    final maxLen = c.length > m.length ? c.length : m.length;
    for (var i = 0; i < maxLen; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;

      if (cv < mv) return true; // Current is older
      if (cv > mv) return false; // Current is newer
    }

    return false; // Versions are equal
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('+')[0] // Remove build number (e.g., "0.1.4+5" → "0.1.4")
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
  }
}

class VersionBlockReason {
  const VersionBlockReason({
    required this.isBlocked,
    required this.currentVersion,
    required this.minimumVersion,
    required this.title,
    required this.message,
    this.downloadUrl,
    required this.canSkip,
  });

  final bool isBlocked;
  final String currentVersion;
  final String minimumVersion;
  final String title;
  final String message;
  final String? downloadUrl;
  final bool canSkip;
}
