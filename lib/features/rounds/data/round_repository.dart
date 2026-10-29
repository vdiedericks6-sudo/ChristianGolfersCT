import '../../courses/domain/golf_course.dart';
import '../../courses/domain/tee_set.dart';
import '../domain/golf_round.dart';
import '../domain/round_player.dart';

abstract class RoundRepository {
  Future<String> createRound({
    required GolfCourse course,
    required TeeSet teeSet,
  });

  Future<String> joinRoundByCode(String rawCode);

  Stream<GolfRound?> watchRound(String roundId);

  Stream<List<RoundPlayer>> watchPlayers(String roundId);

  /// Every round the signed-in golfer has taken part in, newest first.
  Future<List<GolfRound>> myRounds({int limit = 50});

  Future<void> startRound(String roundId);

  Future<void> setCurrentHole({
    required String roundId,
    required int holeNumber,
  });

  Future<void> completeRound(String roundId);
}
