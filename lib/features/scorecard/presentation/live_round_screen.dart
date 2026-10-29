import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../../courses/domain/golf_hole.dart';
import '../../courses/domain/tee_set.dart';
import '../../courses/presentation/course_providers.dart';
import '../../handicap/domain/handicap_calculator.dart';
import '../../rounds/domain/round_player.dart';
import '../../rounds/presentation/round_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../../core/widgets/hole_artwork.dart';
import '../../rounds/domain/golf_round.dart';
import '../domain/hole_score.dart';
import 'score_providers.dart';

class LiveRoundScreen extends ConsumerStatefulWidget {
  const LiveRoundScreen({required this.roundId, super.key});

  final String roundId;

  @override
  ConsumerState<LiveRoundScreen> createState() => _LiveRoundScreenState();
}

class _LiveRoundScreenState extends ConsumerState<LiveRoundScreen> {
  int _strokes = 4;
  int _putts = 2;
  int _penalties = 0;
  int? _loadedHole;
  bool _saving = false;
  bool _completing = false;

  void _loadExistingScore(int holeNumber, HoleScore? score, int par) {
    if (_loadedHole == holeNumber) return;
    _loadedHole = holeNumber;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _strokes = score?.strokes ?? par;
        _putts = score?.putts ?? 2;
        _penalties = score?.penaltyStrokes ?? 0;
      });
    });
  }

  Future<void> _saveScore(int holeNumber) async {
    setState(() => _saving = true);

    try {
      await ref
          .read(scoreRepositoryProvider)
          .saveMyScore(
            roundId: widget.roundId,
            holeNumber: holeNumber,
            strokes: _strokes,
            putts: _putts,
            penaltyStrokes: _penalties,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Score saved.')));
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeSharedHole(int currentHole, int delta) async {
    final next = currentHole + delta;
    if (next < 1 || next > 18) return;

    try {
      await ref
          .read(roundRepositoryProvider)
          .setCurrentHole(roundId: widget.roundId, holeNumber: next);
      _loadedHole = null;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _completeRound() async {
    setState(() => _completing = true);

    try {
      await ref.read(roundRepositoryProvider).completeRound(widget.roundId);

      if (mounted) {
        context.go('/rounds/${widget.roundId}/leaderboard');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roundState = ref.watch(roundProvider(widget.roundId));
    final playersState = ref.watch(roundPlayersProvider(widget.roundId));
    final scoresState = ref.watch(roundScoresProvider(widget.roundId));
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Live round'),
        actions: [
          IconButton(
            tooltip: 'Leaderboard',
            onPressed: () =>
                context.push('/rounds/${widget.roundId}/leaderboard'),
            icon: const Icon(Icons.leaderboard_outlined),
          ),
          IconButton(
            tooltip: 'Scorecard',
            onPressed: () =>
                context.push('/rounds/${widget.roundId}/scorecard'),
            icon: const Icon(Icons.table_chart_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: roundState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (round) {
            if (round == null) {
              return const Center(child: Text('Round not found.'));
            }

            if (round.isCompleted) {
              return const Center(child: Text('This round is complete.'));
            }

            final holesState = ref.watch(courseHolesProvider(round.courseId));
            final teesState = ref.watch(courseTeeSetsProvider(round.courseId));

            return holesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('$error')),
              data: (holes) {
                final hole = _holeForNumber(holes, round.currentHole);
                if (hole == null) {
                  return const Center(child: Text('Hole data unavailable.'));
                }

                return teesState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('$error')),
                  data: (tees) {
                    final tee = _teeForId(tees, round.teeSetId);

                    return playersState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          Center(child: Text('$error')),
                      data: (players) {
                        final me = _playerForId(players, userId);

                        return scoresState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) =>
                              Center(child: Text('$error')),
                          data: (scores) {
                            final existingScore = _scoreFor(
                              scores,
                              userId,
                              round.currentHole,
                            );

                            _loadExistingScore(
                              round.currentHole,
                              existingScore,
                              hole.par,
                            );

                            final handicapIndex = me?.handicapIndex;
                            final courseHandicap =
                                handicapIndex != null && tee != null
                                ? HandicapCalculator.courseHandicap(
                                    handicapIndex: handicapIndex,
                                    slopeRating: tee.slopeRating,
                                    courseRating: tee.courseRating,
                                    par: tee.par,
                                  )
                                : null;

                            final playingHandicap = courseHandicap == null
                                ? null
                                : HandicapCalculator.playingHandicap(
                                    courseHandicap: courseHandicap,
                                  );

                            final strokesReceived = playingHandicap == null
                                ? 0
                                : HandicapCalculator.strokesReceivedOnHole(
                                    playingHandicap: playingHandicap,
                                    strokeIndex: hole.strokeIndex,
                                  );

                            final gross = _strokes + _penalties;
                            final net = HandicapCalculator.netHoleScore(
                              grossScore: gross,
                              strokesReceived: strokesReceived,
                            );

                            final isHost = round.hostUserId == userId;

                            return _HoleView(
                              key: ValueKey(hole.number),
                              roundId: widget.roundId,
                              round: round,
                              hole: hole,
                              tee: tee,
                              players: players,
                              scores: scores,
                              userId: userId,
                              isHost: isHost,
                              playingHandicap: playingHandicap,
                              strokesReceived: strokesReceived,
                              gross: gross,
                              net: net,
                              strokes: _strokes,
                              putts: _putts,
                              penalties: _penalties,
                              saving: _saving,
                              completing: _completing,
                              onStrokes: (value) =>
                                  setState(() => _strokes = value),
                              onPutts: (value) =>
                                  setState(() => _putts = value),
                              onPenalties: (value) =>
                                  setState(() => _penalties = value),
                              onSave: () => _saveScore(round.currentHole),
                              onMoveHole: (delta) =>
                                  _changeSharedHole(round.currentHole, delta),
                              onComplete: _completeRound,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  GolfHole? _holeForNumber(List<GolfHole> holes, int number) {
    for (final hole in holes) {
      if (hole.number == number) return hole;
    }
    return null;
  }

  TeeSet? _teeForId(List<TeeSet> tees, String teeId) {
    for (final tee in tees) {
      if (tee.id == teeId) return tee;
    }
    return null;
  }

  RoundPlayer? _playerForId(List<RoundPlayer> players, String? userId) {
    if (userId == null) return null;

    for (final player in players) {
      if (player.userId == userId) return player;
    }
    return null;
  }

  HoleScore? _scoreFor(
    List<HoleScore> scores,
    String? playerId,
    int holeNumber,
  ) {
    if (playerId == null) return null;

    for (final score in scores) {
      if (score.playerId == playerId && score.holeNumber == holeNumber) {
        return score;
      }
    }
    return null;
  }
}

/// The scoring screen itself.
///
/// Everything here is sized for the course, not the sofa: 60dp steppers, a
/// row of quick-tap chips so a 6 is one tap rather than two, and pure white
/// numerals on near-black so the card stays readable in direct sun.
class _HoleView extends StatelessWidget {
  const _HoleView({
    super.key,
    required this.roundId,
    required this.round,
    required this.hole,
    required this.tee,
    required this.players,
    required this.scores,
    required this.userId,
    required this.isHost,
    required this.playingHandicap,
    required this.strokesReceived,
    required this.gross,
    required this.net,
    required this.strokes,
    required this.putts,
    required this.penalties,
    required this.saving,
    required this.completing,
    required this.onStrokes,
    required this.onPutts,
    required this.onPenalties,
    required this.onSave,
    required this.onMoveHole,
    required this.onComplete,
  });

  final String roundId;
  final GolfRound round;
  final GolfHole hole;
  final TeeSet? tee;
  final List<RoundPlayer> players;
  final List<HoleScore> scores;
  final String? userId;
  final bool isHost;
  final int? playingHandicap;
  final int strokesReceived;
  final int gross;
  final int net;
  final int strokes;
  final int putts;
  final int penalties;
  final bool saving;
  final bool completing;
  final ValueChanged<int> onStrokes;
  final ValueChanged<int> onPutts;
  final ValueChanged<int> onPenalties;
  final VoidCallback onSave;
  final ValueChanged<int> onMoveHole;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final toPar = gross - hole.par;
    final officialDistance = tee?.holeDistancesMeters[hole.number];
    final gpsEstimate = hole.estimatedStraightLineMeters;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        // --- Hole header ----------------------------------------------------
        ChristianGolfersCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      round.courseName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.label(10),
                    ),
                  ),
                  MetaPill(
                    'HCP ${playingHandicap?.toString() ?? '--'}',
                    colour: AppTheme.gold,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StepArrow(
                    icon: Icons.chevron_left_rounded,
                    enabled: isHost && hole.number > 1,
                    onTap: () => onMoveHole(-1),
                    semantic: 'Previous hole',
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('HOLE', style: AppTheme.label(10)),
                        Text(
                          '${hole.number}',
                          style: AppTheme.numeric(64, colour: AppTheme.gold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MetaPill('Par ${hole.par}'),
                            const SizedBox(width: 6),
                            MetaPill('SI ${hole.strokeIndex}'),
                            if (strokesReceived > 0) ...[
                              const SizedBox(width: 6),
                              MetaPill(
                                '+$strokesReceived shot'
                                '${strokesReceived == 1 ? '' : 's'}',
                                colour: AppTheme.gold,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StepArrow(
                    icon: Icons.chevron_right_rounded,
                    enabled: isHost && hole.number < 18,
                    onTap: () => onMoveHole(1),
                    semantic: 'Next hole',
                  ),
                ],
              ),
              if (!isHost) ...[
                const SizedBox(height: 10),
                Text(
                  'The host moves the group to the next hole.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(11.5, colour: AppTheme.textFaint),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),
        HoleArtwork(
          hole: hole,
          seed: '${round.courseId}-${hole.number}',
          height: 190,
        ),
        const SizedBox(height: 8),
        Text(
          officialDistance != null
              ? 'Hole ${hole.number}: $officialDistance m from ${tee?.colour ?? 'selected'} tees'
              : gpsEstimate != null
              ? 'About $gpsEstimate m straight-line from the tee · GPS estimate, not official yardage'
              : 'Official hole distance has not been supplied.',
          textAlign: TextAlign.center,
          style: AppTheme.body(11, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        _ShotAdviceCard(key: ValueKey('advice-${hole.number}')),

        const SizedBox(height: 14),

        // --- Running total --------------------------------------------------
        Row(
          children: [
            Expanded(
              child: _Readout(label: 'Gross', value: '$gross', accent: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Readout(
                label: 'To par',
                value: toPar == 0
                    ? 'E'
                    : toPar > 0
                    ? '+$toPar'
                    : '$toPar',
                colour: toPar <= 0 ? AppTheme.positive : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Readout(label: 'Net', value: '$net'),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // --- Entry ----------------------------------------------------------
        ChristianGolfersCard(
          child: ScoreStepper(
            label: 'Strokes',
            value: strokes,
            min: 1,
            max: 20,
            onChanged: onStrokes,
          ),
        ),
        const SizedBox(height: 12),
        ChristianGolfersCard(
          child: ScoreStepper(
            label: 'Putts',
            value: putts,
            min: 0,
            max: 10,
            quickValues: const [0, 1, 2, 3, 4, 5],
            lastQuickIsPlus: true,
            onChanged: onPutts,
          ),
        ),
        const SizedBox(height: 12),
        ChristianGolfersCard(
          child: ScoreStepper(
            label: 'Penalties',
            value: penalties,
            min: 0,
            max: 10,
            quickValues: const [0, 1, 2, 3],
            lastQuickIsPlus: true,
            onChanged: onPenalties,
          ),
        ),

        const SizedBox(height: 20),
        GoldButton(
          label: 'Save hole ${hole.number}',
          icon: Icons.check_rounded,
          busy: saving,
          onPressed: saving ? null : onSave,
        ),

        const SizedBox(height: 26),
        const SectionHeader('The group'),
        _GroupStandings(
          players: players,
          scores: scores,
          userId: userId,
          currentHole: hole.number,
        ),

        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/rounds/$roundId/scorecard'),
                icon: const Icon(Icons.grid_on_rounded, size: 17),
                label: const Text('CARD'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/rounds/$roundId/leaderboard'),
                icon: const Icon(Icons.leaderboard_rounded, size: 17),
                label: const Text('LEADERS'),
              ),
            ),
          ],
        ),

        if (isHost) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: completing ? null : onComplete,
            icon: const Icon(Icons.flag_circle_rounded, size: 18),
            label: Text(
              completing ? 'Finishing...' : 'Finish this round for everyone',
            ),
          ),
        ],
      ],
    );
  }
}

class _ShotAdviceCard extends StatefulWidget {
  const _ShotAdviceCard({super.key});

  @override
  State<_ShotAdviceCard> createState() => _ShotAdviceCardState();
}

class _ShotAdviceCardState extends State<_ShotAdviceCard> {
  final _distanceController = TextEditingController();
  String _lie = 'Fairway';

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  String _clubFor(int metres) {
    if (metres >= 205) return 'fairway wood or hybrid';
    if (metres >= 175) return 'hybrid or 4–5 iron';
    if (metres >= 145) return '5–7 iron';
    if (metres >= 115) return '7–9 iron';
    if (metres >= 80) return 'pitching or gap wedge';
    return 'gap or sand wedge';
  }

  String get _tip {
    final metres = int.tryParse(_distanceController.text.trim());
    switch (_lie) {
      case 'Trees':
        return 'Aim through the widest clear gap and get back to the fairway first. Choose the most reliable punch-out club; don’t force a shot through branches.';
      case 'Bushes':
        return 'Look for a safe route back to playable ground. Check the course’s relief rules before taking an unplayable-ball penalty; don’t try to hit through dense growth.';
      case 'Bunker':
        return 'From a greenside bunker, use a sand wedge and splash the ball out. From a fairway bunker, pick a club you can strike cleanly below the lip.';
      case 'Rough':
        return 'Grass can reduce contact and spin. Take enough loft to clear the rough, and consider one more club if the lie is sitting down.';
      default:
        return metres == null || metres < 1
            ? 'Enter your measured distance to get a club starting point. If the line is clear, favour the safe centre of the green.'
            : 'For about $metres m, try a ${_clubFor(metres)} as a starting point. Aim for the safe centre of the green and use your own stock carry distance.';
    }
  }

  @override
  Widget build(BuildContext context) => ChristianGolfersCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Second-shot helper',
          style: AppTheme.body(15, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your lie and enter the measured distance to the green.',
          style: AppTheme.body(11.5, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _lie,
                decoration: const InputDecoration(labelText: 'Ball lie'),
                items: const ['Fairway', 'Rough', 'Bunker', 'Trees', 'Bushes']
                    .map(
                      (lie) => DropdownMenuItem(value: lie, child: Text(lie)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _lie = value ?? 'Fairway'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'To green (m)',
                  hintText: 'e.g. 145',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_tip, style: AppTheme.body(12.5)),
        const SizedBox(height: 6),
        Text(
          'General guide only. Check the lie, wind, obstacles and your own club carry.',
          style: AppTheme.body(10.5, colour: AppTheme.textFaint),
        ),
      ],
    ),
  );
}

class _StepArrow extends StatelessWidget {
  const _StepArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.semantic,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      enabled: enabled,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Material(
          color: enabled ? AppTheme.cardRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onTap : null,
            child: Icon(
              icon,
              size: 26,
              color: enabled ? AppTheme.gold : AppTheme.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    this.colour,
    this.accent = false,
  });

  final String label;
  final String value;
  final Color? colour;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: AppTheme.tileRadius,
        border: Border.all(color: accent ? AppTheme.goldLine : AppTheme.line),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: AppTheme.label(9.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.numeric(
              26,
              colour: colour ?? (accent ? AppTheme.gold : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where everyone stands, through the holes played so far.
class _GroupStandings extends StatelessWidget {
  const _GroupStandings({
    required this.players,
    required this.scores,
    required this.userId,
    required this.currentHole,
  });

  final List<RoundPlayer> players;
  final List<HoleScore> scores;
  final String? userId;
  final int currentHole;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (var index = 0; index < players.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _GroupRow(
              player: players[index],
              scores: scores,
              isMe: players[index].userId == userId,
              currentHole: currentHole,
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.player,
    required this.scores,
    required this.isMe,
    required this.currentHole,
  });

  final RoundPlayer player;
  final List<HoleScore> scores;
  final bool isMe;
  final int currentHole;

  @override
  Widget build(BuildContext context) {
    final mine = scores.where((s) => s.playerId == player.userId).toList();
    final played = mine.length;
    final total = mine.fold<int>(0, (sum, s) => sum + s.totalStrokes);
    final thisHole = mine.where((s) => s.holeNumber == currentHole).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GolferAvatar(name: player.displayName, size: 36, highlight: isMe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe
                            ? '${player.displayName} (you)'
                            : player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(14, weight: FontWeight.w700),
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 6),
                      const MetaPill('Host', colour: AppTheme.gold),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  played == 0
                      ? 'No holes in yet'
                      : '$played ${played == 1 ? 'hole' : 'holes'} · $total strokes',
                  style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (thisHole.isEmpty)
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.line),
              ),
              child: Text(
                '--',
                style: AppTheme.numeric(13, colour: AppTheme.textFaint),
              ),
            )
          else
            Text(
              '${thisHole.first.totalStrokes}',
              style: AppTheme.numeric(22, colour: AppTheme.gold),
            ),
        ],
      ),
    );
  }
}
