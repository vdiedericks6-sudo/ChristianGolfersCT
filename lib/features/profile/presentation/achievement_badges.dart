import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';

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
            leading: Icon(item['earned'] == true ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: item['earned'] == true ? AppTheme.gold : AppTheme.textMuted),
            title: Text('${item['title']}'),
            subtitle: Text('${item['description']}'),
            trailing: Text(item['earned'] == true ? 'Earned' : '${item['progress']}/${item['target']}'),
          ),
        ]),
      ),
    ]));
  }
}
