import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/round_repository.dart';
import '../data/supabase_round_repository.dart';
import '../domain/golf_round.dart';
import '../domain/round_player.dart';

final roundRepositoryProvider = Provider<RoundRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.rounds;

  return SupabaseRoundRepository(ref.watch(supabaseClientProvider));
});

final roundProvider = StreamProvider.family<GolfRound?, String>((ref, roundId) {
  return ref.watch(roundRepositoryProvider).watchRound(roundId);
});

final roundPlayersProvider = StreamProvider.family<List<RoundPlayer>, String>((
  ref,
  roundId,
) {
  return ref.watch(roundRepositoryProvider).watchPlayers(roundId);
});
