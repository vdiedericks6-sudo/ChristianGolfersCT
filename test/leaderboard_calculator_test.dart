import 'package:christian_golfers/features/courses/domain/golf_hole.dart';
import 'package:christian_golfers/features/courses/domain/tee_set.dart';
import 'package:christian_golfers/features/leaderboard/domain/leaderboard_calculator.dart';
import 'package:christian_golfers/features/rounds/domain/round_player.dart';
import 'package:christian_golfers/features/scorecard/domain/hole_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tee = TeeSet(
    id: 'club',
    name: 'Club',
    colour: 'White',
    courseRating: 72,
    slopeRating: 113,
    par: 72,
    totalDistance: 6000,
    distanceUnit: 'metres',
  );

  const holes = [
    GolfHole(
      number: 1,
      par: 4,
      strokeIndex: 1,
      teeLatitude: 0,
      teeLongitude: 0,
      greenFrontLatitude: 0,
      greenFrontLongitude: 0,
      greenCentreLatitude: 0,
      greenCentreLongitude: 0,
      greenBackLatitude: 0,
      greenBackLongitude: 0,
    ),
    GolfHole(
      number: 2,
      par: 4,
      strokeIndex: 18,
      teeLatitude: 0,
      teeLongitude: 0,
      greenFrontLatitude: 0,
      greenFrontLongitude: 0,
      greenCentreLatitude: 0,
      greenCentreLongitude: 0,
      greenBackLatitude: 0,
      greenBackLongitude: 0,
    ),
  ];

  const players = [
    RoundPlayer(
      userId: 'a',
      displayName: 'Alice',
      role: 'host',
      active: true,
      handicapIndex: 18,
    ),
    RoundPlayer(
      userId: 'b',
      displayName: 'Bob',
      role: 'player',
      active: true,
      handicapIndex: 0,
    ),
  ];

  const scores = [
    HoleScore(
      roundId: 'r',
      playerId: 'a',
      holeNumber: 1,
      strokes: 5,
      putts: 2,
      penaltyStrokes: 0,
      confirmed: true,
    ),
    HoleScore(
      roundId: 'r',
      playerId: 'a',
      holeNumber: 2,
      strokes: 5,
      putts: 2,
      penaltyStrokes: 0,
      confirmed: true,
    ),
    HoleScore(
      roundId: 'r',
      playerId: 'b',
      holeNumber: 1,
      strokes: 4,
      putts: 2,
      penaltyStrokes: 0,
      confirmed: true,
    ),
    HoleScore(
      roundId: 'r',
      playerId: 'b',
      holeNumber: 2,
      strokes: 5,
      putts: 2,
      penaltyStrokes: 0,
      confirmed: true,
    ),
  ];

  test('primary net stroke play applies handicap strokes', () {
    final result = LeaderboardCalculator.calculate(
      players: players,
      scores: scores,
      holes: holes,
      teeSet: tee,
      mode: LeaderboardMode.net,
      currentUserId: 'a',
    );

    expect(result.first.playerId, 'a');
    expect(result.first.netTotal, 8);
    expect(result.first.netToPar, 0);
    expect(result.first.grossTotal, 10);
  });

  test('secondary gross view ranks lower gross score first', () {
    final result = LeaderboardCalculator.calculate(
      players: players,
      scores: scores,
      holes: holes,
      teeSet: tee,
      mode: LeaderboardMode.gross,
      currentUserId: 'a',
    );

    expect(result.first.playerId, 'b');
    expect(result.first.grossTotal, 9);
  });
}
