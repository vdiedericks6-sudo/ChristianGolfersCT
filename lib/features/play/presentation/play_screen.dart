import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../rounds/presentation/round_providers.dart';

class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text('Play Golf'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            // Hero Banner Card matching Screen 5
            _PlayHeroCardScreen5(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Text('Your upcoming and active rounds')),
                IconButton(
                  tooltip: 'Refresh rounds',
                  onPressed: () => ref.invalidate(openRoundsProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            ref
                .watch(openRoundsProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text(
                    'Could not load your rounds. Tap refresh to retry.',
                  ),
                  data: (rounds) => rounds.isEmpty
                      ? const Text('No upcoming rounds yet.')
                      : Column(
                          children: rounds.map((round) {
                            final date = round.scheduledAt?.toLocal();
                            return Card(
                              child: ListTile(
                                title: Text(round.courseName),
                                subtitle: Text(
                                  '${round.teeSetName} · ${round.isActive ? 'Hole ${round.currentHole}' : 'Lobby'}'
                                  '${date == null ? '' : '\n${date.day}/${date.month}/${date.year} ${TimeOfDay.fromDateTime(date).format(context)}'}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push(
                                  '/rounds/${round.id}/${round.isActive ? 'live' : 'lobby'}',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
            const SizedBox(height: 16),

            // Quick Menu Items matching Screen 5
            _PlayMenuItemScreen5(
              icon: Icons.assignment_outlined,
              title: 'My Rounds',
              subtitle: 'View your round history',
              onTap: () => context.push('/leaderboards'),
            ),
            const SizedBox(height: 10),
            _PlayMenuItemScreen5(
              icon: Icons.security_rounded,
              title: 'Handicap',
              subtitle: 'View and manage your handicap',
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(height: 10),
            _PlayMenuItemScreen5(
              icon: Icons.bar_chart_rounded,
              title: 'Stats',
              subtitle: 'Your performance at a glance',
              onTap: () => context.push('/leaderboards'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayHeroCardScreen5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppTheme.cardRadius,
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/golf_ball_tee_hero.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  const CourseArtwork(seed: 'play-hero-5', overlay: false),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55182421), Color(0x00182421), Color(0xDD182421)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your next round starts here',
                    style: AppTheme.display(20, colour: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your course. Pick your tees. Play together.',
                    style: AppTheme.body(
                      12,
                      colour: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: GoldButton(
                label: 'New Round',
                icon: Icons.add_circle_outline_rounded,
                // Course selection is a standalone route, preserving Back.
                onPressed: () => context.push('/courses?start=1'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayMenuItemScreen5 extends StatelessWidget {
  const _PlayMenuItemScreen5({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body(14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
