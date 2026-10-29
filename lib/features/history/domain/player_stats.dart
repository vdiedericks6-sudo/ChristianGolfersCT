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
    for (final summary in completed) {
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
      averagePutts: mean(
        full
            .where((summary) => summary.putts > 0)
            .map((summary) => summary.putts),
      ),
      breakdown: breakdown,
      recentAverage: recentAverage,
      trend: (scoringAverage == null || recentAverage == null || full.length < 3)
          ? null
          : recentAverage - scoringAverage,
    );
  }
}
