import '../domain/hole_score.dart';

abstract class ScoreRepository {
  Stream<List<HoleScore>> watchScores(String roundId);

  Stream<List<HoleScore>> watchMyScores(String roundId);

  Future<List<HoleScore>> myScoresForRounds(Iterable<String> roundIds);

  Future<void> saveMyScore({
    required String roundId,
    required int holeNumber,
    required int strokes,
    required int putts,
    required int penaltyStrokes,
    int sandShots = 0,
    String? fairway,
    bool? greenInRegulation,
    bool confirmed = true,
  });

  /// Captures a score for another player. It remains provisional until that
  /// player confirms it; the server checks both players' round membership.
  Future<void> saveGroupScore({
    required String roundId,
    required String playerId,
    required int holeNumber,
    required int strokes,
    required int putts,
    required int penaltyStrokes,
    required bool expectedExists,
    DateTime? expectedUpdatedAt,
    int sandShots = 0,
    String? fairway,
    bool? greenInRegulation,
  });
}
