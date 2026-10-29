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
    bool confirmed = true,
  });
}
