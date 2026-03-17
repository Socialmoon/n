import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../models/emergency_alert.dart';
import '../models/member.dart';

class EmergencyService {
  static const _alertsKey = 'emergency_alerts';

  SharedPreferences? _preferences;
  final List<EmergencyAlert> _alerts = [];

  List<EmergencyAlert> get alerts => List.unmodifiable(_alerts.reversed);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final rawAlerts = _preferences?.getStringList(_alertsKey) ?? <String>[];
    _alerts
      ..clear()
      ..addAll(rawAlerts.map(EmergencyAlert.fromJson));
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
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _alertsKey,
      _alerts.map((entry) => entry.toJson()).toList(),
    );
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(pattern: <int>[0, 300, 200, 300]);
    }
  }
}