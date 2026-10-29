import 'package:christian_golfers/features/history/domain/player_stats.dart';
import 'package:christian_golfers/features/history/domain/round_summary.dart';
import 'package:christian_golfers/features/rounds/domain/golf_round.dart';
import 'package:christian_golfers/features/scorecard/domain/hole_score.dart';
import 'package:flutter_test/flutter_test.dart';

const _pars = <int>[4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4, 4];

Map<int, int> holePars([int holes = 18]) => {
      for (var index = 0; index < holes; index++) index + 1: _pars[index],
    };

GolfRound round({
  String id = 'r1',
  String status = 'completed',
  DateTime? completedAt,
}) {
  return GolfRound(
    id: id,
    hostUserId: 'me',
    courseId: 'c1',
    courseName: 'Test GC',
    teeSetId: 'club',
    teeSetName: 'Club',
    joinCode: 'ABC123',
    format: 'strokePlay',
    status: status,
    currentHole: 18,
    createdAt: DateTime(2026, 1, 1),
    completedAt: completedAt ?? DateTime(2026, 1, 1, 16),
  );
}

/// A card where every hole is played [overPar] over its par.
List<HoleScore> card({
  String roundId = 'r1',
  int holes = 18,
  int overPar = 0,
  int putts = 2,
}) {
  return [
    for (var index = 0; index < holes; index++)
      HoleScore(
        roundId: roundId,
        playerId: 'me',
        holeNumber: index + 1,
        strokes: _pars[index] + overPar,
        putts: putts,
        penaltyStrokes: 0,
        confirmed: true,
      ),
  ];
}

void main() {
  group('RoundSummary', () {
    test('adds up strokes, putts and par for a level round', () {
      final summary = RoundSummary(
        round: round(),
        myScores: card(),
        holePars: holePars(),
        coursePar: 72,
      );

      expect(summary.holesPlayed, 18);
      expect(summary.isFullRound, isTrue);
      expect(summary.grossStrokes, 72);
      expect(summary.putts, 36);
      expect(summary.toPar, 0);
    });

    test('counts penalty strokes towards the gross score', () {
      final scores = card(holes: 1);
      final summary = RoundSummary(
        round: round(),
        myScores: [
          HoleScore(
            roundId: 'r1',
            playerId: 'me',
            holeNumber: 1,
            strokes: scores.first.strokes,
            putts: 2,
            penaltyStrokes: 2,
            confirmed: true,
          ),
        ],
        holePars: holePars(),
        coursePar: 72,
      );

      expect(summary.grossStrokes, 6); // par 4 + 2 penalties
      expect(summary.toPar, 2);
    });

    test('measures to-par against holes played, not the full course', () {
      final summary = RoundSummary(
        round: round(status: 'active'),
        myScores: card(holes: 9, overPar: 1),
        holePars: holePars(),
        coursePar: 72,
      );

      expect(summary.isFullRound, isFalse);
      expect(summary.toPar, 9);
    });

    test('falls back to the course total when hole pars are missing', () {
      final summary = RoundSummary(
        round: round(),
        myScores: card(overPar: 1),
        holePars: const {},
        coursePar: 72,
      );

      expect(summary.parForHolesPlayed, isNull);
      expect(summary.toPar, 18);
    });

    test('gives up on to-par when nothing is known about par', () {
      final summary = RoundSummary(
        round: round(),
        myScores: card(),
        holePars: const {},
      );

      expect(summary.toPar, isNull);
    });

    test('classifies holes relative to par', () {
      final summary = RoundSummary(
        round: round(),
        myScores: [
          HoleScore(roundId: 'r1', playerId: 'me', holeNumber: 4, strokes: 3,
              putts: 1, penaltyStrokes: 0, confirmed: true), // par 5, eagle
          HoleScore(roundId: 'r1', playerId: 'me', holeNumber: 1, strokes: 3,
              putts: 1, penaltyStrokes: 0, confirmed: true), // par 4, birdie
          HoleScore(roundId: 'r1', playerId: 'me', holeNumber: 2, strokes: 4,
              putts: 2, penaltyStrokes: 0, confirmed: true), // par
          HoleScore(roundId: 'r1', playerId: 'me', holeNumber: 3, strokes: 4,
              putts: 2, penaltyStrokes: 0, confirmed: true), // par 3, bogey
          HoleScore(roundId: 'r1', playerId: 'me', holeNumber: 5, strokes: 7,
              putts: 3, penaltyStrokes: 0, confirmed: true), // par 4, triple
        ],
        holePars: holePars(),
      );

      expect(summary.breakdown, {
        ScoreClass.eagleOrBetter: 1,
        ScoreClass.birdie: 1,
        ScoreClass.par: 1,
        ScoreClass.bogey: 1,
        ScoreClass.doubleOrWorse: 1,
      });
    });
  });

  group('PlayerStats', () {
    test('is empty with no rounds', () {
      expect(PlayerStats.from(const []).isEmpty, isTrue);
      expect(PlayerStats.from(const []).scoringAverage, isNull);
    });

    test('ignores rounds that are still in progress', () {
      final stats = PlayerStats.from([
        RoundSummary(
          round: round(id: 'live', status: 'active'),
          myScores: card(roundId: 'live', holes: 6),
          holePars: holePars(),
          coursePar: 72,
        ),
      ]);

      expect(stats.roundsPlayed, 0);
      expect(stats.isEmpty, isTrue);
    });

    test('averages only full rounds but counts every completed one', () {
      final stats = PlayerStats.from([
        RoundSummary(
          round: round(id: 'a', completedAt: DateTime(2026, 3, 1)),
          myScores: card(roundId: 'a', overPar: 0),
          holePars: holePars(),
          coursePar: 72,
        ),
        RoundSummary(
          round: round(id: 'b', completedAt: DateTime(2026, 2, 1)),
          myScores: card(roundId: 'b', overPar: 2),
          holePars: holePars(),
          coursePar: 72,
        ),
        RoundSummary(
          round: round(id: 'c', completedAt: DateTime(2026, 1, 1)),
          myScores: card(roundId: 'c', holes: 9),
          holePars: holePars(),
          coursePar: 72,
        ),
      ]);

      expect(stats.roundsPlayed, 3);
      expect(stats.fullRoundsPlayed, 2);
      expect(stats.scoringAverage, (72 + 108) / 2);
      expect(stats.bestGross, 72);
      expect(stats.bestToPar, 0);
      expect(stats.averagePutts, 36);
    });

    test('trend compares the last five rounds with the overall average', () {
      // Six rounds, the older three poor and the newer three good.
      final summaries = <RoundSummary>[
        for (var index = 0; index < 6; index++)
          RoundSummary(
            round: round(
              id: 'r$index',
              completedAt: DateTime(2026, 1, 1).add(Duration(days: index * 7)),
            ),
            myScores: card(roundId: 'r$index', overPar: index < 3 ? 2 : 0),
            holePars: holePars(),
            coursePar: 72,
          ),
      ];

      final stats = PlayerStats.from(summaries);

      expect(stats.fullRoundsPlayed, 6);
      expect(stats.trend, isNotNull);
      // Recent rounds are the good ones, so the trend is negative (improving).
      expect(stats.trend! < 0, isTrue);
    });

    test('withholds a trend until there are enough rounds to mean anything', () {
      final stats = PlayerStats.from([
        RoundSummary(
          round: round(id: 'a'),
          myScores: card(roundId: 'a'),
          holePars: holePars(),
          coursePar: 72,
        ),
      ]);

      expect(stats.trend, isNull);
    });

    test('sums the score mix across every completed round', () {
      final stats = PlayerStats.from([
        RoundSummary(
          round: round(id: 'a', completedAt: DateTime(2026, 2, 1)),
          myScores: card(roundId: 'a', overPar: 1),
          holePars: holePars(),
          coursePar: 72,
        ),
        RoundSummary(
          round: round(id: 'b', completedAt: DateTime(2026, 1, 1)),
          myScores: card(roundId: 'b', overPar: 1),
          holePars: holePars(),
          coursePar: 72,
        ),
      ]);

      expect(stats.breakdown[ScoreClass.bogey], 36);
    });
  });
}
