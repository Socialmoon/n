import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import '../core/app_strings.dart';
import '../core/brand.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/app_language_service.dart';
import '../services/app_settings_service.dart';
import '../services/local_notification_service.dart';
import '../services/member_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.currentUser,
    required this.repository,
    required this.authService,
    required this.onLogout,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final AuthService authService;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _bugReportMobile = '9193410557';
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final AppLanguageService _languageService = AppLanguageService();
  final AppSettingsService _settingsService = AppSettingsService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _loadingPrefs = true;
  bool _saving = false;
  bool _updatingBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _newMpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _languageService.localeListenable,
      builder: (context, locale, _) {
        final languageCode = locale.languageCode;

        return Scaffold(
          appBar: AppBar(
            title: BrandedScreenTitle(AppStrings.tr(languageCode, 'settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        AppStrings.tr(languageCode, 'security'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(AppStrings.tr(languageCode, 'security_subtitle')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _newMpinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText:
                              AppStrings.tr(languageCode, 'new_6_digit_mpin'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmMpinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: true,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: AppStrings.tr(languageCode, 'confirm_mpin'),
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _saveMpin,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _saving
                              ? AppStrings.tr(languageCode, 'saving')
                              : AppStrings.tr(languageCode, 'update_mpin'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Text(
                          AppStrings.tr(languageCode, 'preferences'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_loadingPrefs)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        ),
                      ListTile(
                        leading: const Icon(Icons.language_outlined),
                        title: Text(AppStrings.tr(languageCode, 'language')),
                        subtitle:
                            Text(AppStrings.tr(languageCode, 'choose_language')),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: languageCode,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              _languageService.setLanguageCode(value);
                            },
                            items: AppStrings.supportedLocales
                                .map((locale) => DropdownMenuItem<String>(
                                      value: locale.languageCode,
                                      child: Text(
                                        AppStrings.languageLabel(
                                          locale.languageCode,
                                          languageCode,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      SwitchListTile.adaptive(
                        value: _notificationsEnabled,
                        onChanged: _loadingPrefs
                            ? null
                            : (enabled) => _updateNotifications(enabled),
                        title: Text(AppStrings.tr(languageCode, 'notifications')),
                        subtitle:
                            Text(AppStrings.tr(languageCode, 'notifications_subtitle')),
                        secondary: const Icon(Icons.notifications_outlined),
                      ),
                      SwitchListTile.adaptive(
                        value: _vibrationEnabled,
                        onChanged: _loadingPrefs
                            ? null
                            : (enabled) => _updateVibration(enabled),
                        title: Text(AppStrings.tr(languageCode, 'vibration')),
                        subtitle:
                            Text(AppStrings.tr(languageCode, 'vibration_subtitle')),
                        secondary: const Icon(Icons.vibration_outlined),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bug_report_outlined),
                        title: Text(
                          languageCode == 'hi' ? 'बग रिपोर्ट करें' : 'Report a bug',
                        ),
                        subtitle: Text(
                          languageCode == 'hi'
                              ? 'समस्या की जानकारी सपोर्ट टीम को भेजें।'
                              : 'Send issue details to support team.',
                        ),
                        onTap: _reportBug,
                      ),
                      ListTile(
                        leading: const Icon(Icons.fingerprint_outlined),
                        title: Text(languageCode == 'hi'
                            ? 'फिंगरप्रिंट लॉगिन प्रबंधित करें'
                            : 'Manage fingerprint login'),
                        subtitle: Text(languageCode == 'hi'
                            ? 'इस खाते के लिए बायोमेट्रिक लॉगिन सक्षम/अपडेट करें।'
                            : 'Enable or update biometric login for this account.'),
                        trailing: FilledButton.tonal(
                          onPressed:
                              _updatingBiometric ? null : _registerOrUpdateBiometric,
                          child: Text(_updatingBiometric
                              ? (languageCode == 'hi' ? 'जांच...' : 'Checking...')
                              : (languageCode == 'hi' ? 'अपडेट' : 'Update')),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.logout, color: Colors.redAccent),
                        title: Text(AppStrings.tr(languageCode, 'logout')),
                        subtitle:
                            Text(AppStrings.tr(languageCode, 'logout_subtitle')),
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppStrings.tr(languageCode, 'profile_admin_verified_message'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSettings() async {
    final notifications = await _settingsService.getNotificationsEnabled();
    final vibration = await _settingsService.getVibrationEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = notifications;
      _vibrationEnabled = vibration;
      _loadingPrefs = false;
    });
  }

  Future<void> _updateNotifications(bool enabled) async {
    final languageCode = _languageService.currentLanguageCode;
    setState(() {
      _notificationsEnabled = enabled;
    });
    await _settingsService.setNotificationsEnabled(enabled);
    if (enabled) {
      await _notificationService.requestPermissionsIfNeeded();
    }
    _showMessage(
      enabled
          ? AppStrings.tr(languageCode, 'notifications_enabled')
          : AppStrings.tr(languageCode, 'notifications_disabled'),
    );
  }

  Future<void> _updateVibration(bool enabled) async {
    final languageCode = _languageService.currentLanguageCode;
    setState(() {
      _vibrationEnabled = enabled;
    });
    await _settingsService.setVibrationEnabled(enabled);
    if (enabled && await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 120);
    }
    _showMessage(
      enabled
          ? AppStrings.tr(languageCode, 'vibration_enabled')
          : AppStrings.tr(languageCode, 'vibration_disabled'),
    );
  }

  Future<void> _confirmLogout() async {
    final languageCode = _languageService.currentLanguageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.tr(languageCode, 'logout_confirm_title')),
        content: Text(AppStrings.tr(languageCode, 'logout_confirm_message')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.tr(languageCode, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.tr(languageCode, 'logout')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    widget.onLogout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _saveMpin() async {
    final languageCode = _languageService.currentLanguageCode;
    final newMpin = _newMpinController.text.trim();
    final confirm = _confirmMpinController.text.trim();

    if (!RegExp(r'^[0-9]{6}$').hasMatch(newMpin)) {
      _showMessage(AppStrings.tr(languageCode, 'mpin_exact_6'));
      return;
    }
    if (RegExp(r'^(\d)\1{5}$').hasMatch(newMpin)) {
      _showMessage('M-PIN cannot be all same digits.');
      return;
    }
    if (newMpin != confirm) {
      _showMessage(AppStrings.tr(languageCode, 'mpin_mismatch'));
      return;
    }

    setState(() {
      _saving = true;
    });

    final updated = widget.currentUser.copyWith(
      mpin: newMpin,
      passwordUpdatedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
    final saved = await widget.repository.saveMember(updated);

    if (!mounted) {
      return;
    }

    if (!saved) {
      setState(() {
        _saving = false;
      });
      _showMessage(AppStrings.tr(languageCode, 'mpin_cloud_retry'));
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
    _showMessage(AppStrings.tr(languageCode, 'mpin_updated'));
    Navigator.of(context).pop(updated);
  }

  Future<void> _reportBug() async {
    try {
      final message = Uri.encodeComponent(
        'Bug report\nMember: ${widget.currentUser.name}\nMobile: ${widget.currentUser.mobileNumber}\nIssue: ',
      );
      final uri = Uri.parse('https://wa.me/91$_bugReportMobile?text=$message');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Unable to open bug report channel. Please retry.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open bug report channel. Please retry.');
      }
    }
  }

  Future<void> _registerOrUpdateBiometric() async {
    setState(() {
      _updatingBiometric = true;
    });

    final result = await widget.authService.registerOrUpdateBiometric(widget.currentUser);
    if (!mounted) {
      return;
    }

    setState(() {
      _updatingBiometric = false;
    });

    if (!result.isSuccess) {
      _showMessage(result.error ?? 'Unable to update fingerprint login.');
      return;
    }
    _showMessage(
      _languageService.currentLanguageCode == 'hi'
          ? 'फिंगरप्रिंट लॉगिन सफलतापूर्वक अपडेट हो गया।'
          : 'Fingerprint login updated successfully.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
