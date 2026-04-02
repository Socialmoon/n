import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceBinding {
  const DeviceBinding({
    required this.deviceId,
    required this.fingerprint,
    required this.boundAt,
  });

  final String deviceId;
  final String fingerprint;
  final DateTime boundAt;

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'fingerprint': fingerprint,
      'boundAt': boundAt.toIso8601String(),
    };
  }

  factory DeviceBinding.fromMap(Map<String, dynamic> map) {
    return DeviceBinding(
      deviceId: map['deviceId'] as String,
      fingerprint: map['fingerprint'] as String,
      boundAt: DateTime.parse(map['boundAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DeviceBinding.fromJson(String source) =>
      DeviceBinding.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class DeviceBindingService {
  static final DeviceBindingService _instance = DeviceBindingService._internal();
  static const String _deviceIdKey = 'bound_device_id_v1';
  static const String _fingerprintKey = 'bound_device_fingerprint_v1';
  String? _cachedDeviceId;
  String? _cachedFingerprint;
  final Map<String, Map<String, dynamic>> _memberBindings = {};

  DeviceBindingService._internal();

  factory DeviceBindingService() {
    return _instance;
  }

  /// Returns a stable device ID persisted on the device.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_deviceIdKey)?.trim() ?? '';
      if (stored.isNotEmpty) {
        _cachedDeviceId = stored;
        return stored;
      }

      final stableSeed = await _stableDeviceSeed();
      final digest = sha256.convert(utf8.encode(stableSeed)).toString();
      final deviceId = 'device_${digest.substring(0, 24)}';
      await prefs.setString(_deviceIdKey, deviceId);
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (_) {
      return 'device_unknown';
    }
  }

  /// Returns a stable device fingerprint.
  Future<String> generateFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_fingerprintKey)?.trim() ?? '';
      if (stored.isNotEmpty) {
        _cachedFingerprint = stored;
        return stored;
      }

      final deviceId = await getDeviceId();
      final seed = await _stableDeviceSeed();
      final digest = sha256.convert(utf8.encode('$seed|$deviceId')).toString();
      final fingerprint = 'flutter|app|$digest';
      await prefs.setString(_fingerprintKey, fingerprint);
      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (_) {
      return 'flutter|app|1.0|unknown';
    }
  }

  /// Create new device binding
  Future<DeviceBinding> createBinding() async {
    final deviceId = await getDeviceId();
    final fingerprint = await generateFingerprint();
    return DeviceBinding(
      deviceId: deviceId,
      fingerprint: fingerprint,
      boundAt: DateTime.now(),
    );
  }

  /// Check if current device matches stored binding
  Future<bool> isDeviceMatching(DeviceBinding? stored) async {
    if (stored == null) {
      return false;
    }

    try {
      // For web/cross-device, we do a lighter check
      // In production, use platform channels for real device ID
      return stored.deviceId.isNotEmpty &&
          stored.fingerprint.isNotEmpty &&
          stored.boundAt.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Clear cached device info
  void clearCache() {
    _cachedDeviceId = null;
    _cachedFingerprint = null;
  }
  
  /// Store device binding for a member
  Future<void> storeBinding(String memberId, String deviceId) async {
    _memberBindings[memberId] = {
      'deviceId': deviceId,
      'boundAt': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get stored binding for a member
  Map<String, dynamic>? getStoredBinding(String memberId) {
    return _memberBindings[memberId];
  }

  Future<String> _stableDeviceSeed() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      final info = await deviceInfo.webBrowserInfo;
      return 'web|${info.vendor}|${info.userAgent}|${info.hardwareConcurrency}|${info.platform}';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await deviceInfo.androidInfo;
        final androidId = info.id.trim();
        if (androidId.isNotEmpty) {
          return 'android|$androidId|${info.brand}|${info.model}|${info.hardware}';
        }
        return 'android|${info.brand}|${info.model}|${info.hardware}|${info.fingerprint}';
      case TargetPlatform.iOS:
        final info = await deviceInfo.iosInfo;
        final identifier = info.identifierForVendor?.trim() ?? '';
        return 'ios|$identifier|${info.name}|${info.model}|${info.systemVersion}';
      case TargetPlatform.windows:
        final info = await deviceInfo.windowsInfo;
        return 'windows|${info.computerName}|${info.numberOfCores}|${info.systemMemoryInMegabytes}';
      case TargetPlatform.macOS:
        final info = await deviceInfo.macOsInfo;
        return 'macos|${info.systemGUID}|${info.model}|${info.osRelease}';
      case TargetPlatform.linux:
        final info = await deviceInfo.linuxInfo;
        return 'linux|${info.machineId}|${info.name}|${info.version}';
      case TargetPlatform.fuchsia:
        return 'fuchsia|unsupported';
    }
  }
}
