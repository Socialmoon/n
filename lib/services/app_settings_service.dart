import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _notificationsKey = 'settings_notifications_enabled';
  static const String _vibrationKey = 'settings_vibration_enabled';
  static const String _languageKey = 'settings_language_code';
  static bool _notificationsEnabled = true;
  static bool _vibrationEnabled = true;
  static String _languageCode = 'en';
  static bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    _languageCode = prefs.getString(_languageKey) ?? 'en';
    _loaded = true;
  }

  Future<bool> getNotificationsEnabled() async {
    await _ensureLoaded();
    return _notificationsEnabled;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ensureLoaded();
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<bool> getVibrationEnabled() async {
    await _ensureLoaded();
    return _vibrationEnabled;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _ensureLoaded();
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, enabled);
  }

  Future<String> getLanguageCode() async {
    await _ensureLoaded();
    return _languageCode;
  }

  Future<void> setLanguageCode(String code) async {
    await _ensureLoaded();
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }
}
