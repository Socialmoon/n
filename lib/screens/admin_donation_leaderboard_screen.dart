import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../models/member.dart';
import '../services/donation_service.dart';

class AdminDonationLeaderboardScreen extends StatefulWidget {
  const AdminDonationLeaderboardScreen({
    required this.currentUser,
    required this.donationService,
    super.key,
  });

  final Member currentUser;
  final DonationService donationService;

  @override
  State<AdminDonationLeaderboardScreen> createState() =>
      _AdminDonationLeaderboardScreenState();
}

class _AdminDonationLeaderboardScreenState
    extends State<AdminDonationLeaderboardScreen> {

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const BrandedScreenTitle('Donations Leaderboard')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can view this page.'),
          ),
        ),
      );
    }

    final donations = widget.donationService.donations;
    final Map<String, _MemberDonationStats> stats = <String, _MemberDonationStats>{};
    for (final entry in donations) {
      final existing = stats[entry.memberMobile];
      if (existing == null) {
        stats[entry.memberMobile] = _MemberDonationStats(
          memberName: entry.memberName,
          memberMobile: entry.memberMobile,
          totalAmount: entry.amount,
          donationCount: 1,
          verifiedCount: entry.isVerified ? 1 : 0,
          rejectedCount: entry.isRejected ? 1 : 0,
        );
      } else {
        stats[entry.memberMobile] = existing.copyWith(
          totalAmount: existing.totalAmount + entry.amount,
          donationCount: existing.donationCount + 1,
          verifiedCount: existing.verifiedCount + (entry.isVerified ? 1 : 0),
          rejectedCount: existing.rejectedCount + (entry.isRejected ? 1 : 0),
        );
      }
    }

    final leaderboard = stats.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final totalAmount = donations.fold<double>(0, (sum, item) => sum + item.amount);
    final verifiedAmount = donations
        .where((item) => item.isVerified)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('Donations Leaderboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _summaryTile(
                  'All Entries',
                  '${donations.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  'Total Amount',
                  'Rs ${totalAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryTile(
            'Verified Amount',
            'Rs ${verifiedAmount.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 14),
          if (leaderboard.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No donations available yet.'),
              ),
            ),
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
                subtitle: Text(
                  '${item.memberMobile} • ${item.donationCount} entries • ${item.verifiedCount} verified • ${item.rejectedCount} rejected',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Rs ${item.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => _deleteMember(item),
                      tooltip: 'Delete member donation entries',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _deleteMember(_MemberDonationStats item) async {
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

  Widget _summaryTile(String title, String value) {
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
}

class _MemberDonationStats {
  const _MemberDonationStats({
    required this.memberName,
    required this.memberMobile,
    required this.totalAmount,
    required this.donationCount,
    required this.verifiedCount,
    required this.rejectedCount,
  });

  final String memberName;
  final String memberMobile;
  final double totalAmount;
  final int donationCount;
  final int verifiedCount;
  final int rejectedCount;

  _MemberDonationStats copyWith({
    String? memberName,
    String? memberMobile,
    double? totalAmount,
    int? donationCount,
    int? verifiedCount,
    int? rejectedCount,
  }) {
    return _MemberDonationStats(
      memberName: memberName ?? this.memberName,
      memberMobile: memberMobile ?? this.memberMobile,
      totalAmount: totalAmount ?? this.totalAmount,
      donationCount: donationCount ?? this.donationCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}
