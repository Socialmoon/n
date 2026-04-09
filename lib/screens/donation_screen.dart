import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/time_utils.dart';
import '../models/donation_entry.dart';
import '../core/supabase_image_headers.dart';
import '../models/member.dart';
import '../services/donation_service.dart';

enum DonationTab {
  donate,
  history,
  leaderboard,
  paymentSettings,
}

class DonationScreen extends StatefulWidget {
  const DonationScreen({
    required this.currentUser,
    required this.donationService,
    super.key,
  });

  final Member currentUser;
  final DonationService donationService;

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _transactionRefController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _upiNameController = TextEditingController();
  final TextEditingController _adminMobileController = TextEditingController();

  XFile? _proofScreenshot;
  XFile? _customQrImage;
  DonationTab _selectedTab = DonationTab.donate;
  String? _selectedMemberMobile;
  bool _savingPaymentSettings = false;
  bool _submittingDonation = false;
  String _submitPhase = '';
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _upiPattern = RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$');
  static final RegExp _safeRefPattern = RegExp(r'^[A-Za-z0-9-]{4,40}$');

  bool get _isAdmin => widget.currentUser.isAdmin;

  String get _activeUpiId {
    if (_upiIdController.text.trim().isNotEmpty) {
      return _upiIdController.text.trim();
    }
    return widget.donationService.upiId;
  }

  String get _activeUpiName {
    if (_upiNameController.text.trim().isNotEmpty) {
      return _upiNameController.text.trim();
    }
    return widget.donationService.upiName;
  }

  String get _activeAdminMobile {
    if (_adminMobileController.text.trim().isNotEmpty) {
      return _adminMobileController.text.trim();
    }
    return widget.donationService.adminMobile;
  }

  String get _upiUri {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final query = <String, String>{
      'pa': _activeUpiId.trim(),
      'pn': _activeUpiName.trim(),
      'cu': 'INR',
    };
    if (amount != null && amount > 0) {
      query['am'] = amount.toStringAsFixed(2);
    }
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: query,
    ).toString();
  }

  @override
  void initState() {
    super.initState();
    _upiIdController.text = widget.donationService.upiId;
    _upiNameController.text = widget.donationService.upiName;
    _adminMobileController.text = widget.donationService.adminMobile;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _transactionRefController.dispose();
    _memberSearchController.dispose();
    _upiIdController.dispose();
    _upiNameController.dispose();
    _adminMobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 420;
    final tabs = <DonationTab>[DonationTab.donate, DonationTab.history];
    if (_isAdmin) {
      tabs.add(DonationTab.leaderboard);
    }

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('Member Donations'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<DonationTab>(
                segments: tabs
                    .map(
                      (tab) => ButtonSegment<DonationTab>(
                        value: tab,
                        label: Text(_tabLabel(tab, compact: isCompact)),
                      ),
                    )
                    .toList(),
                selected: <DonationTab>{_selectedTab},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedTab = selection.first;
                  });
                },
              ),
            ),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
    );
  }

  String _tabLabel(DonationTab tab, {bool compact = false}) {
    switch (tab) {
      case DonationTab.donate:
        return 'Donate';
      case DonationTab.history:
        return compact ? 'History' : 'Member History';
      case DonationTab.leaderboard:
        return 'Leaderboard';
      case DonationTab.paymentSettings:
        return 'UPI / QR Settings';
    }
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case DonationTab.donate:
        return _buildDonateTab();
      case DonationTab.history:
        return _buildMemberHistoryTab();
      case DonationTab.leaderboard:
        return _isAdmin
            ? _buildLeaderboardTab()
            : const SizedBox.shrink();
      case DonationTab.paymentSettings:
        return _isAdmin
            ? _buildPaymentSettingsTab()
            : const SizedBox.shrink();
    }
  }

  Widget _buildDonateTab() {
    final customQrUrl = widget.donationService.customQrImageUrl;
    final hasCustomQr = customQrUrl != null && customQrUrl.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${AppBrand.appName} Support Fund',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Donate via UPI or scan QR, then upload payment screenshot for admin verification.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableText(
                        _activeUpiId,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: _copyUpiId,
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: 'Copy UPI ID',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _activeUpiName,
                  style: const TextStyle(color: Color(0xFF5A6B74)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD0DBE2)),
                    ),
                    child: hasCustomQr
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              customQrUrl,
                              width: 210,
                              height: 210,
                              fit: BoxFit.cover,
                              headers: supabaseImageHeaders(),
                              errorBuilder: (_, __, ___) => QrImageView(
                                data: _upiUri,
                                size: 210,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          )
                        : QrImageView(
                            data: _upiUri,
                            size: 210,
                            backgroundColor: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasCustomQr
                      ? 'Using admin-uploaded QR image.'
                      : 'Using auto-generated QR from UPI ID.',
                  style: const TextStyle(color: Color(0xFF5A6B74)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openUpiApp,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Pay with UPI App'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Donation amount (INR)',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _transactionRefController,
          decoration: const InputDecoration(
            labelText: 'Transaction reference (optional)',
            prefixIcon: Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Example: Donation for emergency support drive',
            prefixIcon: Icon(Icons.edit_note_outlined),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickProofScreenshot,
          icon: const Icon(Icons.image_outlined),
          label: Text(_proofScreenshot == null
              ? 'Attach payment screenshot'
              : 'Change screenshot proof'),
        ),
        if (_proofScreenshot != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Proof attached: ${_proofScreenshot!.name}',
              style: const TextStyle(color: Color(0xFF2B6E78)),
            ),
          ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _openAdminChat,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Open admin WhatsApp chat'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _submittingDonation ? null : _submitDonation,
          icon: const Icon(Icons.verified_outlined),
          label: Text(
            _submittingDonation
                ? (_submitPhase.isEmpty ? 'Submitting...' : _submitPhase)
                : 'Submit donation entry',
          ),
        ),
      ],
    );
  }

  Widget _buildMemberHistoryTab() {
    final donations = _historyDonations();
    if (donations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _isAdmin
                ? 'No donation entries available yet.'
                : 'No donation entries yet. Your pending submissions will appear here.',
          ),
        ),
      );
    }

    final members = <String, String>{};
    for (final donation in donations) {
      members[donation.memberMobile] = donation.memberName;
    }

    final search = _memberSearchController.text.trim().toLowerCase();
    final filtered = donations.where((entry) {
      final memberMatch = !_isAdmin ||
          _selectedMemberMobile == null ||
          entry.memberMobile == _selectedMemberMobile;
      final queryMatch = search.isEmpty ||
          entry.memberName.toLowerCase().contains(search) ||
          entry.memberMobile.contains(search);
      return memberMatch && queryMatch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Donation history',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (_isAdmin)
          DropdownButtonFormField<String?>(
            initialValue: _selectedMemberMobile,
            decoration: const InputDecoration(
              labelText: 'Select member',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All members'),
              ),
              ...members.entries.map(
                (entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text('${entry.value} • ${entry.key}'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMemberMobile = value;
              });
            },
          ),
        if (_isAdmin) const SizedBox(height: 10),
        TextField(
          controller: _memberSearchController,
          decoration: const InputDecoration(
            labelText: 'Search by name or mobile',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No donations found for the selected filter.'),
            ),
          ),
        ...filtered.map(_buildDonationCard),
      ],
    );
  }

  List<DonationEntry> _historyDonations() {
    final donations = widget.donationService.donations;
    if (_isAdmin) {
      return donations;
    }
    return donations.where((entry) => entry.memberId == widget.currentUser.id).toList();
  }

  Widget _buildLeaderboardTab() {
    final verifiedDonations = widget.donationService.donations
        .where((entry) => entry.isVerified)
        .toList();
    if (verifiedDonations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No verified donations available for leaderboard yet.'),
        ),
      );
    }

    final Map<String, _MemberDonationStats> stats = <String, _MemberDonationStats>{};
    for (final entry in verifiedDonations) {
      final key = entry.memberMobile;
      final existing = stats[key];
      if (existing == null) {
        stats[key] = _MemberDonationStats(
          memberName: entry.memberName,
          memberMobile: entry.memberMobile,
          totalAmount: entry.amount,
          donationCount: 1,
        );
      } else {
        stats[key] = existing.copyWith(
          totalAmount: existing.totalAmount + entry.amount,
          donationCount: existing.donationCount + 1,
        );
      }
    }

    final leaderboard = stats.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final totalAmount =
        leaderboard.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildSummaryCard(
          title: 'Verified Donation Entries',
          value: '${verifiedDonations.length}',
        ),
        const SizedBox(height: 10),
        _buildSummaryCard(
          title: 'Total Amount',
          value: 'Rs ${totalAmount.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 14),
        const Text(
          'Admin Leaderboard (Verified Only)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...leaderboard.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    rank == 1 ? const Color(0xFFE0B36A) : const Color(0xFF123C56),
                foregroundColor: Colors.white,
                child: Text('$rank'),
              ),
              title: Text(item.memberName),
              subtitle: Text('${item.memberMobile} • ${item.donationCount} entries'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Rs ${item.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => _deleteLeaderboardMember(item),
                    tooltip: 'Delete member donation entries',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentSettingsTab() {
    return ListView(
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
                  'Update UPI details. QR code in donation page refreshes automatically from these values.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _upiIdController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _upiNameController,
                  decoration: const InputDecoration(
                    labelText: 'Beneficiary Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
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
                  onPressed: _savingPaymentSettings ? null : _savePaymentSettings,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_savingPaymentSettings ? 'Saving...' : 'Save UPI Settings'),
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
                          child: Center(child: Text('Current QR preview unavailable.')),
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
    );
  }

  Widget _buildSummaryCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF4F7F9),
        border: Border.all(color: const Color(0xFFD5DEE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: Color(0xFF5A6B74))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DonationEntry entry) {
    final stamp = formatIstDateTime(entry.createdAt);
    final statusVisual = _statusVisual(entry.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  backgroundColor: Color(0xFF123C56),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.volunteer_activism_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${entry.memberName} donated Rs ${entry.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusVisual.background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusVisual.label,
                    style: TextStyle(
                      color: statusVisual.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Submitted: $stamp'),
            Text('Ref: ${entry.transactionRef?.isNotEmpty == true ? entry.transactionRef : 'N/A'}'),
            if (entry.rejectionReason?.trim().isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Rejection reason: ${entry.rejectionReason!.trim()}',
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _DonationStatusVisual _statusVisual(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized == 'verified') {
      return const _DonationStatusVisual(
        label: 'Verified',
        background: Color(0xFFDFF7E5),
        foreground: Color(0xFF1F7A3A),
      );
    }
    if (normalized == 'rejected') {
      return const _DonationStatusVisual(
        label: 'Rejected',
        background: Color(0xFFFDE7E9),
        foreground: Color(0xFFB3261E),
      );
    }
    return const _DonationStatusVisual(
      label: 'Unverified',
      background: Color(0xFFFFF4D6),
      foreground: Color(0xFF8A5A00),
    );
  }

  Future<void> _deleteLeaderboardMember(_MemberDonationStats item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete donation entries?'),
          content: Text(
            'Delete all ${item.donationCount} donation entries for ${item.memberName} from Supabase?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deletedCount = await widget.donationService.deleteDonationsByMemberMobile(
      actor: widget.currentUser,
      memberMobile: item.memberMobile,
    );

    if (!mounted) {
      return;
    }

    if (deletedCount == 0) {
      final writeError = widget.donationService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to delete donation entries. Please try again.'
          : 'Unable to delete donation entries: $writeError';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $deletedCount donation entries.')),
    );
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: _activeUpiId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UPI ID copied.')),
    );
  }

  Future<void> _openUpiApp() async {
    try {
      if (!_upiPattern.hasMatch(_activeUpiId.trim())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI ID is invalid. Please check payment settings.')),
          );
        }
        return;
      }

      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UPI apps open only on mobile device. Please use Android/iPhone app.'),
            ),
          );
        }
        return;
      }

      final uri = Uri.parse(_upiUri);

      // canLaunchUrl can be false on some devices even when launch works.
      var opened = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!opened) {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened && defaultTargetPlatform == TargetPlatform.android) {
        final intentUri = Uri.parse(
          'intent://pay?${uri.query}#Intent;scheme=upi;end',
        );
        opened = await launchUrl(
          intentUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No UPI app found on this device. Install any UPI app and retry.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open UPI app. Please retry.')),
      );
    }
  }

  Future<void> _pickProofScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) {
      return;
    }
    setState(() {
      _proofScreenshot = picked;
    });
  }

  Future<void> _openAdminChat() async {
    try {
      final message = Uri.encodeComponent(
        'Hello Admin, I have made a donation and uploaded payment proof for verification.',
      );
      final uri = Uri.parse('https://wa.me/91$_activeAdminMobile?text=$message');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open admin chat. Please retry.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open admin chat. Please retry.')),
      );
    }
  }

  Future<void> _submitDonation() async {
    if (_submittingDonation) {
      return;
    }
    setState(() {
      _submittingDonation = true;
      _submitPhase = 'Validating...';
    });

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || amount > 1000000) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDonation = false;
        _submitPhase = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid donation amount (1 to 1000000).')),
      );
      return;
    }

    final transactionRef = _transactionRefController.text.trim();
    if (transactionRef.isNotEmpty && !_safeRefPattern.hasMatch(transactionRef)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDonation = false;
        _submitPhase = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction reference must be 4-40 letters/numbers.')),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.length > 300) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDonation = false;
        _submitPhase = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note can be up to 300 characters only.')),
      );
      return;
    }

    String? screenshotUrl;
    if (_proofScreenshot != null) {
      setState(() {
        _submitPhase = 'Uploading screenshot...';
      });
      screenshotUrl = await widget.donationService.uploadProofScreenshot(_proofScreenshot!);
      if (screenshotUrl == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _submittingDonation = false;
          _submitPhase = '';
        });
        final uploadError = widget.donationService.lastUploadError;
        final message = (uploadError == null || uploadError.isEmpty)
            ? 'Unable to upload screenshot to cloud. Please retry.'
            : 'Unable to upload screenshot to cloud: $uploadError';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
    }

    setState(() {
      _submitPhase = 'Saving donation...';
    });
    final created = await widget.donationService.createDonation(
      member: widget.currentUser,
      amount: amount,
      upiId: _activeUpiId,
      note: note.isEmpty ? null : note,
      transactionRef: transactionRef.isEmpty ? null : transactionRef,
      screenshotPath: screenshotUrl,
    );

    if (!created) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDonation = false;
        _submitPhase = '';
      });
      final writeError = widget.donationService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to save donation in cloud. Please retry.'
          : 'Unable to save donation in cloud: $writeError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    try {
      await _autoShareProofToAdmin(screenshotUrl);
    } catch (_) {
      // Donation is already saved; sharing is best effort only.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _amountController.clear();
      _noteController.clear();
      _transactionRefController.clear();
      _proofScreenshot = null;
      _selectedTab = DonationTab.history;
      _submittingDonation = false;
      _submitPhase = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Donation submitted successfully. Awaiting admin verification.'),
      ),
    );
  }

  Future<void> _autoShareProofToAdmin(String? screenshotUrl) async {
    try {
      final proofLine = (screenshotUrl == null || screenshotUrl.isEmpty)
          ? 'Proof URL: not attached'
          : 'Proof URL: $screenshotUrl';
      final message = Uri.encodeComponent(
        'Donation submitted for verification.\n'
        'Member: ${widget.currentUser.name}\n'
        'Mobile: ${widget.currentUser.mobileNumber}\n'
        'Amount: ${_amountController.text.trim()}\n'
        '$proofLine',
      );
      final uri = Uri.parse('https://wa.me/91$_activeAdminMobile?text=$message');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share proof to admin automatically.')),
      );
    }
  }

  Future<void> _savePaymentSettings() async {
    final upi = _upiIdController.text.trim();
    final name = _upiNameController.text.trim();
    final mobile = _adminMobileController.text.trim();

    if (upi.isEmpty || name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID, beneficiary name, and admin mobile are required.')),
      );
      return;
    }

    if (!_upiPattern.hasMatch(upi)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid UPI ID (example@bank).')),
      );
      return;
    }

    if (name.length < 2 || name.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary name must be 2-60 characters.')),
      );
      return;
    }

    if (!_mobilePattern.hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin mobile must be a valid 10 digit number.')),
      );
      return;
    }

    setState(() {
      _savingPaymentSettings = true;
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
      _savingPaymentSettings = false;
    });

    if (!saved) {
      final writeError = widget.donationService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to save payment settings in cloud. Please retry.'
          : 'Unable to save payment settings in cloud: $writeError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment settings updated successfully.')),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    setState(() {
      _customQrImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Custom QR uploaded successfully.')),
    );
  }

  Future<void> _removeCustomQr() async {
    final saved = await widget.donationService.updatePaymentSettings(
      actor: widget.currentUser,
      upiId: _activeUpiId,
      upiName: _activeUpiName,
      adminMobile: _activeAdminMobile,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    setState(() {
      _customQrImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploaded custom QR removed.')),
    );
  }
}

class _MemberDonationStats {
  const _MemberDonationStats({
    required this.memberName,
    required this.memberMobile,
    required this.totalAmount,
    required this.donationCount,
  });

  final String memberName;
  final String memberMobile;
  final double totalAmount;
  final int donationCount;

  _MemberDonationStats copyWith({
    String? memberName,
    String? memberMobile,
    double? totalAmount,
    int? donationCount,
  }) {
    return _MemberDonationStats(
      memberName: memberName ?? this.memberName,
      memberMobile: memberMobile ?? this.memberMobile,
      totalAmount: totalAmount ?? this.totalAmount,
      donationCount: donationCount ?? this.donationCount,
    );
  }
}

class _DonationStatusVisual {
  const _DonationStatusVisual({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
