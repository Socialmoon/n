import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

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
}

class DeviceBindingService {
  static final DeviceBindingService _instance = DeviceBindingService._internal();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedDeviceId;
  String? _cachedFingerprint;

  DeviceBindingService._internal();

  factory DeviceBindingService() {
    return _instance;
  }

  /// Get or generate unique device ID
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      String deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = '';
      }
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      return '';
    }
  }

  /// Generate device fingerprint (model, OS version, app version)
  Future<String> generateFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    try {
      String fingerprint;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}|${androidInfo.version.release}|1.0.0';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}|${iosInfo.systemVersion}|1.0.0';
      } else {
        fingerprint = 'web|unknown|1.0.0';
      }
      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
      return 'unknown|unknown|1.0.0';
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
      final currentId = await getDeviceId();
      final currentFingerprint = await generateFingerprint();
      return currentId == stored.deviceId && currentFingerprint == stored.fingerprint;
    } catch (_) {
      return false;
    }
  }
}
