import 'supabase_config.dart';

/// Rewrites a Supabase Storage public URL to go through the CDN host when one
/// is configured via --dart-define=CDN_BASE_URL=https://img.yourdomain.com
///
/// If no CDN is configured the original Supabase URL is returned unchanged so
/// the app works out-of-the-box without any CDN setup.
///
/// Cloudflare setup (one-time, no code changes needed after):
///   1. Add your domain to Cloudflare (free plan is fine).
///   2. Create a CNAME:  img.yourdomain.com  →  <project>.supabase.co
///   3. Add a Cache Rule in Cloudflare:
///        URL pattern : img.yourdomain.com/*
///        Cache       : Cache Everything
///        Edge TTL    : 1 month
///        Browser TTL : 7 days
///   4. Build the app with:
///        --dart-define=CDN_BASE_URL=https://img.yourdomain.com  (no angle brackets needed)
///
/// Images served through CDN do NOT need the Supabase apikey header because
/// Cloudflare caches the public-bucket response and serves it directly.
class CdnConfig {
  static const String _cdnBaseFromEnv =
      String.fromEnvironment('CDN_BASE_URL');

  /// True when a CDN host has been configured at build time.
  static bool get hasCdn => _cdnBaseFromEnv.isNotEmpty;

  /// Rewrites [url] to use the CDN host when available.
  /// Returns [url] unchanged if no CDN is configured or the URL is not a
  /// Supabase Storage public URL for the current project.
  static String rewrite(String url) {
    if (url.isEmpty) return url;
    if (!hasCdn) return url;

    final supabaseHost = Uri.tryParse(SupabaseConfig.url)?.host ?? '';
    if (supabaseHost.isEmpty) return url;

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != supabaseHost) return url;
    if (!uri.path.startsWith('/storage/v1/object/public/')) return url;

    return url.replaceFirst(
      '${uri.scheme}://${uri.host}',
      _cdnBaseFromEnv.endsWith('/')
          ? _cdnBaseFromEnv.substring(0, _cdnBaseFromEnv.length - 1)
          : _cdnBaseFromEnv,
    );
  }

  /// HTTP headers to attach when fetching [url].
  /// CDN URLs are public — no apikey needed (and Cloudflare won't cache
  /// requests that carry custom headers by default).
  /// Supabase direct URLs still get the apikey header.
  static Map<String, String> headersFor(String url) {
    if (hasCdn && url.startsWith(_cdnBaseFromEnv)) {
      return const <String, String>{};
    }
    return <String, String>{'apikey': SupabaseConfig.anonKey};
  }
}
