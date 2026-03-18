import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/twilio_config.dart';

class OtpDispatchResult {
  const OtpDispatchResult({
    required this.success,
    this.error,
    this.debugOtp,
  });

  final bool success;
  final String? error;
  final String? debugOtp;
}

class OtpVerifyResult {
  const OtpVerifyResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

class OtpService {
  final Map<String, String> _localPendingOtps = <String, String>{};
  final Random _random = Random.secure();

  Future<OtpDispatchResult> sendOtp(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.length != 10) {
      return const OtpDispatchResult(
        success: false,
        error: 'Enter a valid 10 digit mobile number.',
      );
    }

    final to = _toE164(normalized);
    if (to == null) {
      return const OtpDispatchResult(
        success: false,
        error: 'Unable to format phone number for OTP.',
      );
    }

    if (!TwilioConfig.isConfigured) {
      final otp = _generateOtp();
      _localPendingOtps[normalized] = otp;
      debugPrint('Twilio not configured. Local OTP for $normalized: $otp');
      return OtpDispatchResult(success: true, debugOtp: otp);
    }

    final auth = base64Encode(
      utf8.encode('${TwilioConfig.accountSid}:${TwilioConfig.authToken}'),
    );
    final uri = Uri.parse(
      'https://verify.twilio.com/v2/Services/${TwilioConfig.verifyServiceSid}/Verifications',
    );

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'To': to,
          'Channel': 'sms',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            'Twilio send OTP failed: ${response.statusCode} ${response.body}');
        return const OtpDispatchResult(
          success: false,
          error: 'Failed to send OTP. Please try again.',
        );
      }

      return const OtpDispatchResult(success: true);
    } catch (error) {
      debugPrint('Twilio send OTP exception: $error');
      return const OtpDispatchResult(
        success: false,
        error: 'Unable to reach OTP service. Check network and retry.',
      );
    }
  }

  Future<OtpVerifyResult> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.length != 10) {
      return const OtpVerifyResult(
        success: false,
        error: 'Enter a valid 10 digit mobile number.',
      );
    }

    if (otp.length != 6) {
      return const OtpVerifyResult(
        success: false,
        error: 'Enter the 6 digit OTP.',
      );
    }

    if (!TwilioConfig.isConfigured) {
      final expected = _localPendingOtps[normalized];
      if (expected == null || expected != otp) {
        return const OtpVerifyResult(success: false, error: 'Invalid OTP.');
      }
      _localPendingOtps.remove(normalized);
      return const OtpVerifyResult(success: true);
    }

    final to = _toE164(normalized);
    if (to == null) {
      return const OtpVerifyResult(
        success: false,
        error: 'Unable to format phone number for OTP verification.',
      );
    }

    final auth = base64Encode(
      utf8.encode('${TwilioConfig.accountSid}:${TwilioConfig.authToken}'),
    );
    final uri = Uri.parse(
      'https://verify.twilio.com/v2/Services/${TwilioConfig.verifyServiceSid}/VerificationCheck',
    );

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'To': to,
          'Code': otp,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            'Twilio verify OTP failed: ${response.statusCode} ${response.body}');
        return const OtpVerifyResult(
          success: false,
          error: 'OTP verification failed. Please retry.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (decoded['status'] as String?)?.toLowerCase() ?? '';
      if (status != 'approved') {
        return const OtpVerifyResult(success: false, error: 'Invalid OTP.');
      }

      return const OtpVerifyResult(success: true);
    } catch (error) {
      debugPrint('Twilio verify OTP exception: $error');
      return const OtpVerifyResult(
        success: false,
        error: 'Unable to verify OTP. Check network and retry.',
      );
    }
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  String? _toE164(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.length >= 11 && digits.length <= 15) {
      return '+$digits';
    }
    return null;
  }

  String _generateOtp() {
    final code = _random.nextInt(900000) + 100000;
    return code.toString();
  }
}
