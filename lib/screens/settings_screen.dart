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
import 'user_guide_screen.dart';

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
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: BrandedScreenTitle(AppStrings.tr(languageCode, 'settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: <Widget>[
              _buildSectionLabel(
                icon: Icons.shield_outlined,
                title: AppStrings.tr(languageCode, 'security'),
                color: const Color(0xFF0F3A4A),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.tr(languageCode, 'security_subtitle'),
                      style: const TextStyle(
                        color: Color(0xFF5A6B74),
                        fontSize: 13,
                      ),
                    ),
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
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
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
                        labelText:
                            AppStrings.tr(languageCode, 'confirm_mpin'),
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveMpin,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _saving
                              ? AppStrings.tr(languageCode, 'saving')
                              : AppStrings.tr(languageCode, 'update_mpin'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3A4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                icon: Icons.fingerprint_outlined,
                title: languageCode == 'hi'
                    ? 'बायोमेट्रिक'
                    : 'Biometric',
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.fingerprint_outlined,
                iconColor: const Color(0xFF7C3AED),
                title: languageCode == 'hi'
                    ? 'फिंगरप्रिंट लॉगिन'
                    : 'Fingerprint Login',
                subtitle: languageCode == 'hi'
                    ? 'इस खाते के लिए बायोमेट्रिक लॉगिन सक्षम/अपडेट करें।'
                    : 'Enable or update biometric login for this account.',
                trailing: FilledButton.tonal(
                  onPressed: _updatingBiometric
                      ? null
                      : _registerOrUpdateBiometric,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF3E8FF),
                    foregroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(_updatingBiometric
                      ? (languageCode == 'hi'
                          ? 'जांच...'
                          : 'Checking...')
                      : (languageCode == 'hi' ? 'अपडेट' : 'Update')),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                icon: Icons.tune_outlined,
                title: AppStrings.tr(languageCode, 'preferences'),
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    if (_loadingPrefs)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator(),
                      ),
                    _buildSettingsTileInline(
                      icon: Icons.language_outlined,
                      iconColor: const Color(0xFF2563EB),
                      title: AppStrings.tr(languageCode, 'language'),
                      subtitle: AppStrings.tr(languageCode, 'choose_language'),
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile.adaptive(
                      value: _notificationsEnabled,
                      onChanged: _loadingPrefs
                          ? null
                          : (enabled) => _updateNotifications(enabled),
                      title:
                          Text(AppStrings.tr(languageCode, 'notifications')),
                      subtitle: Text(AppStrings.tr(
                          languageCode, 'notifications_subtitle')),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Color(0xFF2563EB), size: 20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile.adaptive(
                      value: _vibrationEnabled,
                      onChanged: _loadingPrefs
                          ? null
                          : (enabled) => _updateVibration(enabled),
                      title: Text(AppStrings.tr(languageCode, 'vibration')),
                      subtitle: Text(
                          AppStrings.tr(languageCode, 'vibration_subtitle')),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vibration_outlined, color: Color(0xFF2563EB), size: 20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionLabel(
                icon: Icons.help_outline_rounded,
                title: languageCode == 'hi' ? 'सहायता' : 'Help & Support',
                color: const Color(0xFFD4994A),
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFFD4994A),
                title: languageCode == 'hi'
                    ? 'उपयोगकर्ता गाइड'
                    : 'User Guide',
                subtitle: languageCode == 'hi'
                    ? 'ऐप की सभी सुविधाएँ और उपयोग जानें।'
                    : 'Learn all features and how to use the app.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserGuideScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                iconColor: const Color(0xFFD97706),
                title: languageCode == 'hi'
                    ? 'बग रिपोर्ट करें'
                    : 'Report a Bug',
                subtitle: languageCode == 'hi'
                    ? 'समस्या की जानकारी सपोर्ट टीम को भेजें।'
                    : 'Send issue details to support team.',
                onTap: _reportBug,
              ),
              const SizedBox(height: 24),
              _buildSettingsTile(
                icon: Icons.logout,
                iconColor: Colors.redAccent,
                title: AppStrings.tr(languageCode, 'logout'),
                subtitle: AppStrings.tr(languageCode, 'logout_subtitle'),
                onTap: _confirmLogout,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFF5A6B74)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr(
                            languageCode, 'profile_admin_verified_message'),
                        style: const TextStyle(
                          color: Color(0xFF5A6B74),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6B74)),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BEC5)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildSettingsTileInline({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF5A6B74)),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

    final result =
        await widget.authService.registerOrUpdateBiometric(widget.currentUser);
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
