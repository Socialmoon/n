class AppSettingsService {
  static bool _notificationsEnabled = true;
  static bool _vibrationEnabled = true;

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
}
