import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/christian_golfer_user.dart';
import '../../../core/supabase/supabase_config.dart';
import 'auth_repository.dart';

/// Google-only authentication on top of Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static ChristianGolferUser? _toChristianGolferUser(User? user) {
    if (user == null) return null;

    final metadata = user.userMetadata ?? const <String, dynamic>{};

    String? text(String key) {
      final value = metadata[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return ChristianGolferUser(
      id: user.id,
      email: user.email,
      displayName: text('full_name') ?? text('name'),
      photoUrl: text('avatar_url') ?? text('picture'),
    );
  }

  @override
  ChristianGolferUser? get currentUser => _toChristianGolferUser(_auth.currentUser);

  @override
  String? get currentUserId => _auth.currentUser?.id;

  /// Emits the signed-in golfer (or null) starting with the session that was
  /// restored during `Supabase.initialize`.
  @override
  Stream<ChristianGolferUser?> authStateChanges() async* {
    yield currentUser;
    yield* _auth.onAuthStateChange.map(
      (state) => _toChristianGolferUser(state.session?.user),
    );
  }

  /// Starts the Google OAuth flow.
  ///
  /// On web this redirects the tab to Google and back to [redirectTo]; the
  /// session is picked up automatically when the app reloads. On mobile it
  /// opens an external browser and returns through the deep link.
  @override
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.redirectUrlOrNull,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  @override
  Future<void> signInWithPassword({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    await _auth.updateUser(UserAttributes(data: {'full_name': trimmed}));
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
