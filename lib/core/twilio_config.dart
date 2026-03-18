class TwilioConfig {
  static const String _accountSidFromEnv =
      String.fromEnvironment('TWILIO_ACCOUNT_SID');
  static const String _authTokenFromEnv =
      String.fromEnvironment('TWILIO_AUTH_TOKEN');
  static const String _verifyServiceSidFromEnv =
      String.fromEnvironment('TWILIO_VERIFY_SERVICE_SID');

  static String get accountSid => _accountSidFromEnv;
  static String get authToken => _authTokenFromEnv;
  static String get verifyServiceSid => _verifyServiceSidFromEnv;

  static bool get isConfigured {
    return accountSid.isNotEmpty &&
        authToken.isNotEmpty &&
        verifyServiceSid.isNotEmpty;
  }
}
