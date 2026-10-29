import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../courses/domain/tee_set.dart';
import '../../courses/presentation/course_providers.dart';
import '../../rounds/presentation/round_providers.dart';
import '../../scorecard/presentation/score_providers.dart';
import '../domain/leaderboard_calculator.dart';
import '../domain/leaderboard_entry.dart';

class RoundLeaderboardScreen extends ConsumerStatefulWidget {
  const RoundLeaderboardScreen({required this.roundId, super.key});

  final String roundId;

  @override
  ConsumerState<RoundLeaderboardScreen> createState() =>
      _RoundLeaderboardScreenState();
}

class _RoundLeaderboardScreenState
    extends ConsumerState<RoundLeaderboardScreen> {
  LeaderboardMode _mode = LeaderboardMode.net;

  @override
  Widget build(BuildContext context) {
    final roundState = ref.watch(roundProvider(widget.roundId));
    final playersState = ref.watch(roundPlayersProvider(widget.roundId));
    final scoresState = ref.watch(roundScoresProvider(widget.roundId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Leaderboard'),
      ),
      body: SafeArea(
        child: roundState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Unable to load round.\n$error')),
          data: (round) {
            if (round == null) {
              return const Center(child: Text('Round not found.'));
            }

            final holesState = ref.watch(courseHolesProvider(round.courseId));
            final teesState = ref.watch(courseTeeSetsProvider(round.courseId));

            return holesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('$error')),
              data: (holes) => teesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: Text('$error')),
                data: (tees) {
                  TeeSet? teeSet;
                  for (final tee in tees) {
                    if (tee.id == round.teeSetId) {
                      teeSet = tee;
                      break;
                    }
                  }

                  return playersState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(child: Text('$error')),
                    data: (players) => scoresState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          Center(child: Text('$error')),
                      data: (scores) {
                        final entries = LeaderboardCalculator.calculate(
                          players: players,
                          scores: scores,
                          holes: holes,
                          teeSet: teeSet,
                          mode: _mode,
                          currentUserId: currentUserId,
                        );

                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                              round.courseName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${round.teeSetName} tees · '
                              '${round.status == 'active' ? 'Live' : 'Round ${round.status}'}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Primary competition format: net stroke play. '
                              'Gross score is available as a reference.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 20),
                            SegmentedButton<LeaderboardMode>(
                              segments: const [
                                ButtonSegment(
                                  value: LeaderboardMode.net,
                                  label: Text('Net stroke play'),
                                  icon: Icon(Icons.calculate_outlined),
                                ),
                                ButtonSegment(
                                  value: LeaderboardMode.gross,
                                  label: Text('Gross score'),
                                  icon: Icon(Icons.sports_golf_outlined),
                                ),
                              ],
                              selected: {_mode},
                              onSelectionChanged: (selection) {
                                setState(() => _mode = selection.first);
                              },
                            ),
                            const SizedBox(height: 18),
                            if (entries.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No players are available for this leaderboard.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _LeaderboardCard(
                                    entry: entry,
                                    mode: _mode,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              'Leaderboard updates automatically as confirmed scores are saved.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entry, required this.mode});

  final LeaderboardEntry entry;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = mode == LeaderboardMode.net
        ? entry.netTotal
        : entry.grossTotal;
    final toPar = mode == LeaderboardMode.net
        ? entry.netToPar
        : entry.grossToPar;

    return Card(
      child: Container(
        decoration: entry.isCurrentUser
            ? BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(22),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  _positionText(entry.position),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                child: Text(
                  entry.displayName.isEmpty
                      ? '?'
                      : entry.displayName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (entry.isCurrentUser) ...[
                          const SizedBox(width: 8),
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text('You'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.holesCompleted} holes completed',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _toParText(toPar),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    entry.holesCompleted == 0 ? '--' : '$total',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _positionText(int position) {
    if (position <= 0) return '-';
    return '$position';
  }

  static String _toParText(int value) {
    if (value == 0) return 'E';
    if (value > 0) return '+$value';
    return '$value';
  }
}
