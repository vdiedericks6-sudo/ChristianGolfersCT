import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/json_parsing.dart';
import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../leagues/domain/season_competition.dart';

class AdminDashboardFilter {
  const AdminDashboardFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  String? _date(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-'
            '${value.month.toString().padLeft(2, '0')}-'
            '${value.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> get rpcParameters => {
    'p_from_date': _date(from),
    'p_to_date': _date(to),
  };

  @override
  bool operator ==(Object other) =>
      other is AdminDashboardFilter &&
      _date(other.from) == _date(from) &&
      _date(other.to) == _date(to);

  @override
  int get hashCode => Object.hash(_date(from), _date(to));
}

class AdminLeagueMember {
  const AdminLeagueMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.handicapIndex,
    required this.visiting,
    required this.createdAt,
  });

  final String userId;
  final String displayName;
  final String email;
  final double? handicapIndex;
  final bool visiting;
  final DateTime? createdAt;

  factory AdminLeagueMember.fromJson(Json row) => AdminLeagueMember(
    userId: asString(row['user_id']),
    displayName: asString(row['display_name'], 'Golfer'),
    email: asString(row['email']),
    handicapIndex: asDoubleOrNull(row['handicap_index']),
    visiting: asBool(row['is_visiting_golfer']),
    createdAt: asDateOrNull(row['created_at']),
  );
}

class AdminLeagueRound {
  const AdminLeagueRound({
    required this.id,
    required this.courseName,
    required this.teeSetName,
    required this.status,
    required this.format,
    required this.currentHole,
    required this.hostUserId,
    required this.hostName,
    required this.createdAt,
    required this.startedAt,
    required this.completedAt,
    required this.playedAt,
  });

  final String id;
  final String courseName;
  final String teeSetName;
  final String status;
  final String format;
  final int currentHole;
  final String hostUserId;
  final String hostName;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? playedAt;

  factory AdminLeagueRound.fromJson(Json row) => AdminLeagueRound(
    id: asString(row['id']),
    courseName: asString(row['course_name']),
    teeSetName: asString(row['tee_set_name']),
    status: asString(row['status']),
    format: asString(row['format']),
    currentHole: asInt(row['current_hole'], 1),
    hostUserId: asString(row['host_user_id']),
    hostName: asString(row['host_name'], 'Golfer'),
    createdAt: asDateOrNull(row['created_at']),
    startedAt: asDateOrNull(row['started_at']),
    completedAt: asDateOrNull(row['completed_at']),
    playedAt: asDateOrNull(row['played_at']),
  );
}

class AdminRoundPlayer {
  const AdminRoundPlayer({
    required this.roundId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.active,
    required this.handicapIndex,
    required this.courseHandicap,
    required this.playingHandicap,
    required this.joinedAt,
  });

  final String roundId;
  final String userId;
  final String displayName;
  final String email;
  final String role;
  final bool active;
  final double? handicapIndex;
  final int? courseHandicap;
  final int? playingHandicap;
  final DateTime? joinedAt;

  factory AdminRoundPlayer.fromJson(Json row) => AdminRoundPlayer(
    roundId: asString(row['round_id']),
    userId: asString(row['user_id']),
    displayName: asString(row['display_name'], 'Golfer'),
    email: asString(row['email']),
    role: asString(row['role']),
    active: asBool(row['active'], true),
    handicapIndex: asDoubleOrNull(row['handicap_index']),
    courseHandicap: asIntOrNull(row['course_handicap']),
    playingHandicap: asIntOrNull(row['playing_handicap']),
    joinedAt: asDateOrNull(row['joined_at']),
  );
}

class AdminHoleScore {
  const AdminHoleScore({
    required this.roundId,
    required this.playerId,
    required this.holeNumber,
    required this.par,
    required this.strokeIndex,
    required this.strokes,
    required this.putts,
    required this.penalties,
    required this.confirmed,
    required this.updatedAt,
  });

  final String roundId;
  final String playerId;
  final int holeNumber;
  final int? par;
  final int? strokeIndex;
  final int strokes;
  final int putts;
  final int penalties;
  final bool confirmed;
  final DateTime? updatedAt;

  int get gross => strokes + penalties;

  factory AdminHoleScore.fromJson(Json row) => AdminHoleScore(
    roundId: asString(row['round_id']),
    playerId: asString(row['player_id']),
    holeNumber: asInt(row['hole_number']),
    par: asIntOrNull(row['par']),
    strokeIndex: asIntOrNull(row['stroke_index']),
    strokes: asInt(row['strokes']),
    putts: asInt(row['putts']),
    penalties: asInt(row['penalty_strokes']),
    confirmed: asBool(row['confirmed']),
    updatedAt: asDateOrNull(row['updated_at']),
  );
}

class AdminRoundResult {
  const AdminRoundResult({
    required this.roundId,
    required this.playerId,
    required this.displayName,
    required this.handicapIndex,
    required this.courseHandicap,
    required this.holesPlayed,
    required this.grossStrokes,
    required this.netStrokes,
    required this.position,
    required this.completedAt,
  });

  final String roundId;
  final String playerId;
  final String displayName;
  final double? handicapIndex;
  final int courseHandicap;
  final int holesPlayed;
  final int grossStrokes;
  final int netStrokes;
  final int position;
  final DateTime? completedAt;

  factory AdminRoundResult.fromJson(Json row) => AdminRoundResult(
    roundId: asString(row['round_id']),
    playerId: asString(row['player_id']),
    displayName: asString(row['display_name'], 'Golfer'),
    handicapIndex: asDoubleOrNull(row['handicap_index']),
    courseHandicap: asInt(row['course_handicap']),
    holesPlayed: asInt(row['holes_played']),
    grossStrokes: asInt(row['gross_strokes']),
    netStrokes: asInt(row['net_strokes']),
    position: asInt(row['position']),
    completedAt: asDateOrNull(row['completed_at']),
  );
}

class AdminLeagueDashboard {
  const AdminLeagueDashboard({
    required this.members,
    required this.rounds,
    required this.players,
    required this.scores,
    required this.results,
    required this.leagueAMaxHandicap,
    required this.leagueBMaxHandicap,
  });

  final List<AdminLeagueMember> members;
  final List<AdminLeagueRound> rounds;
  final List<AdminRoundPlayer> players;
  final List<AdminHoleScore> scores;
  final List<AdminRoundResult> results;
  final double leagueAMaxHandicap;
  final double leagueBMaxHandicap;

  factory AdminLeagueDashboard.fromJson(Json json) {
    double number(Object? value, double fallback) =>
        value is num ? value.toDouble() : fallback;
    List<T> rows<T>(String key, T Function(Json) parser) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(parser)
            .toList(growable: false);

    final leagueA = number(json['league_a_max_handicap'], 12);
    final leagueB = number(json['league_b_max_handicap'], 24);
    return AdminLeagueDashboard(
      members: rows('members', AdminLeagueMember.fromJson),
      rounds: rows('rounds', AdminLeagueRound.fromJson),
      players: rows('players', AdminRoundPlayer.fromJson),
      scores: rows('scores', AdminHoleScore.fromJson),
      results: rows('results', AdminRoundResult.fromJson),
      leagueAMaxHandicap: leagueA,
      leagueBMaxHandicap: leagueB,
    );
  }

  List<CompetitionRoundResult> get competitionResults {
    final membersById = {for (final member in members) member.userId: member};
    final completedRounds = {
      for (final round in rounds.where((round) => round.status == 'completed'))
        round.id,
    };
    return [
      for (final result in results)
        if (completedRounds.contains(result.roundId) &&
            result.holesPlayed >= 18)
          CompetitionRoundResult(
            roundId: result.roundId,
            playerId: result.playerId,
            playerName: result.displayName,
            division: _divisionFor(
              membersById[result.playerId],
              result.handicapIndex,
            ),
            netScore: result.netStrokes,
            completed: true,
            eligible: true,
          ),
    ];
  }

  CompetitionDivision _divisionFor(
    AdminLeagueMember? member,
    double? fallbackIndex,
  ) {
    if (member?.visiting ?? false) return CompetitionDivision.social;
    final index = fallbackIndex ?? member?.handicapIndex;
    if (index == null || index > leagueBMaxHandicap) {
      return CompetitionDivision.social;
    }
    if (index <= leagueAMaxHandicap) return CompetitionDivision.leagueA;
    return CompetitionDivision.leagueB;
  }

  int get confirmedScores => scores.where((score) => score.confirmed).length;

  int get completedRoundCount =>
      rounds.where((round) => round.status == 'completed').length;
}

final adminLeagueDashboardProvider = FutureProvider.autoDispose
    .family<AdminLeagueDashboard, AdminDashboardFilter>((ref, filter) async {
      final demo = ref.watch(demoBackendProvider);
      if (demo != null) {
        throw StateError(
          'The league owner dashboard requires the secure live backend.',
        );
      }

      final client = ref.watch(supabaseClientProvider);
      final payload = await client.rpc(
        'admin_league_dashboard',
        params: filter.rpcParameters,
      );
      if (payload is! Map<String, dynamic>) {
        throw const FormatException(
          'The admin dashboard returned invalid data.',
        );
      }
      return AdminLeagueDashboard.fromJson(payload);
    });
