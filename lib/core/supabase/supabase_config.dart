/// Build-time Supabase configuration.
///
/// The project URL and publishable key identify the app's Supabase project and
/// are safe for a client build. A server-side secret/service-role key must
/// never be placed in this app. Build-time values can override the defaults:
///
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// On Vercel the same values come from the project's environment variables
/// (see scripts/vercel_build.sh).
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cegmyadsnrvzlgpwoezu.supabase.co',
  );

  /// The client-side key. Supabase now calls this the *publishable* key; older
  /// projects issue it as the *anon* key. Either works, and either is safe to
  /// ship in the app - row level security is what protects the data.
  ///
  /// SUPABASE_PUBLISHABLE_KEY wins if both are set.
  // Const expressions may not call `isNotEmpty`, but they may compare with
  // `==`, so the fallback is written that way.
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_1Z-I0Guja_HBIzSJxU32Pg_SLY5SOpP',
  );

  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String publishableKey = _publishableKey == ''
      ? _anonKey
      : _publishableKey;

  /// Where Supabase sends the golfer back to after Google sign-in.
  ///
  /// Mobile callback URI. Web sign-in leaves this null and returns to the
  /// current origin.
  static const String redirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'com.christiangolfers.capetown://login-callback',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static String? get redirectUrlOrNull =>
      redirectUrl.isEmpty ? null : redirectUrl;
}
