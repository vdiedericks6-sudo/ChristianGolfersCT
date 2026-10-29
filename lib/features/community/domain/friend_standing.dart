import '../../../core/data/json_parsing.dart';

/// A row of the season leaderboard among friends.
class FriendStanding {
  const FriendStanding({
    required this.golferId,
    required this.displayName,
    required this.roundsPlayed,
    required this.bestGross,
    required this.averageGross,
    this.photoUrl,
  });

  final String golferId;
  final String displayName;
  final int roundsPlayed;
  final int bestGross;
  final double averageGross;
  final String? photoUrl;

  factory FriendStanding.fromJson(Json data) {
    return FriendStanding(
      golferId: asString(data['golfer_id']),
      displayName: asString(data['display_name'], 'Christian Golfer'),
      photoUrl: asStringOrNull(data['photo_url']),
      roundsPlayed: asInt(data['rounds_played']),
      bestGross: asInt(data['best_gross']),
      averageGross: asDouble(data['average_gross']),
    );
  }
}
