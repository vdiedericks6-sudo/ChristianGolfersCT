import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/community_repository.dart';
import '../data/supabase_community_repository.dart';
import '../domain/friend.dart';
import '../domain/friend_activity.dart';
import '../domain/friend_standing.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.community;

  return SupabaseCommunityRepository(ref.watch(supabaseClientProvider));
});

final friendshipsProvider = FutureProvider<List<Friend>>((ref) {
  return ref.watch(communityRepositoryProvider).friendships();
});

final friendActivityProvider = FutureProvider<List<FriendActivity>>((ref) {
  return ref.watch(communityRepositoryProvider).activity();
});

final friendStandingsProvider = FutureProvider<List<FriendStanding>>((ref) {
  return ref.watch(communityRepositoryProvider).standings();
});

/// Refreshes everything the Community tab shows after a change.
void invalidateCommunity(WidgetRef ref) {
  ref.invalidate(friendshipsProvider);
  ref.invalidate(friendActivityProvider);
  ref.invalidate(friendStandingsProvider);
}
