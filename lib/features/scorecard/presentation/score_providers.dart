import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/score_repository.dart';
import '../data/supabase_score_repository.dart';
import '../domain/hole_score.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.scores;

  return SupabaseScoreRepository(ref.watch(supabaseClientProvider));
});

final roundScoresProvider = StreamProvider.family<List<HoleScore>, String>((
  ref,
  roundId,
) {
  return ref.watch(scoreRepositoryProvider).watchScores(roundId);
});

final myRoundScoresProvider = StreamProvider.family<List<HoleScore>, String>((
  ref,
  roundId,
) {
  return ref.watch(scoreRepositoryProvider).watchMyScores(roundId);
});
