import 'package:supabase_flutter/supabase_flutter.dart';

import '../../courses/domain/golf_course.dart';
import '../../courses/domain/tee_set.dart';
import '../domain/golf_round.dart';
import '../domain/round_player.dart';
import 'round_repository.dart';

class SupabaseRoundRepository implements RoundRepository {
  SupabaseRoundRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _rounds => _client.from('rounds');

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You must be signed in.');
    }
    return id;
  }

  /// Creating a round and seating the host happens in one `create_round`
  /// transaction on Postgres, which also guarantees a unique join code.
  @override
  Future<String> createRound({
    required GolfCourse course,
    required TeeSet teeSet,
  }) async {
    final roundId = await _client.rpc<dynamic>(
      'create_round',
      params: {
        'p_course_id': course.id,
        'p_course_name': course.name,
        'p_tee_set_id': teeSet.id,
        'p_tee_set_name': teeSet.name,
      },
    );

    return roundId as String;
  }

  @override
  Future<String> joinRoundByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    if (code.length != 6) {
      throw StateError('Enter the six-character round code.');
    }

    final roundId = await _client.rpc<dynamic>(
      'join_round_by_code',
      params: {'p_code': code},
    );

    return roundId as String;
  }

  @override
  Stream<GolfRound?> watchRound(String roundId) {
    return _rounds
        .stream(primaryKey: ['id'])
        .eq('id', roundId)
        .map((rows) => rows.isEmpty ? null : GolfRound.fromJson(rows.first));
  }

  @override
  Stream<List<RoundPlayer>> watchPlayers(String roundId) {
    return _client
        .from('round_players')
        .stream(primaryKey: ['round_id', 'user_id'])
        .eq('round_id', roundId)
        .map((rows) {
          final players = rows.map(RoundPlayer.fromJson).toList();

          players.sort((a, b) {
            if (a.isHost && !b.isHost) return -1;
            if (!a.isHost && b.isHost) return 1;
            return a.displayName.compareTo(b.displayName);
          });

          return players;
        });
  }

  Future<GolfRound> _requireRound(String roundId) async {
    final row = await _rounds.select().eq('id', roundId).maybeSingle();

    if (row == null) {
      throw StateError('Round not found.');
    }

    return GolfRound.fromJson(row);
  }

  @override
  Future<void> startRound(String roundId) async {
    final round = await _requireRound(roundId);

    if (round.hostUserId != _currentUserId) {
      throw StateError('Only the host can start the round.');
    }

    if (!round.isWaiting) {
      throw StateError('The round is no longer waiting to start.');
    }

    await _rounds.update({
      'status': 'active',
      'current_hole': 1,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', roundId);
  }

  @override
  Future<void> setCurrentHole({
    required String roundId,
    required int holeNumber,
  }) async {
    if (holeNumber < 1 || holeNumber > 18) {
      throw ArgumentError('Hole number must be between 1 and 18.');
    }

    final round = await _requireRound(roundId);

    if (round.hostUserId != _currentUserId) {
      throw StateError('Only the host can move the shared round hole.');
    }

    if (!round.isActive) {
      throw StateError('The round is not active.');
    }

    await _rounds.update({'current_hole': holeNumber}).eq('id', roundId);
  }

  @override
  Future<void> completeRound(String roundId) async {
    await _client.rpc('complete_round', params: {'p_round_id': roundId});
  }

  /// Two plain queries rather than an embedded select: the round ids the
  /// golfer is seated at, then those rounds. Avoids depending on PostgREST
  /// resolving the foreign key by name.
  @override
  Future<List<GolfRound>> myRounds({int limit = 50}) async {
    final seats = await _client
        .from('round_players')
        .select('round_id')
        .eq('user_id', _currentUserId);

    final ids = seats
        .map((row) => row['round_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) return const [];

    final rows = await _rounds
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map(GolfRound.fromJson).toList(growable: false);
  }
}
