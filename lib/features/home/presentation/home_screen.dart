import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/christian_golfers_logo.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../faith/presentation/word_of_the_day_card.dart';
import '../../profile/presentation/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final name = profile?.displayName.split(' ').first ?? 'David';
    final greeting = _greetingForLocalTime();

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HomeHeaderHero(name: name, greeting: greeting),
            Transform.translate(
              offset: const Offset(0, -14),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: WordOfTheDayCard(),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -26),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: _HomeQuickActionsGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingForLocalTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// The hero header matching Screen 2 in the Christian Golfers Cape Town branding.
class _HomeHeaderHero extends StatelessWidget {
  const _HomeHeaderHero({required this.name, required this.greeting});

  final String name;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (viewportHeight * 0.31).clamp(245.0, 275.0).toDouble();

    return Stack(
      children: [
        // Background scenic artwork
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Image.asset(
            'assets/images/golf_home_sunset.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const CourseArtwork(seed: 'home-hero-bg', overlay: false),
          ),
        ),
        // Dark gradient overlay
        Container(
          height: heroHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x550B1114), Color(0x22151D20), Color(0xFF20292D)],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
        ),
        // Header contents
        Padding(
          padding: EdgeInsets.fromLTRB(18, topPadding + 12, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Logo, Brand title & notification icon
              Row(
                children: [
                  Expanded(
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: ChristianGolfersLogo(
                        width: 158,
                        height: 82,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    iconColor: Colors.white,
                    size: 38,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Greeting
              Text(
                greeting,
                style: AppTheme.body(
                  13.5,
                  colour: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(name, style: AppTheme.display(26, colour: Colors.white)),
              const SizedBox(height: 6),

              // Scripture quote
              Text(
                '“Commit to the Lord whatever you do, and He will establish your plans.”',
                style: AppTheme.body(
                  12.5,
                  colour: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Proverbs 16:3',
                style: AppTheme.body(
                  11,
                  colour: AppTheme.primaryGreenLight,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2x2 Quick Action Grid matching Screen 2 in the branding image.
class _HomeQuickActionsGrid extends StatelessWidget {
  const _HomeQuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.52,
      children: [
        QuickActionTile(
          icon: Icons.outlined_flag,
          label: 'Courses',
          caption: 'Explore SA courses',
          onTap: () => context.go('/courses'),
        ),
        QuickActionTile(
          icon: Icons.people_outline_rounded,
          label: 'Fellowship',
          caption: 'Connect & share',
          onTap: () => context.go('/community'),
        ),
        QuickActionTile(
          icon: Icons.emoji_events_outlined,
          label: 'Leagues',
          caption: 'View standings',
          onTap: () => context.go('/leagues'),
        ),
        QuickActionTile(
          icon: Icons.sports_golf_rounded,
          label: 'Play Golf',
          caption: 'Track your rounds',
          onTap: () => context.push('/play'),
        ),
      ],
    );
  }
}
