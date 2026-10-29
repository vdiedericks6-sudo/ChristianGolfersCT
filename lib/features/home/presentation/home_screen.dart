import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/christian_golfers_mark.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../faith/presentation/word_of_the_day_card.dart';
import '../../profile/presentation/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final name = profile?.displayName.split(' ').first ?? 'David';

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HomeHeaderHero(name: name),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                children: [
                  const WordOfTheDayCard(),
                  const SizedBox(height: 18),
                  const _HomeQuickActionsGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hero header matching Screen 2 in the Christian Golfers Cape Town branding.
class _HomeHeaderHero extends StatelessWidget {
  const _HomeHeaderHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.viewPaddingOf(context).top;

    return Stack(
      children: [
        // Background scenic artwork
        SizedBox(
          height: 330,
          width: double.infinity,
          child: Image.asset(
            'assets/images/golf_ball_tee_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const CourseArtwork(seed: 'home-hero-bg', overlay: false),
          ),
        ),
        // Dark gradient overlay
        Container(
          height: 330,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC0F172A),
                Color(0x880F172A),
                Color(0xF2F4F6F9),
              ],
              stops: [0.0, 0.6, 1.0],
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
                  const ChristianGolfersMark(size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Christian Golfers',
                          style: AppTheme.display(
                            16,
                            colour: Colors.white,
                            spacing: 0,
                          ),
                        ),
                        Text(
                          'CAPE TOWN',
                          style: AppTheme.label(
                            9,
                            colour: AppTheme.primaryGreenLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    iconColor: Colors.white,
                    size: 38,
                    onTap: () => context.push('/more'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Greeting
              Text(
                'Good Morning',
                style: AppTheme.body(
                  13.5,
                  colour: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                name,
                style: AppTheme.display(26, colour: Colors.white),
              ),
              const SizedBox(height: 12),

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
      childAspectRatio: 1.45,
      children: [
        QuickActionTile(
          icon: Icons.outlined_flag,
          label: 'Courses',
          caption: 'Explore SA courses',
          onTap: () => context.go('/courses'),
        ),
        QuickActionTile(
          icon: Icons.people_outline_rounded,
          label: 'Community',
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
