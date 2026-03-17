import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import 'member_repository.dart';

class AuthResult {
  const AuthResult({this.member, this.error});

  final Member? member;
  final String? error;

  bool get isSuccess => member != null;
}

class AuthService {
  static const _activeUserKey = 'active_user_id';
  static const _lastMobileKey = 'last_mobile_number';

  AuthService(this._repository);

  final MemberRepository _repository;
  final Map<String, String> _pendingOtps = <String, String>{};
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<Member?> loadSession() async {
    await initialize();
    final userId = _preferences?.getString(_activeUserKey);
    if (userId == null) {
      return null;
    }
    return _repository.findById(userId);
  }

  Future<void> logout() async {
    await initialize();
    await _preferences?.remove(_activeUserKey);
  }

  String hashPassword(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String issueOtp(String mobileNumber) {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.length != 10) {
      return '';
    }
    final lastFour = normalized.substring(normalized.length - 4);
    final otp = '1${lastFour}9';
    _pendingOtps[normalized] = otp;
    return otp;
  }

  Future<AuthResult> loginWithOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final normalized = _normalizeMobile(mobileNumber);
    final member = await _resolveMember(normalized);
    if (member == null) {
      return const AuthResult(error: 'Member not found.');
    }
    if (_pendingOtps[normalized] != otp) {
      return const AuthResult(error: 'Invalid OTP.');
    }
    return _completeLogin(member);
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

  Future<AuthResult> loginWithBiometric() async {
    await initialize();
    final lastMobile = _preferences?.getString(_lastMobileKey);
    if (lastMobile == null) {
      return const AuthResult(error: 'No previous member available for biometric login.');
    }
    final member = await _resolveMember(lastMobile);
    if (member == null) {
      return const AuthResult(error: 'Stored member session is no longer valid.');
    }
    final canCheck = await _localAuthentication.canCheckBiometrics;
    final isSupported = await _localAuthentication.isDeviceSupported();
    if (!canCheck && !isSupported) {
      return const AuthResult(error: 'Biometric authentication is not available on this device.');
    }
    final authenticated = await _localAuthentication.authenticate(
      localizedReason: 'Authenticate to access the member directory',
      options: const AuthenticationOptions(biometricOnly: true),
    );
    if (!authenticated) {
      return const AuthResult(error: 'Biometric authentication was cancelled.');
    }
    return _completeLogin(member);
  }

  Future<AuthResult> _completeLogin(Member member) async {
    await initialize();
    if (member.needsProfileRefresh) {
      return const AuthResult(error: 'Profile update required before login.');
    }
    if (member.needsPasswordRefresh) {
      return const AuthResult(error: 'Password renewal required before login.');
    }
    await _preferences?.setString(_activeUserKey, member.id);
    await _preferences?.setString(_lastMobileKey, member.mobileNumber);
    return AuthResult(member: member);
  }

  Future<Member?> _resolveMember(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.isEmpty) {
      return null;
    }
    final local = _repository.findByMobile(normalized);
    if (local != null) {
      return local;
    }

    // Pull latest directory rows before failing login when a member was seeded remotely.
    await _repository.refreshFromCloud();
    final refreshed = _repository.findByMobile(normalized);
    if (refreshed != null) {
      return refreshed;
    }
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