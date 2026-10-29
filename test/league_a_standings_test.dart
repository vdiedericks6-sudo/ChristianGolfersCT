import 'package:christian_golfers/features/leagues/domain/league_a_standings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('League A screenshot standings are preserved in order', () {
    expect(leagueAStartingStandings, hasLength(21));
    expect(leagueAStartingStandings.first.fullName, 'Ross Meiring');
    expect(leagueAStartingStandings.first.totalPoints, 259);
    expect(leagueAStartingStandings[4].fullName, 'Raymond Karelse');
    expect(leagueAStartingStandings[4].totalPoints, 241);
    expect(leagueAStartingStandings.last.fullName, 'Grant Pereth');
    expect(leagueAStartingStandings.last.totalPoints, 50);
    expect(
      leagueAStartingStandings.map((entry) => entry.position),
      List<int>.generate(21, (index) => index + 1),
    );
  });
}
