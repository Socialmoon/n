class SupabaseConfig {
  static const String _defaultUrl =
    'https://mpfzclgtdworikwqwzea.supabase.co';
  static const String _defaultAnonKey =
    'sb_publishable_nmR5V3k5WXT5hgI6fiCztg_8OS4i4ce';

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