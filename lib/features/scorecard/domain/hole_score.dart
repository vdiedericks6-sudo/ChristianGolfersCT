import '../../../core/data/json_parsing.dart';

class HoleScore {
  const HoleScore({
    required this.roundId,
    required this.playerId,
    required this.holeNumber,
    required this.strokes,
    required this.putts,
    required this.penaltyStrokes,
    required this.confirmed,
    this.updatedAt,
  });

  final String roundId;
  final String playerId;
  final int holeNumber;
  final int strokes;
  final int putts;
  final int penaltyStrokes;
  final bool confirmed;
  final DateTime? updatedAt;

  int get totalStrokes => strokes + penaltyStrokes;

  factory HoleScore.fromJson(Json data) {
    return HoleScore(
      roundId: asString(data['round_id']),
      playerId: asString(data['player_id']),
      holeNumber: asInt(data['hole_number']),
      strokes: asInt(data['strokes']),
      putts: asInt(data['putts']),
      penaltyStrokes: asInt(data['penalty_strokes']),
      confirmed: asBool(data['confirmed']),
      updatedAt: asDateOrNull(data['updated_at']),
    );
  }
}
