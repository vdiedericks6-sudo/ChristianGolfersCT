import '../../../core/data/json_parsing.dart';

class RoundPlayer {
  const RoundPlayer({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.active,
    this.handicapIndex,
    this.courseHandicap,
    this.playingHandicap,
    this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String role;
  final bool active;
  final double? handicapIndex;
  final int? courseHandicap;
  final int? playingHandicap;
  final DateTime? joinedAt;

  bool get isHost => role == 'host';

  factory RoundPlayer.fromJson(Json data) {
    return RoundPlayer(
      userId: asString(data['user_id']),
      displayName: asString(data['display_name'], 'Golfer'),
      role: asString(data['role'], 'player'),
      active: asBool(data['active'], true),
      handicapIndex: asDoubleOrNull(data['handicap_index']),
      courseHandicap: asIntOrNull(data['course_handicap']),
      playingHandicap: asIntOrNull(data['playing_handicap']),
      joinedAt: asDateOrNull(data['joined_at']),
    );
  }
}
