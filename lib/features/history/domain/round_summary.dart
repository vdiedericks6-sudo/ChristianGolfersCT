import '../../rounds/domain/golf_round.dart';
import '../../scorecard/domain/hole_score.dart';

/// How a hole was scored relative to its par.
enum ScoreClass { eagleOrBetter, birdie, par, bogey, doubleOrWorse }

/// One golfer's card for one round, with everything the history and stats
/// screens need already worked out.
class RoundSummary {
  const RoundSummary({
    required this.round,
    required this.myScores,
    required this.holePars,
    this.coursePar,
  });

  final GolfRound round;

  /// Only the signed-in golfer's scores, any order.
  final List<HoleScore> myScores;

  /// Hole number to par, for the course this round was played on. May be empty
  /// when the course has no hole data captured.
  final Map<int, int> holePars;

  /// Total par for the course, when known.
  final int? coursePar;

  int get holesPlayed => myScores.length;

  bool get isFullRound => holesPlayed >= 18;

  /// Strokes including penalties.
  int get grossStrokes =>
      myScores.fold<int>(0, (total, score) => total + score.totalStrokes);

  int get putts =>
      myScores.fold<int>(0, (total, score) => total + score.putts);

  int get penalties =>
      myScores.fold<int>(0, (total, score) => total + score.penaltyStrokes);

  /// Par for the holes actually played, or null if any of them is unknown.
  int? get parForHolesPlayed {
    if (holePars.isEmpty) return null;

    var total = 0;
    for (final score in myScores) {
      final par = holePars[score.holeNumber];
      if (par == null) return null;
      total += par;
    }
    return total;
  }

  /// Strokes over (or under) par. Falls back to the course total when the
  /// round is complete but per-hole pars are missing.
  int? get toPar {
    final measured = parForHolesPlayed;
    if (measured != null) return grossStrokes - measured;

    final total = coursePar;
    if (total != null && isFullRound) return grossStrokes - total;

    return null;
  }

  ScoreClass? classify(HoleScore score) {
    final par = holePars[score.holeNumber];
    if (par == null) return null;

    final diff = score.totalStrokes - par;

    if (diff <= -2) return ScoreClass.eagleOrBetter;
    if (diff == -1) return ScoreClass.birdie;
    if (diff == 0) return ScoreClass.par;
    if (diff == 1) return ScoreClass.bogey;
    return ScoreClass.doubleOrWorse;
  }

  Map<ScoreClass, int> get breakdown {
    final counts = <ScoreClass, int>{};
    for (final score in myScores) {
      final label = classify(score);
      if (label == null) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  DateTime get playedAt =>
      round.completedAt ??
      round.startedAt ??
      round.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
