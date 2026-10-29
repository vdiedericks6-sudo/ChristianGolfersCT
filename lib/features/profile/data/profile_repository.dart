import '../../../core/auth/christian_golfer_user.dart';
import '../domain/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);

  Future<UserProfile?> getProfile(String userId);

  /// Safety net for accounts created before the auth trigger existed.
  Future<void> ensureProfileExists(ChristianGolferUser user);

  Future<void> updateProfile({
    required String userId,
    required String displayName,
    required String preferredDistanceUnit,
  });
}
