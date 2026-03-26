import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/supabase_config.dart';

class EmailOtpResult {
  const EmailOtpResult({
    this.success = false,
    this.error,
    this.transactionId,
  });

  final bool success;
  final String? error;
  final String? transactionId;
}

class EmailOtpService {
  static final EmailOtpService _instance = EmailOtpService._internal();

  EmailOtpService._internal();

  factory EmailOtpService() {
    return _instance;
  }

  static final Uri _sendEmailOtpUri =
      Uri.parse('${SupabaseConfig.url}/functions/v1/send-email-otp');
  static final Uri _verifyEmailOtpUri =
      Uri.parse('${SupabaseConfig.url}/functions/v1/verify-email-otp');

  /// Send OTP to email using server-side Gmail SMTP.
  Future<EmailOtpResult> sendVerificationOtp(String email) async {
    if (!_isValidEmail(email)) {
      return const EmailOtpResult(error: 'Invalid email address.');
    }

    if (!SupabaseConfig.isConfigured) {
      return const EmailOtpResult(
        error: 'Supabase is not configured for email OTP.',
      );
    }

    try {
      final response = await http.post(
        _sendEmailOtpUri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.anonKey,
        },
        body: jsonEncode(<String, dynamic>{
          'email': email.trim(),
        }),
      );

      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(response.body) as Map<String, dynamic>);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmailOtpResult(
          success: true,
          transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }

        final errorMessage = body['error'] as String?;
        final detailsMessage = body['details'] as String?;
        final serverMessage =
          (errorMessage == 'Failed to send OTP email' &&
            detailsMessage != null &&
            detailsMessage.isNotEmpty)
          ? 'Failed to send OTP email: $detailsMessage'
          : errorMessage ??
            (body['message'] as String?) ??
            detailsMessage;

      return EmailOtpResult(
        error: serverMessage ??
            'Unable to send OTP email right now (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      return EmailOtpResult(error: 'Failed to send OTP: $e');
    }
  }

  /// Verify OTP via server-side function.
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!_isValidEmail(email) || otp.trim().length != 6) {
      return false;
    }

    if (!SupabaseConfig.isConfigured) {
      return false;
    }

    try {
      final response = await http.post(
        _verifyEmailOtpUri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.anonKey,
        },
        body: jsonEncode(<String, dynamic>{
          'email': email.trim(),
          'otp': otp.trim(),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Pending state is managed server-side; this returns false by design.
  bool isPending(String email) {
    return false;
  }

  /// No local cache when using server-side OTP.
  void clearCache(String email) {
    // no-op
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }
}
