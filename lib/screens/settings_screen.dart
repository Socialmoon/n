import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/member.dart';
import '../services/app_settings_service.dart';
import '../services/member_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.currentUser,
    required this.repository,
    required this.onLogout,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final AppSettingsService _settingsService = AppSettingsService();
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _loadingPrefs = true;
  bool _saving = false;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                  const Text(
                    'Security',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set or update your 6 digit M-PIN used for login.',
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
                    decoration: const InputDecoration(
                      labelText: 'New 6 digit M-PIN',
                      prefixIcon: Icon(Icons.lock_outline),
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
                    decoration: const InputDecoration(
                      labelText: 'Confirm M-PIN',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveMpin,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: Text(_saving ? 'Saving...' : 'Update M-PIN'),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Text(
                      'Preferences',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_loadingPrefs)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  SwitchListTile.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _loadingPrefs
                        ? null
                        : (enabled) => _updateNotifications(enabled),
                    title: const Text('In-app notifications'),
                    subtitle: const Text('Show alerts and action confirmations.'),
                    secondary: const Icon(Icons.notifications_outlined),
                  ),
                  SwitchListTile.adaptive(
                    value: _vibrationEnabled,
                    onChanged:
                        _loadingPrefs ? null : (enabled) => _updateVibration(enabled),
                    title: const Text('Vibration'),
                    subtitle:
                        const Text('Vibrate on emergency actions and alerts.'),
                    secondary: const Icon(Icons.vibration_outlined),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out from this device now.'),
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Profile fields marked as admin verified can only be changed by admin workflows.',
              ),
            ),
          ),
        ],
      ),
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
    setState(() {
      _notificationsEnabled = enabled;
    });
    await _settingsService.setNotificationsEnabled(enabled);
    _showMessage(
      enabled ? 'In-app notifications enabled.' : 'In-app notifications disabled.',
    );
  }

  Future<void> _updateVibration(bool enabled) async {
    setState(() {
      _vibrationEnabled = enabled;
    });
    await _settingsService.setVibrationEnabled(enabled);
    if (enabled && await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 120);
    }
    _showMessage(enabled ? 'Vibration enabled.' : 'Vibration disabled.');
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout now?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
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
    final newMpin = _newMpinController.text.trim();
    final confirm = _confirmMpinController.text.trim();

    if (newMpin.length != 6) {
      _showMessage('M-PIN must be exactly 6 digits.');
      return;
    }
    if (newMpin != confirm) {
      _showMessage('M-PIN confirmation does not match.');
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
    await widget.repository.saveMember(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
    _showMessage('M-PIN updated successfully.');
    Navigator.of(context).pop(updated);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
