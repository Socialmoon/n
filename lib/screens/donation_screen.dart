import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donation_entry.dart';
import '../models/member.dart';
import '../services/donation_service.dart';

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
  static const String _upiId = 'policenetworksupport@oksbi';
  static const String _adminMobile = '9193410557';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _transactionRefController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();

  XFile? _proofScreenshot;
  int _tabIndex = 0;
  String? _selectedMemberMobile;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _transactionRefController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  String get _upiUri {
    final amount = _amountController.text.trim();
    final amountPart = amount.isEmpty ? '' : '&am=$amount';
    return 'upi://pay?pa=$_upiId&pn=Police%20Network%20Support$amountPart&cu=INR';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Donations'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text('Donate')),
                ButtonSegment<int>(value: 1, label: Text('Member History')),
                ButtonSegment<int>(value: 2, label: Text('Leaderboard')),
              ],
              selected: <int>{_tabIndex},
              onSelectionChanged: (selection) {
                setState(() {
                  _tabIndex = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildDonateTab()
                : _tabIndex == 1
                    ? _buildMemberHistoryTab()
                    : _buildLeaderboardTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateTab() {
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
                  'Police Network Support Fund',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Donate via UPI or scan QR, then share payment screenshot with admin for verification.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableText(
                        _upiId,
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
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD0DBE2)),
                    ),
                    child: QrImageView(
                      data: _upiUri,
                      size: 210,
                      backgroundColor: Colors.white,
                    ),
                  ),
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
            hintText: 'Example: Donation for emergency medical support drive',
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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _shareProofToAdmin,
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Share screenshot to admin'),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _openAdminChat,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Open admin WhatsApp chat'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _submitDonation,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Submit donation entry'),
        ),
      ],
    );
  }

  Widget _buildMemberHistoryTab() {
    final donations = widget.donationService.donations;
    if (donations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No donations submitted yet.'),
        ),
      );
    }

    final members = <String, String>{};
    for (final donation in donations) {
      members[donation.memberMobile] = donation.memberName;
    }

    final search = _memberSearchController.text.trim().toLowerCase();
    final filtered = donations.where((entry) {
      final memberMatch = _selectedMemberMobile == null ||
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
          'Donation history by member',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          value: _selectedMemberMobile,
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
        const SizedBox(height: 10),
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
              child: Text('No donations found for the selected person/filter.'),
            ),
          ),
        ...filtered.map(_buildDonationCard),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    final donations = widget.donationService.donations;
    if (donations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No donations available for leaderboard yet.'),
        ),
      );
    }

    final Map<String, _MemberDonationStats> stats = <String, _MemberDonationStats>{};
    for (final entry in donations) {
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

    final totalAmount = leaderboard.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final totalDonations = donations.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Donations',
                value: '$totalDonations',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Amount',
                value: 'Rs ${totalAmount.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Donations Leaderboard',
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
                backgroundColor: rank == 1
                    ? const Color(0xFFE0B36A)
                    : const Color(0xFF123C56),
                foregroundColor: Colors.white,
                child: Text('$rank'),
              ),
              title: Text(item.memberName),
              subtitle: Text(
                '${item.memberMobile} • ${item.donationCount} donations',
              ),
              trailing: Text(
                'Rs ${item.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }),
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
          Text(
            title,
            style: const TextStyle(color: Color(0xFF5A6B74)),
          ),
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
    final stamp =
        '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF123C56),
          foregroundColor: Colors.white,
          child: Icon(Icons.volunteer_activism_outlined),
        ),
        title: Text('${entry.memberName} donated Rs ${entry.amount.toStringAsFixed(0)}'),
        subtitle: Text(
          '${entry.status} • $stamp\nRef: ${entry.transactionRef?.isNotEmpty == true ? entry.transactionRef : 'N/A'}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(const ClipboardData(text: _upiId));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UPI ID copied.')),
    );
  }

  Future<void> _openUpiApp() async {
    final uri = Uri.parse(_upiUri);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Future<void> _shareProofToAdmin() async {
    if (_proofScreenshot == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach screenshot proof first.')),
      );
      return;
    }

    await Share.shareXFiles(
      <XFile>[_proofScreenshot!],
      text:
          'Donation proof for verification\nMember: ${widget.currentUser.name}\nMobile: ${widget.currentUser.mobileNumber}\nAdmin: +91$_adminMobile',
      subject: 'Donation proof',
    );
  }

  Future<void> _openAdminChat() async {
    final message = Uri.encodeComponent(
      'Hello Admin, I have made a donation and will share payment screenshot for verification.',
    );
    final uri = Uri.parse('https://wa.me/91$_adminMobile?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitDonation() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid donation amount.')),
      );
      return;
    }

    await widget.donationService.createDonation(
      member: widget.currentUser,
      amount: amount,
      upiId: _upiId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      transactionRef: _transactionRefController.text.trim().isEmpty
          ? null
          : _transactionRefController.text.trim(),
      screenshotPath: _proofScreenshot?.path,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _amountController.clear();
      _noteController.clear();
      _transactionRefController.clear();
      _proofScreenshot = null;
      _tabIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation submitted and marked pending verification.')),
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
