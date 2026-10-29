import '../../courses/domain/golf_hole.dart';
import '../../courses/domain/tee_set.dart';
import '../../handicap/domain/handicap_calculator.dart';
import '../../rounds/domain/round_player.dart';
import '../../scorecard/domain/hole_score.dart';
import 'leaderboard_entry.dart';

/// [net] is the primary Christian Golfers competition format (net stroke play).
/// [gross] is retained as a secondary reference view.
enum LeaderboardMode { net, gross }

class LeaderboardCalculator {
  const LeaderboardCalculator._();

  static List<LeaderboardEntry> calculate({
    required List<RoundPlayer> players,
    required List<HoleScore> scores,
    required List<GolfHole> holes,
    required TeeSet? teeSet,
    required LeaderboardMode mode,
    required String? currentUserId,
  }) {
    final holeMap = {for (final hole in holes) hole.number: hole};

    final entries = <LeaderboardEntry>[];

    for (final player in players.where((player) => player.active)) {
      final playerScores =
          scores
              .where(
                (score) =>
                    score.playerId == player.userId &&
                    score.confirmed &&
                    holeMap.containsKey(score.holeNumber),
              )
              .toList()
            ..sort((a, b) => a.holeNumber.compareTo(b.holeNumber));

      final courseHandicap = player.handicapIndex != null && teeSet != null
          ? HandicapCalculator.courseHandicap(
              handicapIndex: player.handicapIndex!,
              slopeRating: teeSet.slopeRating,
              courseRating: teeSet.courseRating,
              par: teeSet.par,
            )
          : 0;

      final playingHandicap = HandicapCalculator.playingHandicap(
        courseHandicap: courseHandicap,
      );

      var grossTotal = 0;
      var netTotal = 0;
      var parTotal = 0;

      for (final score in playerScores) {
        final hole = holeMap[score.holeNumber];
        if (hole == null) continue;

        final gross = score.totalStrokes;
        final received = HandicapCalculator.strokesReceivedOnHole(
          playingHandicap: playingHandicap,
          strokeIndex: hole.strokeIndex,
        );
        final net = HandicapCalculator.netHoleScore(
          grossScore: gross,
          strokesReceived: received,
        );

        grossTotal += gross;
        netTotal += net;
        parTotal += hole.par;
      }

      entries.add(
        LeaderboardEntry(
          playerId: player.userId,
          displayName: player.displayName,
          holesCompleted: playerScores.length,
          grossTotal: grossTotal,
          netTotal: netTotal,
          grossToPar: grossTotal - parTotal,
          netToPar: netTotal - parTotal,
          position: 0,
          isCurrentUser: player.userId == currentUserId,
        ),
      );
    }

    entries.sort((a, b) {
      final scoreA = mode == LeaderboardMode.net ? a.netToPar : a.grossToPar;
      final scoreB = mode == LeaderboardMode.net ? b.netToPar : b.grossToPar;

      final completedCompare = b.holesCompleted.compareTo(a.holesCompleted);

      if (a.holesCompleted != b.holesCompleted) {
        return completedCompare;
      }

      final scoreCompare = scoreA.compareTo(scoreB);
      if (scoreCompare != 0) return scoreCompare;

      final totalA = mode == LeaderboardMode.net ? a.netTotal : a.grossTotal;
      final totalB = mode == LeaderboardMode.net ? b.netTotal : b.grossTotal;

      final totalCompare = totalA.compareTo(totalB);
      if (totalCompare != 0) return totalCompare;

      return a.displayName.compareTo(b.displayName);
    });

    final ranked = <LeaderboardEntry>[];
    var currentPosition = 0;
    int? previousScore;
    int? previousHoles;
    int? previousTotal;

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final score = mode == LeaderboardMode.net
          ? entry.netToPar
          : entry.grossToPar;
      final total = mode == LeaderboardMode.net
          ? entry.netTotal
          : entry.grossTotal;

      final tiedWithPrevious =
          index > 0 &&
          previousScore == score &&
          previousHoles == entry.holesCompleted &&
          previousTotal == total;

      if (!tiedWithPrevious) {
        currentPosition = index + 1;
      }

      ranked.add(entry.copyWith(position: currentPosition));

      previousScore = score;
      previousHoles = entry.holesCompleted;
      previousTotal = total;
    }

    return ranked;
  }
}
