import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/friend.dart';
import '../domain/friend_activity.dart';
import '../domain/friend_standing.dart';
import 'community_repository.dart';

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client);

  final SupabaseClient _client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('You must be signed in.');
    return id;
  }

  static List<Map<String, dynamic>> _rows(dynamic result) {
    if (result is List) {
      return result
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  Future<List<Friend>> friendships() async {
    final result = await _client.rpc<dynamic>('my_friendships');

    return _rows(result).map(Friend.fromJson).toList(growable: false);
  }

  @override
  Future<void> sendFriendRequest(String email) async {
    await _client.rpc<dynamic>(
      'send_friend_request',
      params: {'p_email': email.trim()},
    );
  }

  @override
  Future<void> respondToRequest({
    required String requesterId,
    required bool accept,
  }) async {
    await _client.rpc<dynamic>(
      'respond_to_friend_request',
      params: {'p_requester': requesterId, 'p_accept': accept},
    );
  }

  /// Deleting either direction is enough; RLS allows only rows you are part of.
  @override
  Future<void> removeFriend(String golferId) async {
    final me = _currentUserId;

    await _client
        .from('friendships')
        .delete()
        .eq('requester_id', me)
        .eq('addressee_id', golferId);

    await _client
        .from('friendships')
        .delete()
        .eq('requester_id', golferId)
        .eq('addressee_id', me);
  }

  @override
  Future<List<FriendActivity>> activity({int limit = 25}) async {
    final result = await _client.rpc<dynamic>(
      'friend_activity',
      params: {'p_limit': limit},
    );

    return _rows(result).map(FriendActivity.fromJson).toList(growable: false);
  }

  @override
  Future<List<FriendStanding>> standings({DateTime? since}) async {
    final result = await _client.rpc<dynamic>(
      'friends_leaderboard',
      params: {
        if (since != null) 'p_since': since.toUtc().toIso8601String(),
      },
    );

    return _rows(result).map(FriendStanding.fromJson).toList(growable: false);
  }
}
