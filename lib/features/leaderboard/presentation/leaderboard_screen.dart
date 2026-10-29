import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../history/domain/player_stats.dart';
import '../../history/domain/round_summary.dart';
import '../../history/presentation/history_providers.dart';

/// "Your golf": career numbers on top, round history underneath.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(roundHistoryProvider);
    final statsState = ref.watch(playerStatsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.refresh(roundHistoryProvider.future),
        child: historyState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.cloud_off_rounded, size: 56),
              const SizedBox(height: 14),
              Text(
                'Could not load your rounds.\n$error',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          data: (summaries) {
            final stats = statsState.valueOrNull ?? PlayerStats.empty;
            final played = summaries
                .where((summary) => summary.holesPlayed > 0)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  'Your golf',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                if (stats.isEmpty)
                  const _NoRoundsYet()
                else ...[
                  _StatsGrid(stats: stats),
                  const SizedBox(height: 20),
                  if (stats.breakdown.isNotEmpty) ...[
                    _ScoreMix(breakdown: stats.breakdown),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Round history',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  for (final summary in played)
                    _RoundHistoryTile(summary: summary),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoRoundsYet extends StatelessWidget {
  const _NoRoundsYet();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.golf_course_rounded, size: 56),
            const SizedBox(height: 14),
            const Text(
              'No rounds yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Play a round and your scoring average, best round and putting '
              'numbers will build up here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/play'),
              icon: const Icon(Icons.sports_golf_rounded),
              label: const Text('Start a round'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final PlayerStats stats;

  String _oneDecimal(double? value) =>
      value == null ? '--' : value.toStringAsFixed(1);

  String _relativeToPar(int? value) {
    if (value == null) return '--';
    if (value == 0) return 'E';
    return value > 0 ? '+$value' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        label: 'Rounds',
        value: '${stats.roundsPlayed}',
        caption: stats.fullRoundsPlayed == stats.roundsPlayed
            ? 'all 18 holes'
            : '${stats.fullRoundsPlayed} full',
      ),
      _StatTile(
        label: 'Scoring average',
        value: _oneDecimal(stats.scoringAverage),
        caption: stats.trend == null
            ? 'over 18 holes'
            : stats.trend! < 0
                ? '${_oneDecimal(stats.trend!.abs())} better lately'
                : '${_oneDecimal(stats.trend!)} worse lately',
        highlight: stats.trend != null && stats.trend! < 0,
      ),
      _StatTile(
        label: 'Best round',
        value: stats.bestGross == null ? '--' : '${stats.bestGross}',
        caption: stats.bestToPar == null
            ? 'gross'
            : '${_relativeToPar(stats.bestToPar)} to par',
      ),
      _StatTile(
        label: 'Putts',
        value: _oneDecimal(stats.averagePutts),
        caption: 'per round',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: tiles,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.mintStrong : AppTheme.mint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppTheme.forest,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ScoreMix extends StatelessWidget {
  const _ScoreMix({required this.breakdown});

  final Map<ScoreClass, int> breakdown;

  static const _labels = <ScoreClass, String>{
    ScoreClass.eagleOrBetter: 'Eagles+',
    ScoreClass.birdie: 'Birdies',
    ScoreClass.par: 'Pars',
    ScoreClass.bogey: 'Bogeys',
    ScoreClass.doubleOrWorse: 'Doubles+',
  };

  static const _colors = <ScoreClass, Color>{
    ScoreClass.eagleOrBetter: Color(0xFF1B7F5C),
    ScoreClass.birdie: Color(0xFF3FA97F),
    ScoreClass.par: AppTheme.gold,
    ScoreClass.bogey: Color(0xFFCE8A4A),
    ScoreClass.doubleOrWorse: Color(0xFFB4553F),
  };

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return const SizedBox.shrink();

    final ordered = ScoreClass.values
        .where((label) => (breakdown[label] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score mix',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final label in ordered)
                  Expanded(
                    flex: breakdown[label]!,
                    child: ColoredBox(color: _colors[label]!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final label in ordered)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[label],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_labels[label]} ${breakdown[label]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _RoundHistoryTile extends StatelessWidget {
  const _RoundHistoryTile({required this.summary});

  final RoundSummary summary;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _date {
    final at = summary.playedAt;
    return '${at.day} ${_months[at.month - 1]} ${at.year}';
  }

  @override
  Widget build(BuildContext context) {
    final toPar = summary.toPar;
    final inProgress = !summary.round.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        onTap: () => context.push('/rounds/${summary.round.id}/scorecard'),
        title: Text(
          summary.round.courseName.isEmpty
              ? 'Round'
              : summary.round.courseName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          inProgress
              ? '$_date  ·  in progress, ${summary.holesPlayed} holes'
              : '$_date  ·  ${summary.holesPlayed} holes'
                  '${summary.putts > 0 ? '  ·  ${summary.putts} putts' : ''}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${summary.grossStrokes}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.forest,
              ),
            ),
            if (toPar != null)
              Text(
                toPar == 0
                    ? 'E'
                    : toPar > 0
                        ? '+$toPar'
                        : '$toPar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: toPar <= 0
                      ? const Color(0xFF1B7F5C)
                      : AppTheme.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
