import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import 'member_repository.dart';
import 'otp_service.dart';
import 'device_binding_service.dart';

class AuthResult {
  const AuthResult({
    this.member,
    this.error,
    this.requiresDeviceVerification = false,
  });

  final Member? member;
  final String? error;
  final bool requiresDeviceVerification;

  bool get isSuccess => member != null;
}

class AuthService {
  AuthService(this._repository, {OtpService? otpService});

  final MemberRepository _repository;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  String? _activeUserId;
  String? _lastMobile;
  static const int _maxLoginFailures = 5;
  static const Duration _loginLockDuration = Duration(minutes: 5);
  final Map<String, int> _mpinFailuresByMobile = <String, int>{};
  final Map<String, DateTime> _loginLockedUntilByMobile = <String, DateTime>{};
  static const String _lastMobileKey = 'auth_last_mobile';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_lastMobileKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _lastMobile = _normalizeMobile(saved);
    }
  }

  Future<Member?> loadSession() async {
    if (_activeUserId == null) {
      return null;
    }
    return _repository.findById(_activeUserId!);
  }

  Future<void> logout() async {
    _activeUserId = null;
  }

  String hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  Future<OtpDispatchResult> issueOtp(String mobileNumber) {
    // OTP is temporarily disabled across the app.
    return Future<OtpDispatchResult>.value(
      const OtpDispatchResult(
        success: false,
        error: 'OTP login is currently disabled.',
      ),
    );
  }

  Future<AuthResult> loginWithOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    // OTP is temporarily disabled across the app.
    return const AuthResult(error: 'OTP login is currently disabled.');
  }

  Future<OtpVerifyResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) {
    // OTP is temporarily disabled across the app.
    return Future<OtpVerifyResult>.value(
      const OtpVerifyResult(
        success: false,
        error: 'OTP verification is currently disabled.',
      ),
    );
  }

  Future<bool> isBiometricAvailable({String? mobileNumber}) async {
    final targetMobile = _normalizeMobile(mobileNumber ?? _lastMobile ?? '');
    if (targetMobile.isEmpty) {
      return false;
    }
    final member = await _resolveMember(targetMobile);
    if (member == null) {
      return false;
    }
    if (!_isBiometricEnabled(member)) {
      return false;
    }

    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!canCheck && !isSupported) {
        return false;
      }
      final available = await _localAuthentication.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> loginWithMpin({
    required String mobileNumber,
    required String mpin,
  }) async {
    final normalized = _normalizeMobile(mobileNumber);
    final lock = _loginLockedUntilByMobile[normalized];
    if (lock != null && DateTime.now().isBefore(lock)) {
      final waitMinutes = lock.difference(DateTime.now()).inMinutes + 1;
      return AuthResult(
        error: 'Too many failed attempts. Try again in $waitMinutes minute(s).',
      );
    }

    final member = await _resolveMember(normalized);
    if (member == null) {
      _recordMpinFailure(normalized);
      return const AuthResult(error: 'Invalid mobile number or M-PIN.');
    }
    if (member.mpin != mpin) {
      _recordMpinFailure(normalized);
      return const AuthResult(error: 'Invalid mobile number or M-PIN.');
    }
    _clearMpinFailures(normalized);
    return _completeLogin(member);
  }

  Future<AuthResult> loginWithBiometric({String? mobileNumber}) async {
    final targetMobile = _normalizeMobile(mobileNumber ?? _lastMobile ?? '');
    if (targetMobile.isEmpty) {
      return const AuthResult(
          error: 'Enter your mobile number before biometric login.');
    }
    final member = await _resolveMember(targetMobile);
    if (member == null) {
      return const AuthResult(
          error: 'Member not found for this mobile number.');
    }
    if (!_isBiometricEnabled(member)) {
      return const AuthResult(
        error:
            'Biometric login is not enabled for this account. Register fingerprint in Account page first.',
      );
    }
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!canCheck && !isSupported) {
        return const AuthResult(
            error: 'Biometric authentication is not available on this device.');
      }

      final available = await _localAuthentication.getAvailableBiometrics();
      if (available.isEmpty) {
        return const AuthResult(
            error: 'No biometric credentials are enrolled on this device.');
      }

      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to access the member directory',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) {
        return const AuthResult(
            error: 'Biometric authentication was cancelled.');
      }
      return _completeLogin(member);
    } on PlatformException {
      return const AuthResult(
          error: 'Biometric authentication is unavailable on this platform.');
    } catch (_) {
      return const AuthResult(
          error: 'Biometric authentication is unavailable on this platform.');
    }
  }

  Future<AuthResult> _completeLogin(Member member) async {
    if (member.isDeleted) {
      return const AuthResult(
          error: 'Your account has been deleted. Contact an admin.');
    }
    if (member.isBlocked) {
      return const AuthResult(
          error: 'Your account has been blocked. Contact an admin.');
    }
    if (!member.isApproved) {
      return const AuthResult(
          error: 'Your registration is pending admin approval.');
    }
    if (member.needsProfileRefresh) {
      return const AuthResult(error: 'Profile update required before login.');
    }
    if (member.needsPasswordRefresh) {
      return const AuthResult(error: 'Password renewal required before login.');
    }

    // Device binding check
    final deviceBinding = DeviceBindingService();
    final currentDeviceId = await deviceBinding.getDeviceId();
    final currentFingerprint = await deviceBinding.generateFingerprint();
    final payload = _decodePendingPayload(member.pendingUpdatePayload);
    final storedDeviceId = payload['trustedDeviceId'] as String?;
    final storedFingerprint = payload['trustedDeviceFingerprint'] as String?;

    Member memberToSave = member;
    if (storedDeviceId == null || storedDeviceId.isEmpty) {
      // First successful login binds the current device.
      payload['trustedDeviceId'] = currentDeviceId;
      payload['trustedDeviceFingerprint'] = currentFingerprint;
      payload['trustedDeviceBoundAt'] = DateTime.now().toIso8601String();
      memberToSave = member.copyWith(
        pendingUpdatePayload: jsonEncode(payload),
      );
    } else if (storedDeviceId != currentDeviceId ||
        (storedFingerprint != null &&
            storedFingerprint.isNotEmpty &&
            storedFingerprint != currentFingerprint)) {
      if (member.email?.isNotEmpty ?? false) {
        return AuthResult(
          member: member,
          requiresDeviceVerification: true,
        );
      }
      return const AuthResult(
        error:
            'New device detected, but no email is registered for verification.',
      );
    }

    final now = DateTime.now();
    final updatedMember = memberToSave.copyWith(
      lastLoginAt: now,
      lastUpdated: now,
    );
    await _repository.saveMember(updatedMember);
    _activeUserId = updatedMember.id;
    _lastMobile = updatedMember.mobileNumber;
    await _persistLastMobile(updatedMember.mobileNumber);
    return AuthResult(member: updatedMember);
  }

  Future<AuthResult> completeDeviceVerification(Member member) async {
    final deviceBinding = DeviceBindingService();
    final currentDeviceId = await deviceBinding.getDeviceId();
    final currentFingerprint = await deviceBinding.generateFingerprint();
    final payload = _decodePendingPayload(member.pendingUpdatePayload);
    payload['trustedDeviceId'] = currentDeviceId;
    payload['trustedDeviceFingerprint'] = currentFingerprint;
    payload['trustedDeviceBoundAt'] = DateTime.now().toIso8601String();

    final now = DateTime.now();
    final updatedMember = member.copyWith(
      pendingUpdatePayload: jsonEncode(payload),
      lastLoginAt: now,
      lastUpdated: now,
    );
    await _repository.saveMember(updatedMember);
    _activeUserId = updatedMember.id;
    _lastMobile = updatedMember.mobileNumber;
    await _persistLastMobile(updatedMember.mobileNumber);
    return AuthResult(member: updatedMember);
  }

  Future<AuthResult> registerOrUpdateBiometric(Member member) async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!canCheck && !isSupported) {
        return const AuthResult(
          error: 'Biometric authentication is not available on this device.',
        );
      }

      final available = await _localAuthentication.getAvailableBiometrics();
      if (available.isEmpty) {
        return const AuthResult(
          error: 'No biometric credentials are enrolled on this device.',
        );
      }

      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Verify fingerprint to enable biometric login',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!authenticated) {
        return const AuthResult(
          error: 'Biometric verification was cancelled.',
        );
      }

      final payload = _decodePendingPayload(member.pendingUpdatePayload);
      payload['biometricEnabled'] = true;
      payload['biometricEnrolledAt'] = DateTime.now().toIso8601String();

      final updated = member.copyWith(
        pendingUpdatePayload: jsonEncode(payload),
        lastUpdated: DateTime.now(),
      );
      final saved = await _repository.saveMember(updated);
      if (!saved) {
        return const AuthResult(
          error: 'Unable to save biometric preference to cloud.',
        );
      }
      _lastMobile = updated.mobileNumber;
      await _persistLastMobile(updated.mobileNumber);
      return AuthResult(member: updated);
    } on PlatformException {
      return const AuthResult(
        error: 'Biometric authentication is unavailable on this platform.',
      );
    } catch (_) {
      return const AuthResult(
        error: 'Unable to verify biometric right now.',
      );
    }
  }

  bool isBiometricEnabledForMember(Member member) {
    return _isBiometricEnabled(member);
  }

  Map<String, dynamic> _decodePendingPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<Member?> _resolveMember(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
    // Always refresh once so profile fields (like selfie_path) reflect latest cloud state.
    await _repository.refreshFromCloud();
    final latest = _repository.findByMobile(normalized);
    if (latest != null) {
      return latest;
    }

    // Fallback direct lookup for partial directory loads.
    return _repository.fetchByMobileFromCloud(normalized);
  }

  bool _isBiometricEnabled(Member member) {
    final payload = _decodePendingPayload(member.pendingUpdatePayload);
    final raw = payload['biometricEnabled'];
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    if (raw is num) {
      return raw != 0;
    }
    return false;
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  void _recordMpinFailure(String mobile) {
    if (mobile.isEmpty) {
      return;
    }
    final current = _mpinFailuresByMobile[mobile] ?? 0;
    final next = current + 1;
    _mpinFailuresByMobile[mobile] = next;
    if (next >= _maxLoginFailures) {
      _loginLockedUntilByMobile[mobile] = DateTime.now().add(_loginLockDuration);
      _mpinFailuresByMobile[mobile] = 0;
    }
  }

  void _clearMpinFailures(String mobile) {
    if (mobile.isEmpty) {
      return;
    }
    _mpinFailuresByMobile.remove(mobile);
    _loginLockedUntilByMobile.remove(mobile);
  }

  Future<void> _persistLastMobile(String mobile) async {
    final normalized = _normalizeMobile(mobile);
    if (normalized.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastMobileKey, normalized);
  }
}
