import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

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
    final requestedFields = _requestedFieldRows(
      pendingPayloadRaw: member.pendingUpdatePayload,
      previousSnapshotRaw: member.previousPublicProfileSnapshot,
    );
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
            const SizedBox(height: 10),
            if (requestedFields.isNotEmpty) ...<Widget>[
              const Text(
                'Requested Changes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...requestedFields,
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _resolveUpdate(member, true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve Update'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _resolveUpdate(member, false),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _requestedFieldRows({
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

      final rows = <Widget>[];
      payload.forEach((key, value) {
        if (key == 'emergencyContact') {
          return;
        }
        final nextValue = (value ?? '').toString().trim();
        if (nextValue.isEmpty) {
          return;
        }
        final previousValue =
            (previousSnapshot[key] ?? '').toString().trim();
        final isChanged = nextValue.toLowerCase() != previousValue.toLowerCase();
        if (!isChanged) {
          return;
        }

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
                Text(
                  _fieldLabel(key),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Previous: ${previousValue.isEmpty ? '-' : previousValue}'),
                const SizedBox(height: 2),
                Text('Requested: $nextValue'),
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
            Text('Home: ${member.homeDistrict}'),
            Text('Posting: ${member.postingLocation}, ${member.postingDistrict}'),
            if (member.referenceMemberName != null)
              Text('Reference: ${member.referenceMemberName}'),
            const SizedBox(height: 12),
            const Text(
              'Uploaded documents',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildDocumentPreview(
              label: 'Selfie photo',
              path: member.selfiePath,
            ),
            const SizedBox(height: 8),
            _buildDocumentPreview(
              label: 'ID card photo',
              path: member.idCardPhotoPath,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _approveMember(member),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Approve Member'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview({
    required String label,
    required String? path,
  }) {
    if (path == null || path.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$label: not uploaded'),
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
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text('Preview unavailable'));
            },
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
          return Image.memory(
            snapshot.data!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
          );
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
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: child,
            ),
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

  Future<void> _approveMember(Member member) async {
    if (!widget.currentUser.isAdmin) {
      return;
    }

    final success = await widget.repository.setMemberApproved(
      actor: widget.currentUser,
      memberId: member.id,
      approved: true,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to approve member.')),
      );
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} approved successfully.')),
    );
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

  Future<void> _resolveUpdate(Member member, bool approve) async {
    final success = await widget.repository.resolvePendingUpdate(
      actor: widget.currentUser,
      memberId: member.id,
      approve: approve,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process update request.')),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Update approved.' : 'Update rejected.')),
    );
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
