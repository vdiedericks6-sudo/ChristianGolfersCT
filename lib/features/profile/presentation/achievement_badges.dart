import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';

// The backgrounds are the club's original course photographs. Decoration is
// rendered in Flutter so the same images work at different device sizes.
const _badgeArtwork = <String, (String, IconData)>{
  'first_round': ('assets/images/badge_first_round.jpg', Icons.flag_rounded),
  'five_rounds': ('assets/images/badge_five_rounds.jpeg', Icons.groups_rounded),
  'birdie': ('assets/images/badge_birdie.jpeg', Icons.sports_golf_rounded),
  'under_handicap': ('assets/images/badge_under_handicap.jpeg', Icons.emoji_events_rounded),
  'index_updated': ('assets/images/badge_index_updated.jpeg', Icons.edit_note_rounded),
  'index_improved': ('assets/images/badge_index_improved.jpeg', Icons.trending_up_rounded),
};

final achievementBadgesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  if (ref.watch(demoBackendProvider) != null) return const [];
  if (ref.watch(currentUserIdProvider) == null) return const [];
  final data = await ref.watch(supabaseClientProvider).rpc('my_achievement_badges');
  return (data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
});

class AchievementBadges extends ConsumerWidget {
  const AchievementBadges({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(achievementBadgesProvider);
    return ChristianGolfersCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your badges', style: AppTheme.display(18)),
      const SizedBox(height: 6),
      Text('Celebrate confirmed rounds and handicap updates.', style: AppTheme.body(12, colour: AppTheme.textMuted)),
      const SizedBox(height: 12),
      badges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => TextButton(onPressed: () => ref.invalidate(achievementBadgesProvider), child: const Text('Could not load badges. Retry')),
        data: (items) => items.isEmpty ? const Text('Badges are unavailable in preview mode.') : Column(children: [
          for (final item in items) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _BadgeArtwork(id: '${item['id']}', earned: item['earned'] == true),
            title: Text('${item['title']}'),
            subtitle: Text('${item['description']}'),
            trailing: Text(item['earned'] == true ? 'Earned' : '${item['progress']}/${item['target']}'),
          ),
        ]),
      ),
    ]));
  }
}

class _BadgeArtwork extends StatelessWidget {
  const _BadgeArtwork({required this.id, required this.earned});
  final String id;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final artwork = _badgeArtwork[id];
    if (artwork == null) {
      return Icon(earned ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
          color: earned ? AppTheme.gold : AppTheme.textMuted);
    }
    return ExcludeSemantics(
      child: SizedBox(width: 58, height: 58, child: Stack(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: earned ? AppTheme.gold : AppTheme.textMuted, width: 2)),
          child: ClipOval(child: ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: earned ? 0.12 : 0.58), BlendMode.darken),
            child: Image.asset(artwork.$1, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined)),
          )),
        ),
        Positioned(right: 0, bottom: 0, child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppTheme.cardSecondary, shape: BoxShape.circle,
            border: Border.all(color: earned ? AppTheme.gold : AppTheme.textMuted)),
          child: Icon(earned ? artwork.$2 : Icons.lock_rounded, size: 13,
            color: earned ? AppTheme.gold : AppTheme.textMuted),
        )),
      ])),
    );
  }
}
