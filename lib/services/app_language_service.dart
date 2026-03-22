import 'package:flutter/material.dart';

import 'app_settings_service.dart';

class AppLanguageService {
  static final ValueNotifier<Locale> _localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));
  static const Set<String> _supportedCodes = <String>{'en', 'hi'};

  final AppSettingsService _settingsService = AppSettingsService();

  ValueNotifier<Locale> get localeListenable => _localeNotifier;

  Locale get currentLocale => _localeNotifier.value;

  String get currentLanguageCode => _localeNotifier.value.languageCode;

  Future<void> loadSavedLanguage() async {
    final savedCode = await _settingsService.getLanguageCode();
    _localeNotifier.value = Locale(_normalizeCode(savedCode));
  }

  Future<void> setLanguageCode(String languageCode) async {
    final code = _normalizeCode(languageCode);
    _localeNotifier.value = Locale(code);
    await _settingsService.setLanguageCode(code);
  }

  String _normalizeCode(String code) {
    return _supportedCodes.contains(code) ? code : 'en';
  }
}