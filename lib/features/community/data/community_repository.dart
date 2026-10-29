import '../domain/friend.dart';
import '../domain/friend_activity.dart';
import '../domain/friend_standing.dart';

abstract class CommunityRepository {
  /// Accepted friends and open requests in both directions.
  Future<List<Friend>> friendships();

  /// Sends a request by email. Throws with a readable message when there is no
  /// Christian Golfers member at that address.
  Future<void> sendFriendRequest(String email);

  Future<void> respondToRequest({
    required String requesterId,
    required bool accept,
  });

  Future<void> removeFriend(String golferId);

  Future<List<FriendActivity>> activity({int limit = 25});

  Future<List<FriendStanding>> standings({DateTime? since});
}
