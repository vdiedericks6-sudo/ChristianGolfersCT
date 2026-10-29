import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/christian_golfers_logo.dart';
import 'auth_error_message.dart';
import 'auth_providers.dart';

/// Sign in screen matching Screen 1 & 8 in the Christian Golfers Cape Town branding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    } finally {
      if (mounted && !kIsWeb) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The supplied Cape Town course photo is the app's first image.
          Image.asset(
            'assets/images/golf_image.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const CourseArtwork(seed: 'login-bg', overlay: false),
          ),

          // Dark gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x990F172A),
                  Color(0xCC0F172A),
                  Color(0xFA0F172A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // Circular Logo Icon
                  const ChristianGolfersLogo(
                    width: 260,
                    height: 140,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'FAITH • GOLF • FELLOWSHIP',
                    textAlign: TextAlign.center,
                    style: AppTheme.label(
                      10,
                      colour: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  const Spacer(),

                  // Verse / Quote
                  Text(
                    '“For I know the plans I have for you, declares the Lord, plans to give you hope and a future.”',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      13.5,
                      colour: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jeremiah 29:11',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      12,
                      colour: AppTheme.primaryGreenLight,
                      weight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Get Started / Sign In Button
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: AppTheme.body(
                              15,
                              weight: FontWeight.w700,
                              colour: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cursive Tagline
                  Text(
                    'Play with Purpose',
                    style: AppTheme.scriptAccent(
                      32,
                      colour: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
