/// Build-time Supabase configuration.
///
/// Values are injected at build time, never committed:
///
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
///
/// On Vercel the same values come from the project's environment variables
/// (see scripts/vercel_build.sh).
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// The client-side key. Supabase now calls this the *publishable* key; older
  /// projects issue it as the *anon* key. Either works, and either is safe to
  /// ship in the app - row level security is what protects the data.
  ///
  /// SUPABASE_PUBLISHABLE_KEY wins if both are set.
  // Const expressions may not call `isNotEmpty`, but they may compare with
  // `==`, so the fallback is written that way.
  static const String _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String publishableKey =
      _publishableKey == '' ? _anonKey : _publishableKey;

  /// Where Supabase sends the golfer back to after Google sign-in.
  ///
  /// Leave empty on web and the app uses the current origin, which is what you
  /// want for both `localhost` and the Vercel deployment. Set it explicitly for
  /// mobile builds, e.g. `com.christiangolfers.capetown://login-callback`.
  static const String redirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static String? get redirectUrlOrNull =>
      redirectUrl.isEmpty ? null : redirectUrl;
}
