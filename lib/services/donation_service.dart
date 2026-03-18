import 'package:shared_preferences/shared_preferences.dart';

import '../models/donation_entry.dart';
import '../models/member.dart';
import 'supabase_service.dart';

class DonationService {
  DonationService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  static const _donationsKey = 'donations_entries';

  final SupabaseService _cloudService;
  SharedPreferences? _preferences;
  final List<DonationEntry> _donations = <DonationEntry>[];

  List<DonationEntry> get donations => List.unmodifiable(_donations.reversed);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final raw = _preferences?.getStringList(_donationsKey) ?? <String>[];
    _donations
      ..clear()
      ..addAll(raw.map(DonationEntry.fromJson));

    if (!_cloudService.isConfigured) {
      return;
    }

    final cloud = await _cloudService.fetchDonations();
    if (cloud.isEmpty) {
      return;
    }

    _donations
      ..clear()
      ..addAll(cloud.reversed);
    await _persist();
  }

  Future<void> createDonation({
    required Member member,
    required double amount,
    required String upiId,
    String? note,
    String? transactionRef,
    String? screenshotPath,
  }) async {
    final entry = DonationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      memberMobile: member.mobileNumber,
      amount: amount,
      upiId: upiId,
      status: 'Pending Verification',
      createdAt: DateTime.now(),
      note: note,
      transactionRef: transactionRef,
      screenshotPath: screenshotPath,
    );

    _donations.add(entry);
    await _persist();
    await _cloudService.insertDonation(entry);
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _donationsKey,
      _donations.map((entry) => entry.toJson()).toList(),
    );
  }
}
