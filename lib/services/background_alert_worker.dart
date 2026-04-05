import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/supabase_config.dart';

const String emergencyAlertBackgroundTask = 'emergency_alert_background_poll';
const String _lastAlertIdKey = 'bg_last_seen_alert_id';
const String _notificationsEnabledKey = 'settings_notifications_enabled';

@pragma('vm:entry-point')
void backgroundAlertCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != emergencyAlertBackgroundTask) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      if (!notificationsEnabled) {
        return true;
      }

      final uri = Uri.parse(
        '${SupabaseConfig.url}/rest/v1/emergency_alerts?select=id,member_name,message&order=created_at.desc&limit=1',
      );
      final response = await http.get(
        uri,
        headers: <String, String>{
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return true;
      }

      final parsed = jsonDecode(response.body);
      if (parsed is! List || parsed.isEmpty) {
        return true;
      }

      final latest = parsed.first as Map<String, dynamic>;
      final latestId = (latest['id'] ?? '').toString();
      if (latestId.isEmpty) {
        return true;
      }

      final previousId = prefs.getString(_lastAlertIdKey) ?? '';
      if (previousId == latestId) {
        return true;
      }

      final notifier = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await notifier.initialize(initSettings);

      final memberName = (latest['member_name'] ?? 'Member').toString();
      final message = (latest['message'] ?? 'Immediate assistance required').toString();

      const androidDetails = AndroidNotificationDetails(
        'emergency_alerts',
        'Emergency Alerts',
        channelDescription: 'Critical emergency alerts and warnings.',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await notifier.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Apne Saathi Emergency Alert',
        '$memberName: $message',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      await prefs.setString(_lastAlertIdKey, latestId);
      return true;
    } catch (_) {
      return true;
    }
  });
}
