/// Build-time switches.
class AppConfig {
  const AppConfig._();

  /// Runs the app against an in-memory backend instead of Supabase.
  ///
  ///   flutter run -d chrome --dart-define=CHRISTIAN_GOLFERS_DEMO=true
  ///
  /// No network, no sign-in, no database — a seeded course, a round already in
  /// progress and three playing partners who keep posting scores.
  static const bool demoMode = bool.fromEnvironment('CHRISTIAN_GOLFERS_DEMO');

  /// Public origin used when building shareable round links, e.g.
  /// `https://christiangolfers.example`. Leave unset on web and the current origin is
  /// used, which is right for localhost and every Vercel preview alike.
  static const String publicBaseUrl = String.fromEnvironment('CHRISTIAN_GOLFERS_PUBLIC_URL');
}
