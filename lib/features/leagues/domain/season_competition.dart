/// Competition divisions that receive separate round-point tables.
enum CompetitionDivision { leagueA, leagueB, social }

/// One golfer's result in a single competition round.
///
/// [netScore] is the validated net stroke-play total used to rank the round.
/// Only results marked both [completed] and [eligible] are awarded points.
class CompetitionRoundResult {
  const CompetitionRoundResult({
    required this.roundId,
    required this.playerId,
    required this.playerName,
    required this.division,
    required this.netScore,
    required this.completed,
    required this.eligible,
  });

  final String roundId;
  final String playerId;
  final String playerName;
  final CompetitionDivision division;
  final int netScore;
  final bool completed;
  final bool eligible;
}

class RoundPointAward {
  const RoundPointAward({
    required this.roundId,
    required this.playerId,
    required this.playerName,
    required this.division,
    required this.netScore,
    required this.position,
    required this.points,
  });

  final String roundId;
  final String playerId;
  final String playerName;
  final CompetitionDivision division;
  final int netScore;
  final int position;
  final int points;
}

class SeasonStanding {
  const SeasonStanding({
    required this.playerId,
    required this.playerName,
    required this.division,
    required this.totalPoints,
    required this.eligibleRounds,
    required this.countedRoundPoints,
  });

  final String playerId;
  final String playerName;
  final CompetitionDivision division;

  /// During the season this includes every eligible completed round.
  /// At season close this is the sum of the best [countedRoundPoints].
  final int totalPoints;
  final int eligibleRounds;
  final List<int> countedRoundPoints;
}

/// The recommended Christian Golfers competition points schedule.
class CompetitionPointsSchedule {
  const CompetitionPointsSchedule._();

  static const Map<int, int> _pointsByPosition = <int, int>{
    1: 40,
    2: 35,
    3: 32,
    4: 30,
    5: 28,
    6: 26,
    7: 24,
    8: 22,
    9: 20,
    10: 18,
    11: 16,
    12: 14,
    13: 12,
    14: 10,
    15: 8,
    16: 6,
    17: 5,
    18: 4,
    19: 3,
    20: 2,
  };

  static int pointsForPosition(int position) {
    if (position < 1) throw ArgumentError.value(position, 'position');
    return _pointsByPosition[position] ?? 1;
  }
}

/// Calculates points from net stroke-play round results.
///
/// Live standings total points from every eligible completed round. Final
/// standings retain each golfer's best seven round-point awards. A tie in net
/// score shares the points for the tied finishing position and skips the next
/// position (for example: 1, 1, 3).
class SeasonCompetitionCalculator {
  const SeasonCompetitionCalculator._();

  static List<RoundPointAward> awardRoundPoints(
    Iterable<CompetitionRoundResult> results,
  ) {
    final grouped = <String, List<CompetitionRoundResult>>{};
    for (final result in results.where(
      (item) => item.completed && item.eligible,
    )) {
      final key = '${result.roundId}::${result.division.name}';
      grouped.putIfAbsent(key, () => <CompetitionRoundResult>[]).add(result);
    }

    final awards = <RoundPointAward>[];
    for (final group in grouped.values) {
      group.sort((a, b) {
        final scoreCompare = a.netScore.compareTo(b.netScore);
        if (scoreCompare != 0) return scoreCompare;
        return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
      });

      var position = 0;
      int? previousNetScore;
      for (var index = 0; index < group.length; index++) {
        final result = group[index];
        if (index == 0 || result.netScore != previousNetScore) {
          position = index + 1;
        }
        awards.add(
          RoundPointAward(
            roundId: result.roundId,
            playerId: result.playerId,
            playerName: result.playerName,
            division: result.division,
            netScore: result.netScore,
            position: position,
            points: CompetitionPointsSchedule.pointsForPosition(position),
          ),
        );
        previousNetScore = result.netScore;
      }
    }
    return awards;
  }

  static List<SeasonStanding> calculateLive(
    Iterable<CompetitionRoundResult> results, {
    required CompetitionDivision division,
  }) => _calculate(results, division: division, finalSeason: false, bestRounds: 7);

  static List<SeasonStanding> calculateFinal(
    Iterable<CompetitionRoundResult> results, {
    required CompetitionDivision division,
    int bestRounds = 7,
  }) {
    if (bestRounds < 1) throw ArgumentError.value(bestRounds, 'bestRounds');
    return _calculate(
      results,
      division: division,
      finalSeason: true,
      bestRounds: bestRounds,
    );
  }

  static List<SeasonStanding> _calculate(
    Iterable<CompetitionRoundResult> results, {
    required CompetitionDivision division,
    required bool finalSeason,
    required int bestRounds,
  }) {
    final awards = awardRoundPoints(results)
        .where((award) => award.division == division)
        .toList();
    final byPlayer = <String, List<RoundPointAward>>{};
    for (final award in awards) {
      byPlayer.putIfAbsent(award.playerId, () => <RoundPointAward>[]).add(award);
    }

    final standings = <SeasonStanding>[];
    for (final entry in byPlayer.entries) {
      final playerAwards = entry.value
        ..sort((a, b) => b.points.compareTo(a.points));
      final counted = finalSeason
          ? playerAwards.take(bestRounds).map((award) => award.points).toList()
          : playerAwards.map((award) => award.points).toList();
      standings.add(
        SeasonStanding(
          playerId: entry.key,
          playerName: playerAwards.first.playerName,
          division: division,
          totalPoints: counted.fold<int>(0, (sum, points) => sum + points),
          eligibleRounds: playerAwards.length,
          countedRoundPoints: List<int>.unmodifiable(counted),
        ),
      );
    }

    standings.sort((a, b) {
      final pointsCompare = b.totalPoints.compareTo(a.totalPoints);
      if (pointsCompare != 0) return pointsCompare;
      // Equal totals are displayed alphabetically; this is not an extra
      // competition tie-break rule.
      return a.playerName.toLowerCase().compareTo(b.playerName.toLowerCase());
    });
    return standings;
  }
}
