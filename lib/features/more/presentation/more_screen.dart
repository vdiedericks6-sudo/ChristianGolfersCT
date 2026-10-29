import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../profile/presentation/profile_providers.dart';

/// Secondary actions and account tools, reached from the Home settings icon.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentUserIsAdminProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: const Text('More'),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Everything else', style: AppTheme.display(26)),
            const SizedBox(height: 20),

            const SectionHeader('Play'),
            _MoreTile(
              icon: Icons.sports_golf_rounded,
              title: 'Start a round',
              subtitle: 'Pick a course and open it to your crew',
              onTap: () => context.go('/courses'),
            ),
            _MoreTile(
              icon: Icons.group_add_rounded,
              title: 'Join with a code',
              subtitle: 'Six characters from whoever is hosting',
              onTap: () => context.push('/join-round'),
            ),

            const SizedBox(height: 22),
            const SectionHeader('Your golf'),
            _MoreTile(
              icon: Icons.query_stats_rounded,
              title: 'Rounds and stats',
              subtitle: 'Scoring average, best round, putting',
              onTap: () => context.push('/leaderboards'),
            ),
            _MoreTile(
              icon: Icons.leaderboard_rounded,
              title: 'Leagues',
              subtitle: 'League A, League B, Social and Visiting Golfers',
              onTap: () => context.go('/leagues'),
            ),
            _MoreTile(
              icon: Icons.groups_rounded,
              title: 'Fellowship',
              subtitle: 'Your crew, their rounds, season standings',
              onTap: () => context.push('/community'),
            ),

            const SizedBox(height: 22),
            const SectionHeader('League management'),
            _MoreTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Owner / captain dashboard',
              subtitle: 'Sign in to review member scores and standings',
              onTap: () => context.push('/admin'),
            ),
            if (isAdmin)
              _MoreTile(
                icon: Icons.cloud_download_rounded,
                title: 'Import course catalogue',
                subtitle: 'Courses, holes and driving ranges',
                onTap: () => context.push('/course-seed'),
              ),

            const SizedBox(height: 22),
            const SectionHeader('Account'),
            _MoreTile(
              icon: Icons.person_rounded,
              title: 'Profile and handicap',
              onTap: () => context.go('/profile'),
            ),

            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Text(
                    AppConfig.demoMode
                        ? 'CHRISTIAN GOLFERS CAPE TOWN — DEMO MODE'
                        : 'CHRISTIAN GOLFERS CAPE TOWN',
                    style: AppTheme.label(10, colour: AppTheme.textFaint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Course and range records include OpenStreetMap and other directory sources. Verify details before relying on them.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(11, colour: AppTheme.textFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const tint = AppTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChristianGolfersCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.cardSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.body(14.5, weight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textFaint),
          ],
        ),
      ),
    );
  }
}
