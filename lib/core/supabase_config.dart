class SupabaseConfig {
   static const String _defaultUrl =
    'https://iuhecyqizatkiskoznwq.supabase.co';
  static const String _defaultAnonKey =
    'sb_publishable_3IwWvcVPJLQyaprQBdTXMw_zUi-lpC6';

  static const String _urlFromEnv = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKeyFromEnv =
    String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _urlFromEnv.isNotEmpty ? _urlFromEnv : _defaultUrl;
  static String get anonKey =>
    _anonKeyFromEnv.isNotEmpty ? _anonKeyFromEnv : _defaultAnonKey;

  static bool get isConfigured {
    return url.isNotEmpty && anonKey.isNotEmpty;
  }
}