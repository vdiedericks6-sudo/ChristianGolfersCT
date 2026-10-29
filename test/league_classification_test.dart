import 'package:flutter_test/flutter_test.dart';
import 'package:christian_golfers/features/leagues/data/league_data.dart';
import 'package:christian_golfers/features/profile/domain/user_profile.dart';

UserProfile member({
  required String id,
  double? handicap,
  bool visiting = false,
}) {
  final now = DateTime(2026, 10, 28);
  return UserProfile(
    id: id,
    displayName: id,
    email: '$id@example.test',
    preferredDistanceUnit: 'metres',
    estimatedHandicapIndex: handicap,
    isVisitingGolfer: visiting,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('leagueGroupFor', () {
    const aMax = 12.0;
    const bMax = 24.0;

    test('puts low handicaps in League A', () {
      expect(
        leagueGroupFor(member(id: 'a', handicap: 8.4),
            leagueAMaxHandicap: aMax, leagueBMaxHandicap: bMax),
        LeagueGroup.leagueA,
      );
    });

    test('puts handicaps between thresholds in League B', () {
      expect(
        leagueGroupFor(member(id: 'b', handicap: 18.0),
            leagueAMaxHandicap: aMax, leagueBMaxHandicap: bMax),
        LeagueGroup.leagueB,
      );
    });

    test('keeps members without an established handicap in Social', () {
      expect(
        leagueGroupFor(member(id: 'social'),
            leagueAMaxHandicap: aMax, leagueBMaxHandicap: bMax),
        LeagueGroup.social,
      );
    });

    test('keeps visitors separate even when they have a handicap', () {
      expect(
        leagueGroupFor(member(id: 'visitor', handicap: 5.0, visiting: true),
            leagueAMaxHandicap: aMax, leagueBMaxHandicap: bMax),
        LeagueGroup.visiting,
      );
    });
  });
}
