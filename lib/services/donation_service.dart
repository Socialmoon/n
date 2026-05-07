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
  bool _createDonationInProgress = false;
  String? _lastCreateFingerprint;
  DateTime? _lastCreateAt;

  String get upiId => _upiId;
  String get upiName => _upiName;
  String get adminMobile => _adminMobile;
  String? get customQrImageUrl => _customQrImageUrl;
  String? get lastUploadError => _cloudService.lastUploadError;
  String? _lastOperationError;
  String? get lastWriteError => _lastOperationError ?? _cloudService.lastWriteError;

  Future<void> load() async {
    if (!_cloudService.isConfigured) {
      return;
    }
    try {
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
      final rawQrUrl = await _cloudService.fetchAppSetting(
        key: 'donation_qr_image_url',
      );
      final resolvedQrUrl = await _cloudService.resolveMediaUrl(rawQrUrl);
      _customQrImageUrl = (resolvedQrUrl == null || resolvedQrUrl.isEmpty)
          ? null
          : resolvedQrUrl;
    } catch (_) {
      return;
    }
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
    try {
      final saved = await _cloudService.upsertDonation(_donations[index]);
      if (!saved) {
        _donations[index] = current;
      }
    } catch (_) {
      _donations[index] = current;
    }
  }

  Future<bool> deleteDonation({
    required Member actor,
    required String donationId,
  }) async {
    if (!actor.isAdmin) {
      return false;
    }

    final index = _donations.indexWhere((entry) => entry.id == donationId);
    if (index == -1) {
      return false;
    }

    final removed = _donations.removeAt(index);
    try {
      final deleted = await _cloudService.deleteDonation(donationId);
      if (!deleted) {
        _donations.insert(index, removed);
        return false;
      }
      return true;
    } catch (_) {
      _donations.insert(index, removed);
      return false;
    }
  }

  Future<int> deleteDonationsByMemberMobile({
    required Member actor,
    required String memberMobile,
  }) async {
    if (!actor.isAdmin) {
      return 0;
    }

    final targets = _donations
        .where((entry) => entry.memberMobile == memberMobile)
        .map((entry) => entry.id)
        .toList();
    if (targets.isEmpty) {
      return 0;
    }

    var deletedCount = 0;
    try {
      for (final donationId in targets) {
        final deleted = await deleteDonation(actor: actor, donationId: donationId);
        if (!deleted) {
          break;
        }
        deletedCount++;
      }
      return deletedCount;
    } catch (_) {
      return deletedCount;
    }
  }

  Future<bool> updatePaymentSettings({
    required Member actor,
    required String upiId,
    required String upiName,
    required String adminMobile,
    String? customQrImageUrl,
  }) async {
    _lastOperationError = null;
    if (!actor.isAdmin) {
      _lastOperationError = 'Only admins can update UPI/QR settings.';
      return false;
    }
    final previousUpiId = _upiId;
    final previousUpiName = _upiName;
    final previousAdminMobile = _adminMobile;
    final previousCustomQrImageUrl = _customQrImageUrl;

    _upiId = upiId.trim();
    _upiName = upiName.trim();
    _adminMobile = adminMobile.trim();
    final rawQrForDb = _cloudService.storagePathFromMediaValue(customQrImageUrl);
    _customQrImageUrl = await _cloudService.resolveMediaUrl(rawQrForDb);

    try {
      final upiSaved =
          await _cloudService.upsertAppSetting(key: 'donation_upi_id', value: _upiId);
      final nameSaved =
          await _cloudService.upsertAppSetting(key: 'donation_upi_name', value: _upiName);
      final adminSaved = await _cloudService.upsertAppSetting(
        key: 'donation_admin_mobile',
        value: _adminMobile,
      );
      final qrSaved = await _cloudService.upsertAppSetting(
        key: 'donation_qr_image_url',
        value: rawQrForDb ?? '',
      );

      final allSaved = upiSaved && nameSaved && adminSaved && qrSaved;
      if (!allSaved) {
        _upiId = previousUpiId;
        _upiName = previousUpiName;
        _adminMobile = previousAdminMobile;
        _customQrImageUrl = previousCustomQrImageUrl;
        _lastOperationError = _cloudService.lastWriteError;
        return false;
      }

      return true;
    } catch (_) {
      _upiId = previousUpiId;
      _upiName = previousUpiName;
      _adminMobile = previousAdminMobile;
      _customQrImageUrl = previousCustomQrImageUrl;
      _lastOperationError = _cloudService.lastWriteError;
      return false;
    }
  }

  Future<bool> createDonation({
    required Member member,
    required double amount,
    required String upiId,
    String? note,
    String? transactionRef,
    String? screenshotPath,
  }) async {
    _lastOperationError = null;

    final normalizedNote = note?.trim() ?? '';
    final normalizedRef = transactionRef?.trim().toLowerCase();
    final fingerprint =
        '${member.id}|${amount.toStringAsFixed(2)}|${normalizedRef ?? ''}|${normalizedNote.toLowerCase()}';

    if (_createDonationInProgress) {
      _lastOperationError =
          'A donation submission is already in progress. Please wait.';
      return false;
    }

    final recentDuplicate = _lastCreateFingerprint == fingerprint &&
        _lastCreateAt != null &&
        DateTime.now().difference(_lastCreateAt!).inMinutes < 5;
    if (recentDuplicate) {
      _lastOperationError =
          'This donation was already submitted recently. Please refresh history before retrying.';
      return false;
    }

    if (normalizedRef != null && normalizedRef.isNotEmpty) {
      final duplicateRef = _donations.any(
        (entry) =>
            entry.memberId == member.id &&
            (entry.transactionRef?.trim().toLowerCase() == normalizedRef),
      );
      if (duplicateRef) {
        _lastOperationError =
            'Duplicate transaction reference detected. Please check before retrying.';
        return false;
      }
    }

    final now = DateTime.now();
    final duplicateWindow = _donations.any(
      (entry) =>
          entry.memberId == member.id &&
          entry.amount == amount &&
          entry.createdAt.isAfter(now.subtract(const Duration(minutes: 2))) &&
          (entry.note?.trim() ?? '') == normalizedNote,
    );
    if (duplicateWindow) {
      _lastOperationError =
          'A similar donation entry was submitted recently. Please wait and refresh history.';
      return false;
    }

    final entry = DonationEntry(
      id: now.microsecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      memberMobile: member.mobileNumber,
      amount: amount,
      upiId: upiId,
      status: 'Unverified',
      createdAt: now,
      note: normalizedNote.isEmpty ? null : normalizedNote,
      transactionRef:
          normalizedRef == null || normalizedRef.isEmpty ? null : normalizedRef,
      screenshotPath: screenshotPath,
    );

    _createDonationInProgress = true;
    _donations.add(entry);
    try {
      final saved = await _cloudService.insertDonation(entry);
      if (!saved) {
        _donations.removeWhere((item) => item.id == entry.id);
        return false;
      }

      _lastCreateFingerprint = fingerprint;
      _lastCreateAt = DateTime.now();
      return true;
    } catch (_) {
      _donations.removeWhere((item) => item.id == entry.id);
      return false;
    } finally {
      _createDonationInProgress = false;
    }
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
    _lastOperationError = null;
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
    final previousCustomQrImageUrl = _customQrImageUrl;
    _customQrImageUrl = await _cloudService.resolveMediaUrl(uploaded);
    final saved = await _cloudService.upsertAppSetting(
      key: 'donation_qr_image_url',
      value: uploaded,
    );
    if (!saved) {
      _customQrImageUrl = previousCustomQrImageUrl;
      _lastOperationError = _cloudService.lastWriteError;
      return null;
    }
    return _customQrImageUrl;
  }
}
