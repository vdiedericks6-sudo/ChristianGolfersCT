import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'demo_backend.dart';

/// The demo backend, or null when the app is running against Supabase.
///
/// Every repository provider checks this first, which is the single point
/// where demo mode diverges from the real thing.
final demoBackendProvider = Provider<DemoBackend?>((ref) {
  if (!AppConfig.demoMode) return null;

  final backend = DemoBackend.seeded();
  ref.onDispose(backend.dispose);
  return backend;
});
