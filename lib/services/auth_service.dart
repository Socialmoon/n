import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import 'member_repository.dart';
import 'otp_service.dart';

class AuthResult {
  const AuthResult({this.member, this.error});

  final Member? member;
  final String? error;

  bool get isSuccess => member != null;
}

class AuthService {
  AuthService(this._repository, {OtpService? otpService});

  final MemberRepository _repository;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  String? _activeUserId;
  String? _lastMobile;

  Future<void> initialize() async {}

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
    final member = await _resolveMember(normalized);
    if (member == null) {
      return const AuthResult(error: 'Member not found.');
    }
    if (member.mpin != mpin) {
      return const AuthResult(error: 'Incorrect M-PIN.');
    }
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
    final now = DateTime.now();
    final updatedMember = member.copyWith(
      lastLoginAt: now,
      lastUpdated: now,
    );
    await _repository.saveMember(updatedMember);
    _activeUserId = updatedMember.id;
    _lastMobile = updatedMember.mobileNumber;
    return AuthResult(member: updatedMember);
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

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}
