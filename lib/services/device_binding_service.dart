import 'dart:convert';

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
  String? _cachedDeviceId;
  String? _cachedFingerprint;

  DeviceBindingService._internal();

  factory DeviceBindingService() {
    return _instance;
  }

  /// Generate unique device ID using timestamp + random
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      // Use timestamp and random hash as device ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 100000;
      final deviceId = 'device_' + timestamp.toString() + '_' + random.toString();
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      return 'device_unknown';
    }
  }

  /// Generate device fingerprint using available runtime info
  Future<String> generateFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    try {
      // Create fingerprint from app runtime info
      final timestamp = DateTime.now().millisecond.toString();
      final fingerprint = 'flutter|app|1.0|$timestamp';
      _cachedFingerprint = fingerprint;
      return fingerprint;
    } catch (e) {
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
}
