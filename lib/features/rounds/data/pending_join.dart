import 'package:shared_preferences/shared_preferences.dart';

import 'round_link.dart';

/// Remembers a join code across the Google sign-in redirect.
///
/// On the web, signing in navigates the tab away to Google and back to the
/// site root, so anything held in memory is gone by the time the golfer
/// returns. The code they tapped has to outlive that round trip.
class PendingJoin {
  const PendingJoin._();

  static const _key = 'christian_golfers.pending_join_code';

  static Future<void> remember(String joinCode) async {
    final code = RoundLink.normalise(joinCode);
    if (code.length != RoundLink.codeLength) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, code);
  }

  /// Returns the stored code and forgets it, so a join is never replayed.
  static Future<String?> take() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_key);

    if (code != null) await preferences.remove(_key);

    return code;
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
