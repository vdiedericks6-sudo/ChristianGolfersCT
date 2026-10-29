import '../../../core/data/json_parsing.dart';

class HoleScore {
  const HoleScore({
    required this.roundId,
    required this.playerId,
    required this.holeNumber,
    required this.strokes,
    required this.putts,
    required this.penaltyStrokes,
    this.sandShots = 0,
    this.fairway,
    this.greenInRegulation,
    required this.confirmed,
    this.updatedAt,
  });

  final String roundId;
  final String playerId;
  final int holeNumber;
  final int strokes;
  final int putts;
  final int penaltyStrokes;
  final int sandShots;
  final String? fairway;
  final bool? greenInRegulation;
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
      sandShots: asInt(data['sand_shots']),
      fairway: data['fairway'] as String?,
      greenInRegulation: data['green_in_regulation'] as bool?,
      confirmed: asBool(data['confirmed']),
      updatedAt: asDateOrNull(data['updated_at']),
    );
  }
}
