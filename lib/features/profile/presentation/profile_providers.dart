import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/profile_repository.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.profiles;

  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(null);
  }

  return ref.watch(profileRepositoryProvider).watchProfile(userId);
});

/// Uses the protected server allowlist RPC in production. The demo seed's
/// role is only for previewing the admin layout.
final currentUserIsAdminProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return false;
  if (ref.watch(demoBackendProvider) != null) {
    return ref.watch(currentProfileProvider).valueOrNull?.isAdmin ?? false;
  }
  return ref.watch(supabaseClientProvider).rpc<bool>('is_admin');
});
