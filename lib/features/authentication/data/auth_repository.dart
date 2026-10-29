import '../../../core/auth/christian_golfer_user.dart';

/// What the app needs from an authentication provider.
///
/// [SupabaseAuthRepository] is the real one; the demo backend supplies its own.
abstract class AuthRepository {
  ChristianGolferUser? get currentUser;

  String? get currentUserId => currentUser?.id;

  Stream<ChristianGolferUser?> authStateChanges();

  Future<void> signInWithGoogle();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithPassword({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> updateDisplayName(String displayName);

  Future<void> signOut();
}
