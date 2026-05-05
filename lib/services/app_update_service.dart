import 'dart:async';

import 'package:http/http.dart' as http;
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
  static const Duration _urlProbeTimeout = Duration(seconds: 5);

  /// Fetches `min_app_version` and update URLs from Supabase `app_settings`
  /// and compares against the installed build version.
  ///
  /// URL strategy:
  /// - Primary key: `app_download_url`
  /// - Fallback key: `app_download_fallback_url` (optional)
  ///
  /// If primary is not reachable (e.g. restricted/unavailable), fallback is
  /// used when valid and reachable.
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

      final primaryDownloadUrl = await _cloudService.fetchAppSetting(
        key: 'app_download_url',
      );
      final fallbackDownloadUrl = await _cloudService.fetchAppSetting(
        key: 'app_download_fallback_url',
      );

      final downloadUrl = await _pickDownloadUrl(
        primary: primaryDownloadUrl,
        fallback: fallbackDownloadUrl,
      );

      final required = _isUpdateRequired(current, minVersion.trim());
      return UpdateCheckResult(
        isUpdateRequired: required,
        currentVersion: current,
        minimumVersion: minVersion.trim(),
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _pickDownloadUrl({
    required String? primary,
    required String? fallback,
  }) async {
    final primaryUrl = _normalizeUrl(primary);
    final fallbackUrl = _normalizeUrl(fallback);

    if (primaryUrl == null) return fallbackUrl;

    final primaryOk = await _isUrlReachable(primaryUrl);
    if (primaryOk) return primaryUrl;

    if (fallbackUrl != null) {
      final fallbackOk = await _isUrlReachable(fallbackUrl);
      if (fallbackOk) return fallbackUrl;
    }

    // Keep a usable URL for admin-controlled/manual recovery, even if probe
    // fails due to transient connectivity from this device.
    return fallbackUrl ?? primaryUrl;
  }

  static String? _normalizeUrl(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return Uri.tryParse(normalized) == null ? null : normalized;
  }

  Future<bool> _isUrlReachable(String url) async {
    final uri = Uri.parse(url);

    try {
      final response = await http
          .head(uri)
          .timeout(_urlProbeTimeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      // Some endpoints do not allow HEAD; fallback to lightweight GET.
      try {
        final response = await http
            .get(uri, headers: const <String, String>{'Range': 'bytes=0-0'})
            .timeout(_urlProbeTimeout);
        return response.statusCode >= 200 && response.statusCode < 400;
      } catch (_) {
        return false;
      }
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
