import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/supabase_config.dart';

class OtpDispatchResult {
  const OtpDispatchResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
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
  static const String _sendOtpFunction = 'send-otp';
  static const String _verifyOtpFunction = 'verify-otp';

  Future<OtpDispatchResult> sendOtp(String mobileNumber) async {
    final normalized = _normalizeMobile(mobileNumber);
    if (normalized.length != 10) {
      return const OtpDispatchResult(
        success: false,
        error: 'Enter a valid 10 digit mobile number.',
      );
    }

    if (!SupabaseConfig.isConfigured) {
      return const OtpDispatchResult(
        success: false,
        error: 'OTP service is not configured.',
      );
    }

    final uri = Uri.parse('${SupabaseConfig.url}/functions/v1/$_sendOtpFunction');

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{'mobileNumber': normalized}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractErrorMessage(response.body) ?? 'Failed to send OTP. Please try again.';
        return OtpDispatchResult(
          success: false,
          error: message,
        );
      }

      return const OtpDispatchResult(success: true);
    } catch (error) {
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

    if (!SupabaseConfig.isConfigured) {
      return const OtpVerifyResult(
        success: false,
        error: 'OTP service is not configured.',
      );
    }

    final uri = Uri.parse('${SupabaseConfig.url}/functions/v1/$_verifyOtpFunction');

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'mobileNumber': normalized,
          'otp': otp,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractErrorMessage(response.body) ?? 'OTP verification failed. Please retry.';
        return OtpVerifyResult(
          success: false,
          error: message,
        );
      }

      return const OtpVerifyResult(success: true);
    } catch (error) {
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

  String? _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore JSON parse issues and fall back to defaults.
    }
    return null;
  }
}
