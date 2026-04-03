import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/brand.dart';
import '../models/donation_entry.dart';
import '../models/member.dart';
import '../services/donation_service.dart';

class AdminPaymentReviewsScreen extends StatefulWidget {
  const AdminPaymentReviewsScreen({
    required this.currentUser,
    required this.donationService,
    super.key,
  });

  final Member currentUser;
  final DonationService donationService;

  @override
  State<AdminPaymentReviewsScreen> createState() => _AdminPaymentReviewsScreenState();
}

class _AdminPaymentReviewsScreenState extends State<AdminPaymentReviewsScreen> {
  final TextEditingController _rejectionController = TextEditingController();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const BrandedScreenTitle('Payment Verification')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Only admins can verify donation screenshots.'),
          ),
        ),
      );
    }

    final donations = widget.donationService.donations;
    final pending = donations.where((item) => item.isPending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('Payment Verification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No pending payment proofs to review.'),
              ),
            ),
          ...pending.map(_buildReviewCard),
        ],
      ),
    );
  }

  Widget _buildReviewCard(DonationEntry entry) {
    final stamp =
        '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year} ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${entry.memberName} • Rs ${entry.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Mobile: ${entry.memberMobile}'),
            Text('UPI: ${entry.upiId}'),
            Text('Submitted: $stamp'),
            if (entry.transactionRef?.isNotEmpty == true)
              Text('Ref: ${entry.transactionRef}'),
            if (entry.note?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Note: ${entry.note}'),
              ),
            const SizedBox(height: 10),
            _buildScreenshotPreview(entry.screenshotPath),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _verify(entry),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Verify'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _reject(entry),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reject'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _delete(entry),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotPreview(String? path) {
    if (path == null || path.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No screenshot uploaded with this donation entry.'),
      );
    }

    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 80,
            child: Center(child: Text('Screenshot preview unavailable.')),
          ),
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: XFile(path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!snapshot.hasData || snapshot.hasError || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('Screenshot preview unavailable.')),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snapshot.data!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Future<void> _verify(DonationEntry entry) async {
    await widget.donationService.updateDonationStatus(
      actor: widget.currentUser,
      donationId: entry.id,
      status: 'Verified',
    );
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation proof marked as verified.')),
    );
  }

  Future<void> _reject(DonationEntry entry) async {
    _rejectionController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject payment proof'),
          content: TextField(
            controller: _rejectionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Example: Screenshot does not match transaction details.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_rejectionController.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null) {
      return;
    }

    await widget.donationService.updateDonationStatus(
      actor: widget.currentUser,
      donationId: entry.id,
      status: 'Rejected',
      rejectionReason: reason.isEmpty ? null : reason,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation proof rejected.')),
    );
  }

  Future<void> _delete(DonationEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete payment proof?'),
          content: Text(
            'This will permanently delete ${entry.memberName}\'s donation entry from Supabase.',
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

    final deleted = await widget.donationService.deleteDonation(
      actor: widget.currentUser,
      donationId: entry.id,
    );

    if (!mounted) {
      return;
    }

    if (!deleted) {
      final writeError = widget.donationService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to delete donation proof. Please try again.'
          : 'Unable to delete donation proof: $writeError';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation proof deleted.')),
    );
  }
}
