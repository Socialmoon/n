import 'supabase_config.dart';

/// HTTP headers required by Supabase storage for image fetches.
/// Even public buckets may require the API key header depending on
/// project configuration.
Map<String, String> supabaseImageHeaders() {
  return <String, String>{
    'apikey': SupabaseConfig.anonKey,
  };
}
