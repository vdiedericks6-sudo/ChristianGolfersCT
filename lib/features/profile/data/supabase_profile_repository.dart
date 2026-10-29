import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/christian_golfer_user.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _profiles => _client.from('profiles');

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _profiles
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfile.fromJson(rows.first));
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final row = await _profiles.select().eq('id', userId).maybeSingle();

    if (row == null) return null;

    return UserProfile.fromJson(row);
  }

  @override
  Future<void> ensureProfileExists(ChristianGolferUser user) async {
    await _profiles.upsert({
      'id': user.id,
      'display_name': user.bestName,
      'email': user.email ?? '',
      'photo_url': user.photoUrl,
    }, onConflict: 'id', ignoreDuplicates: true);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String displayName,
    required String preferredDistanceUnit,
  }) {
    return _profiles.update({
      'display_name': displayName.trim(),
      'preferred_distance_unit': preferredDistanceUnit,
    }).eq('id', userId);
  }
}
