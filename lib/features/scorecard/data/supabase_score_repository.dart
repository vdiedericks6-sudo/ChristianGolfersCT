import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/hole_score.dart';
import 'score_repository.dart';

class SupabaseScoreRepository implements ScoreRepository {
  SupabaseScoreRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _scores => _client.from('hole_scores');

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('You must be signed in.');
    }
    return id;
  }

  @override
  Stream<List<HoleScore>> watchScores(String roundId) {
    return _scores
        .stream(primaryKey: ['round_id', 'player_id', 'hole_number'])
        .eq('round_id', roundId)
        .map((rows) {
          final scores = rows.map(HoleScore.fromJson).toList();

          scores.sort((a, b) {
            final playerCompare = a.playerId.compareTo(b.playerId);
            if (playerCompare != 0) return playerCompare;
            return a.holeNumber.compareTo(b.holeNumber);
          });

          return scores;
        });
  }

  /// Realtime streams accept a single filter, so the player filter is applied
  /// client-side on top of the round stream.
  @override
  Stream<List<HoleScore>> watchMyScores(String roundId) {
    final userId = _currentUserId;

    return watchScores(roundId).map((scores) {
      final mine = scores.where((score) => score.playerId == userId).toList();
      mine.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
      return mine;
    });
  }

  @override
  Future<void> saveMyScore({
    required String roundId,
    required int holeNumber,
    required int strokes,
    required int putts,
    required int penaltyStrokes,
    bool confirmed = true,
  }) async {
    if (holeNumber < 1 || holeNumber > 18) {
      throw ArgumentError('Hole number must be between 1 and 18.');
    }

    if (strokes < 1 || strokes > 20) {
      throw ArgumentError('Strokes must be between 1 and 20.');
    }

    if (putts < 0 || putts > 10) {
      throw ArgumentError('Putts must be between 0 and 10.');
    }

    if (penaltyStrokes < 0 || penaltyStrokes > 10) {
      throw ArgumentError('Penalty strokes must be between 0 and 10.');
    }

    final playerId = _currentUserId;

    await _scores.upsert({
      'round_id': roundId,
      'player_id': playerId,
      'hole_number': holeNumber,
      'strokes': strokes,
      'putts': putts,
      'penalty_strokes': penaltyStrokes,
      'confirmed': confirmed,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': playerId,
    }, onConflict: 'round_id,player_id,hole_number');
  }

  @override
  Future<List<HoleScore>> myScoresForRounds(Iterable<String> roundIds) async {
    final ids = roundIds.toSet().toList();
    if (ids.isEmpty) return const [];

    final rows = await _scores
        .select()
        .inFilter('round_id', ids)
        .eq('player_id', _currentUserId);

    return rows.map(HoleScore.fromJson).toList(growable: false);
  }
}
