import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

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

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Member Approvals')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can view and approve new members.'),
          ),
        ),
      );
    }

    final pending = widget.repository.pendingApprovals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Member Approvals'),
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
          if (pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending approvals right now.'),
              ),
            ),
          ...pending.map(_buildPendingCard),
        ],
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
        child: Image.network(
          path,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Preview unavailable'));
          },
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
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
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
              height: 170,
              width: double.infinity,
              child: child,
            ),
          ),
        ],
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
}
