import 'package:vibration/vibration.dart';

import '../models/emergency_alert.dart';
import '../models/member.dart';
import 'app_settings_service.dart';
import 'supabase_service.dart';

class EmergencyService {
  EmergencyService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final AppSettingsService _settingsService = AppSettingsService();
  final List<EmergencyAlert> _alerts = [];

  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts.reversed);

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }

    final cloudAlerts = await _cloudService.fetchAlerts();
    if (cloudAlerts.isEmpty) {
      for (final alert in _alerts) {
        await _cloudService.insertAlert(alert);
      }
      return;
    }

    _alerts
      ..clear()
      ..addAll(cloudAlerts.reversed);
  }

  Future<void> triggerAlert({
    required Member member,
    required String message,
  }) async {
    final alert = EmergencyAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      timestamp: DateTime.now(),
      message: message,
      location: member.postingLocation,
    );
    _alerts.add(alert);
    await _cloudService.insertAlert(alert);
    final vibrationEnabled = await _settingsService.getVibrationEnabled();
    if (vibrationEnabled && await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: <int>[0, 300, 200, 300]);
    }
  }

}