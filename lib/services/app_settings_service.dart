class AppSettingsService {
  static bool _notificationsEnabled = true;
  static bool _vibrationEnabled = true;
  static String _languageCode = 'en';

  Future<bool> getNotificationsEnabled() async {
    return _notificationsEnabled;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
  }

  Future<bool> getVibrationEnabled() async {
    return _vibrationEnabled;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
  }

  Future<String> getLanguageCode() async {
    return _languageCode;
  }

  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
  }
}
