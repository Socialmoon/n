import 'package:image_picker/image_picker.dart';

import '../models/donation_entry.dart';
import '../models/member.dart';
import 'supabase_service.dart';

class DonationService {
  DonationService({required SupabaseService cloudService})
      : _cloudService = cloudService;

  final SupabaseService _cloudService;
  final List<DonationEntry> _donations = <DonationEntry>[];

  static const String defaultUpiId = 'policenetworksupport@oksbi';
  static const String defaultUpiName = 'Apne Saathi Support';
  static const String defaultAdminMobile = '9193410557';

  List<DonationEntry> get donations => List.unmodifiable(_donations.reversed);

  String _upiId = defaultUpiId;
  String _upiName = defaultUpiName;
  String _adminMobile = defaultAdminMobile;
  String? _customQrImageUrl;

  String get upiId => _upiId;
  String get upiName => _upiName;
  String get adminMobile => _adminMobile;
  String? get customQrImageUrl => _customQrImageUrl;

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }

    final cloud = await _cloudService.fetchDonations();
    _donations
      ..clear()
      ..addAll(cloud.reversed);

    _upiId = await _cloudService.fetchAppSetting(
          key: 'donation_upi_id',
        ) ??
        defaultUpiId;
    _upiName = await _cloudService.fetchAppSetting(
          key: 'donation_upi_name',
        ) ??
        defaultUpiName;
    _adminMobile = await _cloudService.fetchAppSetting(
          key: 'donation_admin_mobile',
        ) ??
        defaultAdminMobile;
    _customQrImageUrl = await _cloudService.fetchAppSetting(
      key: 'donation_qr_image_url',
    );
  }

  Future<void> updateDonationStatus({
    required Member actor,
    required String donationId,
    required String status,
    String? rejectionReason,
  }) async {
    if (!actor.isAdmin) {
      return;
    }

    final index = _donations.indexWhere((entry) => entry.id == donationId);
    if (index == -1) {
      return;
    }

    final current = _donations[index];
    _donations[index] = current.copyWith(
      status: status,
      reviewedAt: DateTime.now(),
      reviewedBy: actor.name,
      rejectionReason: status.toLowerCase() == 'rejected' ? rejectionReason : null,
    );
    await _cloudService.upsertDonation(_donations[index]);
  }

  Future<void> updatePaymentSettings({
    required Member actor,
    required String upiId,
    required String upiName,
    required String adminMobile,
    String? customQrImageUrl,
  }) async {
    if (!actor.isAdmin) {
      return;
    }
    _upiId = upiId.trim();
    _upiName = upiName.trim();
    _adminMobile = adminMobile.trim();
    _customQrImageUrl = customQrImageUrl?.trim().isEmpty == true
        ? null
        : customQrImageUrl;
    await _cloudService.upsertAppSetting(key: 'donation_upi_id', value: _upiId);
    await _cloudService.upsertAppSetting(key: 'donation_upi_name', value: _upiName);
    await _cloudService.upsertAppSetting(
      key: 'donation_admin_mobile',
      value: _adminMobile,
    );
    await _cloudService.upsertAppSetting(
      key: 'donation_qr_image_url',
      value: _customQrImageUrl ?? '',
    );
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
    await _cloudService.insertDonation(entry);
  }

  Future<String?> uploadProofScreenshot(XFile screenshot) async {
    final bytes = await screenshot.readAsBytes();
    final now = DateTime.now().microsecondsSinceEpoch;
    return _cloudService.uploadImageBytes(
      bytes: bytes,
      folder: 'donation-proofs',
      fileName: 'proof_$now.jpg',
    );
  }

  Future<String?> uploadCustomQrImage(XFile qrImage) async {
    final bytes = await qrImage.readAsBytes();
    final now = DateTime.now().microsecondsSinceEpoch;
    final uploaded = await _cloudService.uploadImageBytes(
      bytes: bytes,
      folder: 'donation-qr',
      fileName: 'custom_qr_$now.jpg',
    );
    if (uploaded == null) {
      return null;
    }
    _customQrImageUrl = uploaded;
    await _cloudService.upsertAppSetting(
      key: 'donation_qr_image_url',
      value: uploaded,
    );
    return uploaded;
  }
}
