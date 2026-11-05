import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/score_outbox.dart';
import '../domain/hole_score.dart';
import 'score_providers.dart';

final scoreOutboxProvider = ChangeNotifierProvider<ScoreOutbox>((ref) {
  final demo = ref.watch(demoBackendProvider);
  final repository = ref.watch(scoreRepositoryProvider);
  final client = demo == null ? ref.read(supabaseClientProvider) : null;
  return ScoreOutbox(
    store: demo == null && !kIsWeb ? SqliteScoreQueueStore() : MemoryScoreQueueStore(),
    currentActor: () => ref.read(currentUserIdProvider),
    send: (score) async {
      if (client != null) {
        await client.rpc('save_group_hole_score', params: {
          'p_actor_id': score.actorId,
          'p_request_id': score.id,
          'p_round_id': score.roundId,
          'p_player_id': score.playerId,
          'p_hole_number': score.holeNumber,
          'p_strokes': score.strokes,
          'p_putts': score.putts,
          'p_penalty_strokes': score.penaltyStrokes,
          'p_sand_shots': score.sandShots,
          'p_fairway': score.fairway,
          'p_green_in_regulation': score.greenInRegulation,
          'p_expected_exists': score.expectedExists,
          'p_expected_updated_at': score.expectedUpdatedAt?.toUtc().toIso8601String(),
        });
        final row = await client.from('hole_scores').select().eq('round_id', score.roundId).eq('player_id', score.playerId).eq('hole_number', score.holeNumber).single();
        return HoleScore.fromJson(row);
      } else {
        await repository.saveGroupScore(
          roundId: score.roundId, playerId: score.playerId,
          holeNumber: score.holeNumber, strokes: score.strokes,
          putts: score.putts, penaltyStrokes: score.penaltyStrokes,
          sandShots: score.sandShots, fairway: score.fairway,
          greenInRegulation: score.greenInRegulation,
          expectedExists: score.expectedExists,
          expectedUpdatedAt: score.expectedUpdatedAt,
        );
        final scores = await repository.watchScores(score.roundId).first;
        return scores.firstWhere((s) => s.playerId == score.playerId && s.holeNumber == score.holeNumber);
      }
    },
  );
});
