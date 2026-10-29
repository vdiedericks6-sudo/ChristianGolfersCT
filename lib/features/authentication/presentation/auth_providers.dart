import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/christian_golfer_user.dart';
import '../../../core/demo/demo_providers.dart';
import '../data/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.auth;

  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<ChristianGolferUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Convenience for widgets that only need the signed-in golfer's id.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.id;
});
