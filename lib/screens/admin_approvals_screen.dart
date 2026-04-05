import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../core/time_utils.dart';
import '../models/member.dart';
import '../services/member_repository.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({
    required this.currentUser,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  bool _refreshing = false;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const BrandedScreenTitle('New Member Approvals')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can view and approve new members.'),
          ),
        ),
      );
    }

    final pending = widget.repository.pendingApprovals;
    final pendingUpdates = widget.repository.pendingUpdateApprovals;
    final retired = widget.repository.retiredMembers;
    final blocked = widget.repository.activeMembers
      .where((member) => member.isBlocked)
      .toList();
    final deletedLast30 = widget.repository.deletedMembers
        .where((member) {
          final deletedAt = member.deletedAt;
          if (deletedAt == null) {
            return false;
          }
          return DateTime.now().difference(deletedAt).inDays <= 30;
        })
        .toList();
    final inactive = widget.repository.inactiveOver30Days;

    final tabs = <String>[
      'New Approvals',
      'Update Approvals',
      'Blocked Members',
      'Retired Members',
      'Deleted (30 days)',
      'Inactive (30+ days)',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('New Member Approvals'),
        actions: <Widget>[
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(
              tabs.length,
              (index) => ChoiceChip(
                label: Text(tabs[index]),
                selected: _tabIndex == index,
                onSelected: (_) {
                  setState(() {
                    _tabIndex = index;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_tabIndex == 0 && pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending approvals right now.'),
              ),
            ),
          if (_tabIndex == 0) ...pending.map(_buildPendingCard),
          if (_tabIndex == 1 && pendingUpdates.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending update requests.'),
              ),
            ),
          if (_tabIndex == 1) ...pendingUpdates.map(_buildUpdateApprovalCard),
          if (_tabIndex == 2 && blocked.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No blocked members.'),
              ),
            ),
          if (_tabIndex == 2) ...blocked.map(_buildLifecycleCard),
          if (_tabIndex == 3 && retired.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No retired members.'),
              ),
            ),
          if (_tabIndex == 3) ...retired.map(_buildLifecycleCard),
          if (_tabIndex == 4 && deletedLast30.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No deleted members in last 30 days.'),
              ),
            ),
          if (_tabIndex == 4) ...deletedLast30.map(_buildLifecycleCard),
          if (_tabIndex == 5 && inactive.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No inactive members for 30+ days.'),
              ),
            ),
          if (_tabIndex == 5) ...inactive.map(_buildLifecycleCard),
        ],
      ),
    );
  }

  Widget _buildUpdateApprovalCard(Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openApprovalReview(member, isUpdateApproval: true),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 22,
                child: Icon(Icons.manage_accounts_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text('Mobile: ${member.mobileNumber}'),
                    Text('Posting: ${member.postingLocation}, ${member.postingDistrict}'),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to review requested fields and approve/reject update',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLifecycleCard(Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              member.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Mobile: ${member.mobileNumber}'),
            Text('Posting: ${member.postingLocation}, ${member.postingDistrict}'),
            Text('Last login: ${_formatLastLogin(member.lastLoginAt)}'),
            Text('Retired: ${member.isRetired ? 'Yes' : 'No'}'),
            Text('Deleted: ${member.isDeleted ? 'Yes' : 'No'}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => _setRetired(member, !member.isRetired),
                  child: Text(member.isRetired ? 'Mark Active' : 'Mark Retired'),
                ),
                OutlinedButton(
                  onPressed: () => _setDeleted(member, !member.isDeleted),
                  child: Text(member.isDeleted ? 'Restore' : 'Delete'),
                ),
                OutlinedButton(
                  onPressed: () => _setBlocked(member, !member.isBlocked),
                  child: Text(member.isBlocked ? 'Unblock' : 'Block'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(Member member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openApprovalReview(member, isUpdateApproval: false),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                radius: 22,
                child: Icon(Icons.person_add_alt_1_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text('Mobile: ${member.mobileNumber}'),
                    Text('Home: ${member.homeDistrict}'),
                    Text('Posting: ${member.postingLocation}, ${member.postingDistrict}'),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to review full profile, documents, contact, and approve',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openApprovalReview(
    Member member, {
    required bool isUpdateApproval,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _ApprovalReviewScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
          member: member,
          isUpdateApproval: isUpdateApproval,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(() {});
    }
  }


  Future<void> _setRetired(Member member, bool retired) async {
    final success = await widget.repository.setMemberRetired(
      actor: widget.currentUser,
      memberId: member.id,
      retired: retired,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update retired status.')),
      );
      return;
    }
    setState(() {});
  }

  Future<void> _setDeleted(Member member, bool deleted) async {
    final success = await widget.repository.setMemberDeleted(
      actor: widget.currentUser,
      memberId: member.id,
      deleted: deleted,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update deleted status.')),
      );
      return;
    }
    setState(() {});
  }

  Future<void> _setBlocked(Member member, bool blocked) async {
    final success = await widget.repository.setMemberBlocked(
      actor: widget.currentUser,
      memberId: member.id,
      blocked: blocked,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update blocked status.')),
      );
      return;
    }
    setState(() {});
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
    });

    await widget.repository.refreshFromCloud();

    if (!mounted) {
      return;
    }

    setState(() {
      _refreshing = false;
    });
  }

  String _formatLastLogin(DateTime? value) {
    if (value == null) {
      return 'Never';
    }
    return formatIstDateTime(value);
  }
}

class _ApprovalReviewScreen extends StatefulWidget {
  const _ApprovalReviewScreen({
    required this.currentUser,
    required this.repository,
    required this.member,
    required this.isUpdateApproval,
  });

  final Member currentUser;
  final MemberRepository repository;
  final Member member;
  final bool isUpdateApproval;

  @override
  State<_ApprovalReviewScreen> createState() => _ApprovalReviewScreenState();
}

class _ApprovalReviewScreenState extends State<_ApprovalReviewScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final title = widget.isUpdateApproval
        ? 'Update Approval Review'
        : 'New Member Approval Review';
    final requestedFields = _requestedFieldRows(
      member: member,
      pendingPayloadRaw: member.pendingUpdatePayload,
      previousSnapshotRaw: member.previousPublicProfileSnapshot,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + safeBottom + 12),
            children: <Widget>[
              _header(member),
              if (widget.isUpdateApproval && requestedFields.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _section(
                  title: 'Requested Changes',
                  children: requestedFields,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.isUpdateApproval && requestedFields.isEmpty) ...<Widget>[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No changed fields found in this update request.'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!widget.isUpdateApproval) ...<Widget>[
                const SizedBox(height: 10),
                _contactActions(member),
                const SizedBox(height: 12),
                _section(
                  title: 'All Profile Details',
                  children: <Widget>[
                    _row('Full Name', member.name),
                    _row('Official Name', member.officialName),
                    _row('Mobile Number', member.mobileNumber),
                    _row('Whatsapp Number', member.whatsappNumber),
                    _row('Calling Contact Number', member.callingContactNumber),
                    _row('Reference Mobile Number', member.referenceMobileNumber),
                    _row('Reference Member Name', member.referenceMemberName),
                    _row('Sub Department', member.department),
                    _row('Rank', member.postRank),
                    _row('Batch Year', member.batchYear),
                    _row('Gender', member.gender),
                    _row('Marital Status', member.maritalStatus),
                    _row('Home State', member.homeState),
                    _row('Home District', member.homeDistrict),
                    _row('Home Village / Mohalla', member.homeVillageMohalla),
                    _row('Home Gali No', member.homeGaliNo),
                    _row('Home Post Office', member.homePostOffice),
                    _row('Home Police Station', member.homePoliceStation),
                    _row('Home Tehsil', member.homeTehsil),
                    _row('Home Village Location', member.homeVillageLocation),
                    _row('Posting State', member.postingState),
                    _row('Posting District', member.postingDistrict),
                    _row('Posting Location', member.postingLocation),
                    _row('Posting Category', member.postingCategory),
                    _row('Posting Work As', member.postingWorkAs),
                    _postingPlaceLocationRow(member.postingPlaceLocation),
                    _row('Emergency Contact', member.emergencyContact),
                    _row('Role', member.role),
                    _row('Approved', member.isApproved ? 'Yes' : 'No'),
                    _row('Blocked', member.isBlocked ? 'Yes' : 'No'),
                    _row('Retired', member.isRetired ? 'Yes' : 'No'),
                    _row('Deleted', member.isDeleted ? 'Yes' : 'No'),
                    _row('Appointment Date', formatIstDateTime(member.appointmentDate)),
                    _row('Last Login', member.lastLoginAt == null ? 'Never' : formatIstDateTime(member.lastLoginAt!)),
                    _row('Last Updated', formatIstDateTime(member.lastUpdated)),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  title: 'Uploaded Documents',
                  children: <Widget>[
                    _buildDocumentPreview(label: 'Selfie Photo', path: member.selfiePath),
                    const SizedBox(height: 8),
                    _buildDocumentPreview(label: 'ID Card Photo', path: member.idCardPhotoPath),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (widget.isUpdateApproval)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: _working ? null : () => _resolveUpdate(true),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve Update'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _working ? null : () => _resolveUpdate(false),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject Update'),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _working ? null : _approveMember,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve Member'),
                ),
            ],
          ),
          if (_working)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _header(Member member) {
    final selfieUrl = member.selfiePath?.trim() ?? '';
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            if (selfieUrl.isEmpty)
              CircleAvatar(radius: 28, child: Text(initial))
            else
              ClipOval(
                child: Image.network(
                  selfieUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(radius: 28, child: Text(initial)),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(member.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${member.postingLocation}, ${member.postingDistrict}'),
                  Text('Mobile: ${member.mobileNumber}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactActions(Member member) {
    final whatsapp = (member.whatsappNumber ?? '').trim().isEmpty
        ? member.mobileNumber
        : member.whatsappNumber!.trim();
    final referenceMobile = member.referenceMobileNumber.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () => _openPhone(member.mobileNumber),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openWhatsApp(whatsapp),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
            FilledButton.tonalIcon(
              onPressed: referenceMobile.isEmpty
                  ? null
                  : () => _openPhone(referenceMobile),
              icon: const Icon(Icons.perm_contact_calendar_outlined),
              label: const Text('Call Reference'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    final text = (value ?? '').trim().isEmpty ? '-' : value!.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: Color(0xFF5A6B74))),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _postingPlaceLocationRow(String? rawValue) {
    final raw = (rawValue ?? '').trim();
    final uri = _postingLocationUri(raw);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            width: 160,
            child: Text(
              'Posting Place Location Link',
              style: TextStyle(color: Color(0xFF5A6B74)),
            ),
          ),
          Expanded(
            child: raw.isEmpty
                ? const Text(
                    'Not uploaded. Mark for later and inform admin.',
                    style: TextStyle(
                      color: Color(0xFFB3261E),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(raw),
                      const SizedBox(height: 6),
                      if (uri != null)
                        OutlinedButton.icon(
                          onPressed: () => _openUri(uri),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open Posting Map'),
                        )
                      else
                        const Text(
                          'Map link format not recognized. Please verify this value.',
                          style: TextStyle(color: Color(0xFFB3261E)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview({
    required String label,
    required String? path,
  }) {
    if (path == null || path.trim().isEmpty) {
      return _documentCard(
        label: label,
        child: const Center(child: Text('Not uploaded')),
      );
    }

    final uri = Uri.tryParse(path);
    final hasScheme = uri != null && uri.hasScheme;

    if (hasScheme) {
      return _documentCard(
        label: label,
        child: InkWell(
          onTap: () => _openImagePreview(path, label),
          child: Image.network(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(child: Text('Preview unavailable')),
          ),
        ),
      );
    }

    return _documentCard(
      label: label,
      child: FutureBuilder<Uint8List>(
        future: XFile(path).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Preview unavailable'));
          }
          return Image.memory(snapshot.data!, fit: BoxFit.contain);
        },
      ),
    );
  }

  Widget _documentCard({
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD5DEE3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(height: 220, width: double.infinity, child: child),
          ),
        ],
      ),
    );
  }

  Future<void> _openImagePreview(String path, String label) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(label)),
          backgroundColor: Colors.black,
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                path,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Preview unavailable',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPhone(String mobile) async {
    try {
      final uri = Uri.parse('tel:$mobile');
      final opened = await launchUrl(uri);
      if (!opened && mounted) {
        _showMessage('Unable to open phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open phone dialer.');
      }
    }
  }

  Future<void> _openWhatsApp(String mobile) async {
    try {
      final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      final normalized = digits.length > 10 ? digits : '91$digits';
      final uri = Uri.parse('https://wa.me/$normalized');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Unable to open WhatsApp.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open WhatsApp.');
      }
    }
  }

  Future<void> _approveMember() async {
    setState(() {
      _working = true;
    });
    final success = await widget.repository.setMemberApproved(
      actor: widget.currentUser,
      memberId: widget.member.id,
      approved: true,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to approve member.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.member.name} approved successfully.')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _resolveUpdate(bool approve) async {
    setState(() {
      _working = true;
    });
    final success = await widget.repository.resolvePendingUpdate(
      actor: widget.currentUser,
      memberId: widget.member.id,
      approve: approve,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _working = false;
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process update request.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Update approved.' : 'Update rejected.')),
    );
    Navigator.of(context).pop(true);
  }

  List<Widget> _requestedFieldRows({
    required Member member,
    required String? pendingPayloadRaw,
    required String? previousSnapshotRaw,
  }) {
    final pendingRaw = pendingPayloadRaw?.trim() ?? '';
    if (pendingRaw.isEmpty) {
      return const <Widget>[];
    }

    try {
      final payload = jsonDecode(pendingRaw) as Map<String, dynamic>;
      Map<String, dynamic> previousSnapshot = <String, dynamic>{};
      final previousRaw = previousSnapshotRaw?.trim() ?? '';
      if (previousRaw.isNotEmpty) {
        try {
          previousSnapshot = jsonDecode(previousRaw) as Map<String, dynamic>;
        } catch (_) {
          previousSnapshot = <String, dynamic>{};
        }
      }

      const ignoredKeys = <String>{
        'biometricEnabled',
        'trustedDeviceId',
        'trustedDeviceFingerprint',
        'trustedDeviceBoundAt',
      };

      final rows = <Widget>[];
      final requestedPostingPlaceRaw =
          (payload['postingPlaceLocation'] ?? '').toString().trim();

      payload.forEach((key, value) {
        if (ignoredKeys.contains(key)) {
          return;
        }

        final nextValue = (value ?? '').toString().trim();
        if (nextValue.isEmpty) {
          return;
        }

        final previousValue = _resolvePreviousValue(
          key: key,
          previousSnapshot: previousSnapshot,
          member: member,
        );

        final isChanged = nextValue.toLowerCase() != previousValue.toLowerCase();
        if (!isChanged) {
          return;
        }

        if (key == 'selfiePath') {
          rows.add(
            _requestedPhotoChangeCard(
              previousPath: previousValue,
              requestedPath: nextValue,
            ),
          );
          return;
        }

        if (key == 'postingPlaceLocation') {
          rows.add(
            _requestedLocationChangeCard(
              previousValue: previousValue,
              requestedValue: nextValue,
            ),
          );
          return;
        }

        final mapUri = key == 'postingLocation'
            ? _postingLocationUri(
                requestedPostingPlaceRaw.isNotEmpty
                    ? requestedPostingPlaceRaw
                    : member.postingPlaceLocation,
              )
            : null;

        rows.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_fieldLabel(key), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Previous: ${previousValue.isEmpty ? '-' : previousValue}'),
                const SizedBox(height: 2),
                Text('Requested: $nextValue'),
                if (mapUri != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _openUri(mapUri),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Check Updated Posting Map'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      });
      return rows;
    } catch (_) {
      return <Widget>[Text(pendingRaw)];
    }
  }

  String _fieldLabel(String key) {
    const labels = <String, String>{
      'name': 'Full Name',
      'postingLocation': 'Posting Location',
      'homeState': 'Home State',
      'homeDistrict': 'Home District',
      'postingState': 'Posting State',
      'postingDistrict': 'Posting District',
      'department': 'Sub Department',
      'postRank': 'Rank',
      'officialName': 'Official Name',
      'batchYear': 'Batch Year',
      'gender': 'Gender',
      'maritalStatus': 'Marital Status',
      'postingCategory': 'Posting Category',
      'postingWorkAs': 'Posting Work As',
      'whatsappNumber': 'Whatsapp Number',
      'callingContactNumber': 'Calling Contact Number',
      'postingPlaceLocation': 'Posting Place Location',
      'homeVillageMohalla': 'Home Village / Mohalla',
      'homeGaliNo': 'Home Gali No',
      'homePostOffice': 'Home Post Office',
      'homePoliceStation': 'Home Police Station',
      'homeTehsil': 'Home Tehsil',
      'selfiePath': 'Profile Photo',
    };
    return labels[key] ?? key;
  }

  String _resolvePreviousValue({
    required String key,
    required Map<String, dynamic> previousSnapshot,
    required Member member,
  }) {
    if (previousSnapshot.containsKey(key)) {
      return (previousSnapshot[key] ?? '').toString().trim();
    }

    switch (key) {
      case 'name':
        return member.name;
      case 'postingLocation':
        return member.postingLocation;
      case 'homeState':
        return member.homeState ?? '';
      case 'homeDistrict':
        return member.homeDistrict;
      case 'postingState':
        return member.postingState ?? '';
      case 'postingDistrict':
        return member.postingDistrict;
      case 'department':
        return member.department ?? '';
      case 'postRank':
        return member.postRank ?? '';
      case 'officialName':
        return member.officialName ?? '';
      case 'batchYear':
        return member.batchYear ?? '';
      case 'gender':
        return member.gender ?? '';
      case 'maritalStatus':
        return member.maritalStatus ?? '';
      case 'postingCategory':
        return member.postingCategory ?? '';
      case 'postingWorkAs':
        return member.postingWorkAs ?? '';
      case 'whatsappNumber':
        return member.whatsappNumber ?? '';
      case 'callingContactNumber':
        return member.callingContactNumber ?? '';
      case 'postingPlaceLocation':
        return member.postingPlaceLocation ?? '';
      case 'homeVillageMohalla':
        return member.homeVillageMohalla ?? '';
      case 'homeGaliNo':
        return member.homeGaliNo ?? '';
      case 'homePostOffice':
        return member.homePostOffice ?? '';
      case 'homePoliceStation':
        return member.homePoliceStation ?? '';
      case 'homeTehsil':
        return member.homeTehsil ?? '';
      case 'selfiePath':
        return member.selfiePath ?? '';
      case 'emergencyContact':
        return member.emergencyContact ?? '';
      default:
        return '';
    }
  }

  Widget _requestedPhotoChangeCard({
    required String previousPath,
    required String requestedPath,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(child: _compactPhotoPreview(previousPath, 'Previous')),
              const SizedBox(width: 10),
              Expanded(child: _compactPhotoPreview(requestedPath, 'Requested')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactPhotoPreview(String path, String label) {
    final normalized = path.trim();
    final uri = Uri.tryParse(normalized);
    final hasScheme = uri != null && uri.hasScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD5DEE3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: normalized.isEmpty
                ? const Center(child: Text('Not set'))
                : hasScheme
                    ? Image.network(
                        normalized,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Text('Preview unavailable')),
                      )
                    : FutureBuilder<Uint8List>(
                        future: XFile(normalized).readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('Preview unavailable'));
                          }
                          return Image.memory(snapshot.data!, fit: BoxFit.cover);
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _requestedLocationChangeCard({
    required String previousValue,
    required String requestedValue,
  }) {
    final previousUri = _postingLocationUri(previousValue);
    final requestedUri = _postingLocationUri(requestedValue);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Posting Place Location', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: previousUri == null ? null : () => _openUri(previousUri),
                icon: const Icon(Icons.location_history_outlined),
                label: const Text('Previous Map'),
              ),
              FilledButton.tonalIcon(
                onPressed: requestedUri == null ? null : () => _openUri(requestedUri),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Requested Map'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uri? _postingLocationUri(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(text);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final direct = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(text);
    if (direct != null) {
      final lat = direct.group(1)!;
      final lng = direct.group(2)!;
      return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    }

    final encoded = Uri.encodeComponent(text);
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  }

  Future<void> _openUri(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Unable to open link.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open link.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
