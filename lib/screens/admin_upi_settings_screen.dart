import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/supabase_image_headers.dart';
import '../models/member.dart';
import '../services/donation_service.dart';

class AdminUpiSettingsScreen extends StatefulWidget {
  const AdminUpiSettingsScreen({
    required this.currentUser,
    required this.donationService,
    super.key,
  });

  final Member currentUser;
  final DonationService donationService;

  @override
  State<AdminUpiSettingsScreen> createState() => _AdminUpiSettingsScreenState();
}

class _AdminUpiSettingsScreenState extends State<AdminUpiSettingsScreen> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _upiNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();
  XFile? _customQrImage;
  bool _saving = false;

  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _upiPattern =
      RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _upiIdController.text = widget.donationService.upiId;
    _upiNameController.text = widget.donationService.upiName;
    _adminMobileController.text = widget.donationService.adminMobile;
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _upiNameController.dispose();
    _adminMobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('UPI / QR Settings')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can edit UPI and QR settings.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('UPI / QR Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Admin Payment Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update UPI details. Donation screen QR will refresh from these values.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _upiIdController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _upiNameController,
                    decoration: const InputDecoration(
                      labelText: 'Beneficiary Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminMobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Admin Mobile (digits only)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save UPI Settings'),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Custom QR Image (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (widget.donationService.customQrImageUrl != null &&
                      widget.donationService.customQrImageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.donationService.customQrImageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          headers: supabaseImageHeaders(),
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 60,
                            child: Center(
                              child: Text('Current QR preview unavailable.'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_customQrImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Selected file: ${_customQrImage!.name}'),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: _pickCustomQr,
                        icon: const Icon(Icons.qr_code_2_outlined),
                        label: const Text('Choose QR Image'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _customQrImage == null ? null : _uploadCustomQr,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Upload QR'),
                      ),
                      TextButton.icon(
                        onPressed: _removeCustomQr,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Uploaded QR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final upi = _upiIdController.text.trim();
    final name = _upiNameController.text.trim();
    final mobile = _adminMobileController.text.trim();

    if (upi.isEmpty || name.isEmpty || mobile.isEmpty) {
      _showMessage('UPI ID, beneficiary name, and admin mobile are required.');
      return;
    }
    if (!_upiPattern.hasMatch(upi)) {
      _showMessage('Enter a valid UPI ID (example@bank).');
      return;
    }
    if (name.length < 2 || name.length > 60) {
      _showMessage('Beneficiary name must be 2-60 characters.');
      return;
    }
    if (!_mobilePattern.hasMatch(mobile)) {
      _showMessage('Admin mobile must be a valid 10 digit number.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final saved = await widget.donationService.updatePaymentSettings(
      actor: widget.currentUser,
      upiId: upi,
      upiName: name,
      adminMobile: mobile,
      customQrImageUrl: widget.donationService.customQrImageUrl,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    if (!saved) {
      final writeError = widget.donationService.lastWriteError;
      _showMessage(
        (writeError == null || writeError.isEmpty)
            ? 'Unable to save payment settings in cloud. Please retry.'
            : 'Unable to save payment settings in cloud: $writeError',
      );
      return;
    }

    _showMessage('Payment settings updated successfully.');
  }

  Future<void> _pickCustomQr() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _customQrImage = picked;
    });
  }

  Future<void> _uploadCustomQr() async {
    final image = _customQrImage;
    if (image == null) {
      return;
    }
    final uploaded = await widget.donationService.uploadCustomQrImage(image);
    if (!mounted) {
      return;
    }
    if (uploaded == null) {
      final uploadError = widget.donationService.lastUploadError;
      final writeError = widget.donationService.lastWriteError;
      final detail = (uploadError != null && uploadError.isNotEmpty)
          ? uploadError
          : writeError;
      final message = (detail == null || detail.isEmpty)
          ? 'Unable to upload custom QR. Please retry.'
          : 'Unable to upload custom QR: $detail';
      _showMessage(message);
      return;
    }
    setState(() {
      _customQrImage = null;
    });
    _showMessage('Custom QR uploaded successfully.');
  }

  Future<void> _removeCustomQr() async {
    final saved = await widget.donationService.updatePaymentSettings(
      actor: widget.currentUser,
      upiId: _upiIdController.text.trim().isEmpty
          ? widget.donationService.upiId
          : _upiIdController.text.trim(),
      upiName: _upiNameController.text.trim().isEmpty
          ? widget.donationService.upiName
          : _upiNameController.text.trim(),
      adminMobile: _adminMobileController.text.trim().isEmpty
          ? widget.donationService.adminMobile
          : _adminMobileController.text.trim(),
      customQrImageUrl: '',
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      final writeError = widget.donationService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to remove uploaded QR from cloud. Please retry.'
          : 'Unable to remove uploaded QR from cloud: $writeError';
      _showMessage(message);
      return;
    }
    setState(() {
      _customQrImage = null;
    });
    _showMessage('Uploaded custom QR removed.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
