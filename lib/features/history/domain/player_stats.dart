import 'round_summary.dart';

/// Career numbers derived from a golfer's completed rounds.
///
/// Pure and dependency-free so it can be unit tested without a backend.
class PlayerStats {
  const PlayerStats({
    required this.roundsPlayed,
    required this.fullRoundsPlayed,
    required this.scoringAverage,
    required this.bestGross,
    required this.bestToPar,
    required this.averagePutts,
    required this.breakdown,
    required this.recentAverage,
    required this.trend,
    required this.fairwaysHit,
    required this.fairwaysRecorded,
    required this.greensHit,
    required this.greensRecorded,
  });

  /// Every completed round, including any cut short.
  final int roundsPlayed;

  /// Rounds where all 18 holes were entered; the ones averages are built from.
  final int fullRoundsPlayed;

  /// Mean gross score over full rounds, or null with nothing to average.
  final double? scoringAverage;

  final int? bestGross;
  final int? bestToPar;

  /// Mean putts per full round.
  final double? averagePutts;

  final Map<ScoreClass, int> breakdown;

  /// Mean gross over the five most recent full rounds.
  final double? recentAverage;

  /// Recent average minus overall average. Negative means improving.
  final double? trend;

  final int fairwaysHit;
  final int fairwaysRecorded;
  final int greensHit;
  final int greensRecorded;

  bool get isEmpty => roundsPlayed == 0;

  static const empty = PlayerStats(
    roundsPlayed: 0,
    fullRoundsPlayed: 0,
    scoringAverage: null,
    bestGross: null,
    bestToPar: null,
    averagePutts: null,
    breakdown: <ScoreClass, int>{},
    recentAverage: null,
    trend: null,
    fairwaysHit: 0,
    fairwaysRecorded: 0,
    greensHit: 0,
    greensRecorded: 0,
  );

  factory PlayerStats.from(List<RoundSummary> summaries) {
    final completed = summaries
        .where((summary) => summary.round.isCompleted && summary.holesPlayed > 0)
        .toList();

    if (completed.isEmpty) return empty;

    // Newest first, so "recent" means what it says.
    completed.sort((a, b) => b.playedAt.compareTo(a.playedAt));

    final full = completed.where((summary) => summary.isFullRound).toList();

    double? mean(Iterable<int> values) {
      final list = values.toList();
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final scoringAverage = mean(full.map((summary) => summary.grossStrokes));
    final recentAverage = mean(
      full.take(5).map((summary) => summary.grossStrokes),
    );

    int? lowest(Iterable<int?> values) {
      final list = values.whereType<int>().toList();
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a < b ? a : b);
    }

    final breakdown = <ScoreClass, int>{};
    var fairwaysHit = 0;
    var fairwaysRecorded = 0;
    var greensHit = 0;
    var greensRecorded = 0;
    for (final summary in completed) {
      for (final score in summary.myScores) {
        final par = summary.holePars[score.holeNumber];
        if (par != null && par > 3 && score.fairway != null) {
          fairwaysRecorded++;
          if (score.fairway == 'hit') fairwaysHit++;
        }
        if (score.greenInRegulation != null) {
          greensRecorded++;
          if (score.greenInRegulation == true) greensHit++;
        }
      }
      summary.breakdown.forEach((label, count) {
        breakdown[label] = (breakdown[label] ?? 0) + count;
      });
    }

    return PlayerStats(
      roundsPlayed: completed.length,
      fullRoundsPlayed: full.length,
      scoringAverage: scoringAverage,
      bestGross: lowest(full.map((summary) => summary.grossStrokes)),
      bestToPar: lowest(full.map((summary) => summary.toPar)),
      averagePutts: mean(full.map((summary) => summary.putts)),
      fairwaysHit: fairwaysHit,
      fairwaysRecorded: fairwaysRecorded,
      greensHit: greensHit,
      greensRecorded: greensRecorded,
      breakdown: breakdown,
      recentAverage: recentAverage,
      trend: (scoringAverage == null || recentAverage == null || full.length < 3)
          ? null
          : recentAverage - scoringAverage,
    );
  }
}
