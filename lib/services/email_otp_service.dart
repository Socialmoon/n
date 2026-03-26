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
  final Map<String, OtpCache> _cache = <String, OtpCache>{};

  EmailOtpService._internal();

  factory EmailOtpService() {
    return _instance;
  }

  /// Generate and send OTP to email
  Future<EmailOtpResult> sendVerificationOtp(String email) async {
    if (!_isValidEmail(email)) {
      return const EmailOtpResult(error: 'Invalid email address.');
    }

    try {
      // Generate 6-digit OTP
      final otp = _generateOtp();
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Cache OTP with 10-minute expiry
      _cache[email] = OtpCache(
        otp: otp,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      // In production, call actual email service (SendGrid, AWS SES, etc.)
      // For now, log it
      print('📧 OTP for $email: $otp');

      return EmailOtpResult(
        success: true,
        transactionId: transactionId,
      );
    } catch (e) {
      return EmailOtpResult(error: 'Failed to send OTP: $e');
    }
  }

  /// Verify OTP for email
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!_isValidEmail(email)) {
      return false;
    }

    final cached = _cache[email];
    if (cached == null) {
      return false;
    }

    if (DateTime.now().isAfter(cached.expiresAt)) {
      _cache.remove(email);
      return false;
    }

    if (cached.otp != otp.trim()) {
      return false;
    }

    // OTP verified, remove from cache
    _cache.remove(email);
    return true;
  }

  /// Check if email verification is pending
  bool isPending(String email) {
    if (!_isValidEmail(email)) {
      return false;
    }
    final cached = _cache[email];
    if (cached == null) {
      return false;
    }
    return DateTime.now().isBefore(cached.expiresAt);
  }

  /// Clear cached OTP
  void clearCache(String email) {
    _cache.remove(email);
  }

  String _generateOtp() {
    final random = DateTime.now().millisecond % 1000000;
    return random.toString().padLeft(6, '0');
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }
}

class OtpCache {
  OtpCache({
    required this.otp,
    required this.createdAt,
    required this.expiresAt,
  });

  final String otp;
  final DateTime createdAt;
  final DateTime expiresAt;
}
