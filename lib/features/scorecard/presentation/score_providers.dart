import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/score_repository.dart';
import '../data/supabase_score_repository.dart';
import '../domain/hole_score.dart';
import 'score_outbox_provider.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.scores;

  return SupabaseScoreRepository(ref.watch(supabaseClientProvider));
});

final roundScoresProvider = StreamProvider.family<List<HoleScore>, String>((ref, roundId) async* {
  final actor = ref.watch(currentUserIdProvider);
  final repository = ref.watch(scoreRepositoryProvider);
  if (actor == null) {
    yield* repository.watchScores(roundId);
    return;
  }
  final outbox = ref.watch(scoreOutboxProvider);
  var disposed = false;
  Timer? retryTimer;
  Completer<void>? retryWait;
  ref.onDispose(() {
    disposed = true;
    retryTimer?.cancel();
    if (retryWait != null && !retryWait!.isCompleted) retryWait!.complete();
  });
  await outbox.ready;
  final cached = await outbox.store.readScores(actor, roundId);
  if (cached != null) yield cached;
  var hadData = cached != null;
  while (!disposed) {
    try {
      await for (final scores in repository.watchScores(roundId)) {
        await outbox.store.writeScores(actor, roundId, scores);
        hadData = true;
        yield scores;
      }
    } catch (error, stack) {
      if (!hadData) yield* Stream<List<HoleScore>>.error(error, stack);
    }
    if (disposed) break;
    retryWait = Completer<void>();
    retryTimer = Timer(const Duration(seconds: 15), retryWait!.complete);
    await retryWait!.future;
  }
});

final myRoundScoresProvider = StreamProvider.family<List<HoleScore>, String>((
  ref,
  roundId,
) {
  return ref.watch(scoreRepositoryProvider).watchMyScores(roundId);
});
