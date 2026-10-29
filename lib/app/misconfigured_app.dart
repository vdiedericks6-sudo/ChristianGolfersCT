import 'package:flutter/material.dart';

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not passed at build time.
class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF0D6EFD),
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Christian Golfers Cape Town is not configured',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'This build was compiled without SUPABASE_URL and '
                  'SUPABASE_PUBLISHABLE_KEY.\n\n'
                  'Pass them with --dart-define, or set them as environment '
                  'variables on the Vercel project and redeploy.\n\n'
                  'To open the local sample experience without backend keys, run with '
                  '--dart-define=CHRISTIAN_GOLFERS_DEMO=true',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
