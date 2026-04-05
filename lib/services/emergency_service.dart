import 'package:vibration/vibration.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';

import '../models/emergency_alert.dart';
import '../models/member.dart';
import 'app_settings_service.dart';
import 'local_notification_service.dart';
import 'supabase_service.dart';

class EmergencyService extends ChangeNotifier with WidgetsBindingObserver {
  EmergencyService({required SupabaseService cloudService})
      : _cloudService = cloudService {
    WidgetsBinding.instance.addObserver(this);
  }

  final SupabaseService _cloudService;
  final AppSettingsService _settingsService = AppSettingsService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final List<EmergencyAlert> _alerts = [];
  final Set<String> _seenCloudAlertIds = <String>{};
  final Set<String> _notifiedCloudAlertIds = <String>{};
  Timer? _syncTimer;
  String? _lastLocallyTriggeredAlertId;
  bool _cloudNotificationsArmed = false;
  bool _isAppInForeground = true;
  bool _syncInProgress = false;

  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts);
  String? get lastWriteError => _cloudService.lastWriteError;

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
    // Reset on every start so app launch/login does not replay old alerts.
    _cloudNotificationsArmed = false;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
  }

  Future<bool> triggerAlert({
    required Member member,
    required String message,
  }) async {
    final alert = EmergencyAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      timestamp: DateTime.now().toUtc(),
      message: message,
      location: member.postingLocation,
    );
    final savedAlert = await _cloudService.insertAlert(alert);
    if (savedAlert == null) {
      return false;
    }

    _alerts.insert(0, savedAlert);
    notifyListeners();
    _lastLocallyTriggeredAlertId = savedAlert.id;

    await _syncFromCloud(showLocalNotificationForNew: false);

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
    return true;
  }

  Future<void> _syncFromCloud({
    required bool showLocalNotificationForNew,
  }) async {
    if (_syncInProgress) {
      return;
    }
    _syncInProgress = true;

    try {
      final cloudAlerts = await _cloudService.fetchAlerts();
      final previouslySeenIds = Set<String>.from(_seenCloudAlertIds);
      _seenCloudAlertIds.addAll(cloudAlerts.map((alert) => alert.id));

      if (cloudAlerts.isEmpty) {
        if (_alerts.isNotEmpty) {
          _alerts.clear();
          notifyListeners();
        }
        return;
      }

      final newAlerts = cloudAlerts
          .where((alert) => !previouslySeenIds.contains(alert.id))
          .toList();

      _alerts
        ..clear()
        ..addAll(cloudAlerts);
      notifyListeners();

      if (!showLocalNotificationForNew || newAlerts.isEmpty) {
        return;
      }

      // First periodic cycle after startup/login primes baseline only.
      if (!_cloudNotificationsArmed) {
        _cloudNotificationsArmed = true;
        return;
      }

      final notificationsEnabled = await _settingsService.getNotificationsEnabled();
      if (!notificationsEnabled) {
        return;
      }

      // Do not show phone notifications while app is open (login/startup/in-app).
      if (_isAppInForeground) {
        return;
      }

      for (final alert in newAlerts.reversed) {
        if (alert.id == _lastLocallyTriggeredAlertId) {
          continue;
        }
        if (_notifiedCloudAlertIds.contains(alert.id)) {
          continue;
        }
        await _localNotificationService.showEmergencyAlertNotification(
          title: 'Apne Saathi Emergency Alert',
          body: '${alert.memberName}: ${alert.message.trim().isEmpty ? 'Immediate assistance required' : alert.message.trim()}',
        );
        _notifiedCloudAlertIds.add(alert.id);
      }
    } finally {
      _syncInProgress = false;
    }
  }

}