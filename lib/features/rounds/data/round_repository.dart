import '../../courses/domain/golf_course.dart';
import '../../courses/domain/tee_set.dart';
import '../domain/golf_round.dart';
import '../domain/round_player.dart';

abstract class RoundRepository {
  Future<String> createRound({
    required GolfCourse course,
    required TeeSet teeSet,
    int startingHole = 1,
  });

  Future<String> joinRoundByCode(String rawCode);

  Stream<GolfRound?> watchRound(String roundId);

  Stream<List<RoundPlayer>> watchPlayers(String roundId);

  /// Every round the signed-in golfer has taken part in, newest first.
  Future<List<GolfRound>> myRounds({int limit = 50});

  Future<void> startRound(String roundId);

  /// Each golfer chooses their own tee before their first score is recorded.
  Future<void> setMyRoundTee({required String roundId, required String teeSetId});

  Future<void> setCurrentHole({
    required String roundId,
    required int holeNumber,
  });

  Future<void> completeRound(String roundId);
}
