import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/offline/round_snapshot_cache.dart';
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

final openRoundsProvider = StreamProvider.autoDispose<List<GolfRound>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(roundRepositoryProvider);
  Future<List<GolfRound>> load() async {
    final rounds = await repository
        .myRounds(limit: 500)
        .timeout(const Duration(seconds: 8));
    return rounds.where((r) => r.isWaiting || r.isActive).toList()..sort(
      (a, b) => (a.scheduledAt ?? a.createdAt ?? DateTime(2000)).compareTo(
        b.scheduledAt ?? b.createdAt ?? DateTime(2000),
      ),
    );
  }

  if (userId == null || ref.watch(demoBackendProvider) != null) {
    return Stream.fromFuture(load());
  }
  return snapshotThenLive<List<GolfRound>>(
    userId: userId,
    kind: 'round_list',
    id: 'open',
    decode: (value) => snapshotList(value, GolfRound.fromJson),
    encode: (value) => value.map(roundSnapshotJson).toList(),
    cacheable: (value) => value.isNotEmpty,
    readCached: () => RoundSnapshotCache.readOpenRounds(userId),
    live: () => Stream.fromFuture(load()),
  );
});

final roundProvider = StreamProvider.family<GolfRound?, String>((ref, roundId) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(roundRepositoryProvider);
  if (userId == null || ref.watch(demoBackendProvider) != null) {
    return repository.watchRound(roundId);
  }
  return snapshotThenLive<GolfRound?>(
    userId: userId,
    kind: 'round',
    id: roundId,
    decode: (value) => GolfRound.fromJson(snapshotMap(value)),
    encode: (value) => roundSnapshotJson(value!),
    cacheable: (value) => value != null,
    live: () => repository.watchRound(roundId),
  );
});

final roundPlayersProvider = StreamProvider.family<List<RoundPlayer>, String>((
  ref,
  roundId,
) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(roundRepositoryProvider);
  if (userId == null || ref.watch(demoBackendProvider) != null) {
    return repository.watchPlayers(roundId);
  }
  return snapshotThenLive<List<RoundPlayer>>(
    userId: userId,
    kind: 'players',
    id: roundId,
    decode: (value) => snapshotList(value, RoundPlayer.fromJson),
    encode: (value) => value.map(playerSnapshotJson).toList(),
    cacheable: (value) => value.isNotEmpty,
    live: () => repository.watchPlayers(roundId),
  );
});
