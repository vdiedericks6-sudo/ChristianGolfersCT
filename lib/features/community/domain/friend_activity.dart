import '../../../core/data/json_parsing.dart';

/// One completed round by someone in your crew.
///
/// Deliberately a summary: the feed shows what they shot, never their
/// hole-by-hole card. That stays private to the people who played with them.
class FriendActivity {
  const FriendActivity({
    required this.roundId,
    required this.golferId,
    required this.displayName,
    required this.courseName,
    required this.playedAt,
    required this.holes,
    required this.gross,
  });

  final String roundId;
  final String golferId;
  final String displayName;
  final String courseName;
  final DateTime playedAt;
  final int holes;
  final int gross;

  bool get isFullRound => holes >= 18;

  factory FriendActivity.fromJson(Json data) {
    return FriendActivity(
      roundId: asString(data['round_id']),
      golferId: asString(data['golfer_id']),
      displayName: asString(data['display_name'], 'Christian Golfer'),
      courseName: asString(data['course_name'], 'a round'),
      playedAt: asDate(data['played_at']),
      holes: asInt(data['holes']),
      gross: asInt(data['gross']),
    );
  }
}
