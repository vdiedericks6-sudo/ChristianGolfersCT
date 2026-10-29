import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/misconfigured_app.dart';
import 'core/config/app_config.dart';
import 'core/config/url_strategy.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean URLs on the web build (no '#'), which also keeps the OAuth
  // redirect that Supabase sends back intact. No-op on mobile.
  configureUrlStrategy();

  if (!AppConfig.demoMode) {
    if (!SupabaseConfig.isConfigured) {
      // Fail loudly and legibly instead of throwing deep inside the SDK.
      runApp(const MisconfiguredApp());
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        persistSession: true,
      ),
    );
  }

  runApp(const ProviderScope(child: ChristianGolfersApp()));
}
