import 'package:package_info_plus/package_info_plus.dart';

import 'supabase_service.dart';

/// Result of an update check.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.isUpdateRequired,
    required this.currentVersion,
    required this.minimumVersion,
    this.downloadUrl,
  });

  /// True when the running build is below the minimum required version.
  final bool isUpdateRequired;
  final String currentVersion;
  final String minimumVersion;

  /// Optional direct download URL stored alongside the version in Supabase.
  final String? downloadUrl;
}

class AppUpdateService {
  const AppUpdateService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;

  /// Fetches `min_app_version` (and optionally `app_download_url`) from
  /// Supabase `app_settings` and compares against the installed build version.
  ///
  /// Returns null if the check cannot be completed (no network, not configured).
  Future<UpdateCheckResult?> checkForUpdate() async {
    if (!_cloudService.isConfigured) return null;

    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "0.1.4"

      final minVersion = await _cloudService.fetchAppSetting(
        key: 'min_app_version',
      );
      if (minVersion == null || minVersion.trim().isEmpty) return null;

      final downloadUrl = await _cloudService.fetchAppSetting(
        key: 'app_download_url',
      );

      final required = _isUpdateRequired(current, minVersion.trim());
      return UpdateCheckResult(
        isUpdateRequired: required,
        currentVersion: current,
        minimumVersion: minVersion.trim(),
        downloadUrl: downloadUrl?.trim().isEmpty == true ? null : downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true when [current] is strictly less than [minimum].
  /// Compares dot-separated integer segments (e.g. "0.1.3" < "0.1.4").
  static bool _isUpdateRequired(String current, String minimum) {
    final c = _segments(current);
    final m = _segments(minimum);
    final len = c.length > m.length ? c.length : m.length;
    for (var i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false; // equal — no update needed
  }

  static List<int> _segments(String version) {
    return version
        .split('.')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .toList();
  }
}
