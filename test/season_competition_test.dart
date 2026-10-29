import 'package:christian_golfers/features/leagues/domain/season_competition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommended points schedule awards 40 for first and 1 from 21st', () {
    expect(CompetitionPointsSchedule.pointsForPosition(1), 40);
    expect(CompetitionPointsSchedule.pointsForPosition(2), 35);
    expect(CompetitionPointsSchedule.pointsForPosition(20), 2);
    expect(CompetitionPointsSchedule.pointsForPosition(21), 1);
    expect(CompetitionPointsSchedule.pointsForPosition(35), 1);
  });

  test('net-score ties share points and following position is skipped', () {
    final awards = SeasonCompetitionCalculator.awardRoundPoints([
      _result('r1', 'a', 'Alice', 70),
      _result('r1', 'b', 'Bob', 70),
      _result('r1', 'c', 'Charlie', 72),
    ]);

    expect(awards.singleWhere((award) => award.playerId == 'a').position, 1);
    expect(awards.singleWhere((award) => award.playerId == 'b').position, 1);
    expect(awards.singleWhere((award) => award.playerId == 'a').points, 40);
    expect(awards.singleWhere((award) => award.playerId == 'b').points, 40);
    expect(awards.singleWhere((award) => award.playerId == 'c').position, 3);
    expect(awards.singleWhere((award) => award.playerId == 'c').points, 32);
  });

  test('live total uses all eligible rounds; final uses best seven round awards', () {
    final results = <CompetitionRoundResult>[];
    final targetPlaces = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    for (var round = 0; round < targetPlaces.length; round++) {
      final roundId = 'round-$round';
      final place = targetPlaces[round];
      for (var opponent = 0; opponent < place - 1; opponent++) {
        results.add(
          _result(
            roundId,
            'opponent-$round-$opponent',
            'Opponent $round $opponent',
            70 + opponent,
          ),
        );
      }
      results.add(_result(roundId, 'golfer-a', 'Golfer A', 100));
    }
    // This apparent win must not count because the round is not completed.
    results.add(
      const CompetitionRoundResult(
        roundId: 'incomplete',
        playerId: 'golfer-a',
        playerName: 'Golfer A',
        division: CompetitionDivision.leagueA,
        netScore: 1,
        completed: false,
        eligible: true,
      ),
    );

    final live = SeasonCompetitionCalculator.calculateLive(
      results,
      division: CompetitionDivision.leagueA,
    ).singleWhere((standing) => standing.playerId == 'golfer-a');
    final finalStanding = SeasonCompetitionCalculator.calculateFinal(
      results,
      division: CompetitionDivision.leagueA,
    ).singleWhere((standing) => standing.playerId == 'golfer-a');

    expect(live.eligibleRounds, 9);
    expect(live.totalPoints, 257); // 40+35+32+30+28+26+24+22+20
    expect(finalStanding.eligibleRounds, 9);
    expect(finalStanding.countedRoundPoints, [40, 35, 32, 30, 28, 26, 24]);
    expect(finalStanding.totalPoints, 215);
  });

  test('ineligible results do not receive points', () {
    final awards = SeasonCompetitionCalculator.awardRoundPoints([
      _result('r1', 'a', 'Alice', 70),
      const CompetitionRoundResult(
        roundId: 'r1',
        playerId: 'b',
        playerName: 'Bob',
        division: CompetitionDivision.leagueA,
        netScore: 60,
        completed: true,
        eligible: false,
      ),
    ]);

    expect(awards, hasLength(1));
    expect(awards.single.playerId, 'a');
    expect(awards.single.position, 1);
    expect(awards.single.points, 40);
  });
}

CompetitionRoundResult _result(
  String roundId,
  String playerId,
  String playerName,
  int netScore,
) => CompetitionRoundResult(
  roundId: roundId,
  playerId: playerId,
  playerName: playerName,
  division: CompetitionDivision.leagueA,
  netScore: netScore,
  completed: true,
  eligible: true,
);
