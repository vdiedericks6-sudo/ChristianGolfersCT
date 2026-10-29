import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              final profile = profileState.valueOrNull;
              if (profile != null) {
                context.push('/edit-profile', extra: profile);
              }
            },
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load your profile.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) {
          final name = profile?.displayName ?? 'David Erasmus';
          final hcp = profile?.estimatedHandicapIndex?.toStringAsFixed(1) ?? '12.4';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              children: [
                // Avatar matching Screen 6
                GolferAvatar(
                  name: name,
                  photoUrl: profile?.photoUrl,
                  size: 80,
                  highlight: true,
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  name,
                  style: AppTheme.display(22, colour: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),

                // Subtitle / League & Handicap Index
                Text(
                  'League A • Handicap $hcp',
                  style: AppTheme.body(12.5, colour: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 3 Column Stats Card matching Screen 6
                ChristianGolfersCard(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Handicap',
                          value: hcp,
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: AppTheme.line,
                      ),
                      Expanded(
                        child: StatTile(
                          label: 'Rounds',
                          value: '8',
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: AppTheme.line,
                      ),
                      Expanded(
                        child: StatTile(
                          label: 'Wins',
                          value: '3',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Menu Options matching Screen 6
                _ProfileMenuItemScreen6(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Details',
                  onTap: () {
                    if (profile != null) {
                      context.push('/edit-profile', extra: profile);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _ProfileMenuItemScreen6(
                  icon: Icons.show_chart_rounded,
                  title: 'Handicap History',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _ProfileMenuItemScreen6(
                  icon: Icons.emoji_events_outlined,
                  title: 'My League',
                  onTap: () => context.go('/leagues'),
                ),
                const SizedBox(height: 10),
                _ProfileMenuItemScreen6(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _ProfileMenuItemScreen6(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => context.push('/more'),
                ),
                const SizedBox(height: 10),
                _ProfileMenuItemScreen6(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileMenuItemScreen6 extends StatelessWidget {
  const _ProfileMenuItemScreen6({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.cardSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.body(14, weight: FontWeight.w700),
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
