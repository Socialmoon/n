import 'package:vibration/vibration.dart';
import 'dart:async';

import '../models/emergency_alert.dart';
import '../models/member.dart';
import 'app_settings_service.dart';
import 'local_notification_service.dart';
import 'supabase_service.dart';

class EmergencyService {
  EmergencyService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final AppSettingsService _settingsService = AppSettingsService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final List<EmergencyAlert> _alerts = [];
  Timer? _syncTimer;
  String? _lastLocallyTriggeredAlertId;

  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts.reversed);

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }

    await _syncFromCloud(showLocalNotificationForNew: false);
  }

  Future<void> startAlertSync({
    Duration interval = const Duration(seconds: 12),
  }) async {
    if (!_cloudService.isConfigured) {
      return;
    }
    await _syncFromCloud(showLocalNotificationForNew: false);
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) {
      unawaited(_syncFromCloud(showLocalNotificationForNew: true));
    });
  }

  void stopAlertSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<bool> triggerAlert({
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
    _lastLocallyTriggeredAlertId = alert.id;
    final saved = await _cloudService.insertAlert(alert);
    final notificationsEnabled = await _settingsService.getNotificationsEnabled();
    final vibrationEnabled = await _settingsService.getVibrationEnabled();
    if (vibrationEnabled && await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: <int>[0, 300, 200, 300]);
    }
    if (notificationsEnabled) {
      await _localNotificationService.showEmergencyAlertNotification(
        title: 'Apne Saathi Emergency Alert',
        body: '${member.name}: ${message.trim().isEmpty ? 'Immediate assistance required' : message.trim()}',
      );
    }
    return saved;
  }

  Future<void> _syncFromCloud({
    required bool showLocalNotificationForNew,
  }) async {
    final cloudAlerts = await _cloudService.fetchAlerts();
    if (cloudAlerts.isEmpty) {
      return;
    }

    final existingIds = _alerts.map((alert) => alert.id).toSet();
    final newAlerts = cloudAlerts
        .where((alert) => !existingIds.contains(alert.id))
        .toList();

    _alerts
      ..clear()
      ..addAll(cloudAlerts.reversed);

    if (!showLocalNotificationForNew || newAlerts.isEmpty) {
      return;
    }

    final notificationsEnabled = await _settingsService.getNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    for (final alert in newAlerts.reversed) {
      if (alert.id == _lastLocallyTriggeredAlertId) {
        continue;
      }
      await _localNotificationService.showEmergencyAlertNotification(
        title: 'Apne Saathi Emergency Alert',
        body: '${alert.memberName}: ${alert.message.trim().isEmpty ? 'Immediate assistance required' : alert.message.trim()}',
      );
    }
  }

}