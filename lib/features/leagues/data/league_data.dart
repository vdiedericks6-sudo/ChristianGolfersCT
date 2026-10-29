import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/demo_providers.dart';
import '../../profile/domain/user_profile.dart';

class LeagueSnapshot {
  const LeagueSnapshot({
    required this.members,
    required this.leagueAMaxHandicap,
    required this.leagueBMaxHandicap,
  });

  final List<UserProfile> members;
  final double leagueAMaxHandicap;
  final double leagueBMaxHandicap;
}

enum LeagueGroup { leagueA, leagueB, social, visiting }

LeagueGroup leagueGroupFor(
  UserProfile member, {
  required double leagueAMaxHandicap,
  required double leagueBMaxHandicap,
}) {
  if (member.isVisitingGolfer) return LeagueGroup.visiting;

  final handicap = member.estimatedHandicapIndex;
  if (handicap == null || handicap > leagueBMaxHandicap) {
    return LeagueGroup.social;
  }
  if (handicap <= leagueAMaxHandicap) return LeagueGroup.leagueA;
  return LeagueGroup.leagueB;
}

final leagueSnapshotProvider = FutureProvider<LeagueSnapshot>((ref) async {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) {
    return LeagueSnapshot(
      members: demo.allProfiles,
      leagueAMaxHandicap: demo.leagueAMaxHandicap,
      leagueBMaxHandicap: demo.leagueBMaxHandicap,
    );
  }

  final client = Supabase.instance.client;
  final rows = await client
      .from('profiles')
      .select()
      .order('display_name');
  final settings = await client
      .from('league_settings')
      .select()
      .eq('id', 1)
      .maybeSingle();

  if (settings == null) {
    throw StateError(
      'League settings have not been created. Apply the Christian Golfers league migration first.',
    );
  }

  final members = (rows as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(UserProfile.fromJson)
      .toList();

  return LeagueSnapshot(
    members: members,
    leagueAMaxHandicap:
        (settings['league_a_max_handicap'] as num).toDouble(),
    leagueBMaxHandicap:
        (settings['league_b_max_handicap'] as num).toDouble(),
  );
});
