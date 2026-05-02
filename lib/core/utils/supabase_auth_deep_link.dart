/// Deep links from Supabase Auth (magic link, OTP) use the app’s registered
/// redirect scheme. Maps those URIs to a [go_router] location.
const String kSupabaseWanderMoodAuthScheme = 'io.supabase.wandermood';

/// Returns `/auth-callback` with merged query string, or `null` if [uri] is not
/// an auth callback for this app.
///
/// Supabase may put parameters in the query (`?code=` PKCE) or in the fragment
/// (implicit-style tokens). Query keys override the same keys from the fragment.
String? supabaseAuthCallbackGoLocationFromUri(Uri uri) {
  if (uri.scheme != kSupabaseWanderMoodAuthScheme) return null;

  final host = uri.host.toLowerCase();
  var path = uri.path;
  if (path.isNotEmpty && !path.startsWith('/')) {
    path = '/$path';
  }

  final isAuthCallback = host == 'auth-callback' || path == '/auth-callback';

  if (!isAuthCallback) return null;

  final fragParams =
      uri.hasFragment ? Uri.splitQueryString(uri.fragment) : <String, String>{};
  final merged = <String, String>{...fragParams, ...uri.queryParameters};

  if (merged.isEmpty) return '/auth-callback';

  final qs = merged.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');
  return '/auth-callback?$qs';
}
