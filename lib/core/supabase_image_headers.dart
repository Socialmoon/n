import 'cdn_config.dart';

/// Returns the HTTP headers required to fetch [url].
/// - CDN URLs (Cloudflare): empty headers — public, no apikey needed.
/// - Supabase direct URLs: apikey header.
Map<String, String> supabaseImageHeaders([String url = '']) {
  return CdnConfig.headersFor(url);
}
