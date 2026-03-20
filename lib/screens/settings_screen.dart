import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/member_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.currentUser,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  bool _saving = false;

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
