import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../courses/domain/golf_hole.dart';
import '../../courses/domain/tee_set.dart';
import '../../courses/presentation/course_providers.dart';
import '../../handicap/domain/handicap_calculator.dart';
import '../../rounds/domain/round_player.dart';
import '../../rounds/presentation/round_providers.dart';
import '../domain/hole_score.dart';
import 'score_providers.dart';

/// The group's card, laid out the way a paper scorecard is: holes across,
/// players down, front nine and back nine totalled separately.
class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({required this.roundId, super.key});

  final String roundId;

  static const _cell = 40.0;
  static const _nameColumn = 108.0;
  static const _rowHeight = 46.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundState = ref.watch(roundProvider(roundId));
    final playersState = ref.watch(roundPlayersProvider(roundId));
    final scoresState = ref.watch(roundScoresProvider(roundId));
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('SCORECARD'),
      ),
      body: SafeArea(
        child: roundState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => LoadFailure(what: 'the round', error: error),
          data: (round) {
            if (round == null) {
              return const EmptyState(
                icon: Icons.help_outline_rounded,
                title: 'Round not found',
                message: 'It may have been removed by the host.',
              );
            }

            final holesState = ref.watch(courseHolesProvider(round.courseId));
            final teesState = ref.watch(courseTeeSetsProvider(round.courseId));

            return holesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => LoadFailure(what: 'the holes', error: e),
              data: (holes) => teesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => LoadFailure(what: 'the tees', error: e),
                data: (tees) => playersState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => LoadFailure(what: 'the players', error: e),
                  data: (players) => scoresState.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => LoadFailure(what: 'the scores', error: e),
                    data: (scores) {
                      if (holes.isEmpty) {
                        return const EmptyState(
                          icon: Icons.grid_off_rounded,
                          title: 'No hole data',
                          message:
                              'This course has no hole-by-hole information '
                              'yet, so a card cannot be drawn for it.',
                        );
                      }

                      return _Card(
                        round: round.courseName,
                        teeName: round.teeSetName,
                        holes: holes,
                        players: players,
                        scores: scores,
                        tee: _teeForId(tees, round.teeSetId),
                        userId: userId,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  TeeSet? _teeForId(List<TeeSet> tees, String teeSetId) {
    for (final tee in tees) {
      if (tee.id == teeSetId) return tee;
    }
    return tees.isEmpty ? null : tees.first;
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.round,
    required this.teeName,
    required this.holes,
    required this.players,
    required this.scores,
    required this.tee,
    required this.userId,
  });

  final String round;
  final String teeName;
  final List<GolfHole> holes;
  final List<RoundPlayer> players;
  final List<HoleScore> scores;
  final TeeSet? tee;
  final String? userId;

  List<GolfHole> get _front =>
      holes.where((h) => h.number <= 9).toList()..sort(_byNumber);

  List<GolfHole> get _back =>
      holes.where((h) => h.number > 9).toList()..sort(_byNumber);

  static int _byNumber(GolfHole a, GolfHole b) => a.number.compareTo(b.number);

  int? _strokesFor(String playerId, int holeNumber) {
    for (final score in scores) {
      if (score.playerId == playerId && score.holeNumber == holeNumber) {
        return score.totalStrokes;
      }
    }
    return null;
  }

  int _playingHandicapFor(RoundPlayer player) {
    final index = player.handicapIndex;
    final teeSet = tee;
    if (index == null || teeSet == null) return 0;

    return HandicapCalculator.playingHandicap(
      courseHandicap: HandicapCalculator.courseHandicap(
        handicapIndex: index,
        slopeRating: teeSet.slopeRating,
        courseRating: teeSet.courseRating,
        par: teeSet.par,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final front = _front;
    final back = _back;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(round.toUpperCase(), style: AppTheme.label(10)),
              const SizedBox(height: 4),
              Text('The card', style: AppTheme.display(28)),
              const SizedBox(height: 4),
              Text(
                '$teeName tees · ${holes.length} holes',
                style: AppTheme.body(12.5, colour: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (front.isNotEmpty) _grid(context, front, 'Out'),
        if (back.isNotEmpty) ...[
          const SizedBox(height: 16),
          _grid(context, back, 'In'),
        ],

        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: SectionHeader('Totals'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _Totals(
            holes: holes,
            players: players,
            scores: scores,
            userId: userId,
            playingHandicapFor: _playingHandicapFor,
            strokesFor: _strokesFor,
          ),
        ),

        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: _Legend(),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, List<GolfHole> nine, String totalLabel) {
    final total = nine.fold<int>(0, (sum, hole) => sum + hole.par);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky name column, so a row never loses its owner when scrolled.
        SizedBox(
          width: ScorecardScreen._nameColumn,
          child: Column(
            children: [
              _labelCell('Hole', muted: true),
              _labelCell('Par', muted: true),
              _labelCell('SI', muted: true),
              for (final player in players)
                _labelCell(
                  player.displayName,
                  highlight: player.userId == userId,
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 18),
            child: Column(
              children: [
                _row([
                  for (final hole in nine)
                    _cell(Text('${hole.number}', style: AppTheme.label(11))),
                  _cell(
                    Text(
                      totalLabel.toUpperCase(),
                      style: AppTheme.label(10, colour: AppTheme.gold),
                    ),
                  ),
                ]),
                _row([
                  for (final hole in nine)
                    _cell(
                      Text(
                        '${hole.par}',
                        style: AppTheme.numeric(
                          14,
                          colour: AppTheme.textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _cell(
                    Text(
                      '$total',
                      style: AppTheme.numeric(14, colour: AppTheme.gold),
                    ),
                  ),
                ]),
                _row([
                  for (final hole in nine)
                    _cell(
                      Text(
                        '${hole.strokeIndex}',
                        style: AppTheme.numeric(
                          12,
                          colour: AppTheme.textFaint,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _cell(const SizedBox.shrink()),
                ]),
                for (final player in players)
                  _row([
                    for (final hole in nine) _cell(_score(player, hole)),
                    _cell(_nineTotal(player, nine)),
                  ], highlight: player.userId == userId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _score(RoundPlayer player, GolfHole hole) {
    final strokes = _strokesFor(player.userId, hole.number);

    if (strokes == null) {
      return Text('·', style: AppTheme.numeric(16, colour: AppTheme.textFaint));
    }

    return ScoreBadge(strokes: strokes, par: hole.par, size: 32);
  }

  Widget _nineTotal(RoundPlayer player, List<GolfHole> nine) {
    var total = 0;
    var played = 0;

    for (final hole in nine) {
      final strokes = _strokesFor(player.userId, hole.number);
      if (strokes != null) {
        total += strokes;
        played++;
      }
    }

    if (played == 0) {
      return Text('·', style: AppTheme.numeric(16, colour: AppTheme.textFaint));
    }

    return Text(
      '$total',
      style: AppTheme.numeric(
        16,
        colour: played == nine.length ? AppTheme.gold : AppTheme.textMuted,
      ),
    );
  }

  Widget _row(List<Widget> cells, {bool highlight = false}) {
    return Container(
      height: ScorecardScreen._rowHeight,
      decoration: BoxDecoration(
        color: highlight ? AppTheme.cardRaised : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppTheme.line, width: 0.6),
        ),
      ),
      child: Row(children: cells),
    );
  }

  Widget _cell(Widget child) {
    return SizedBox(
      width: ScorecardScreen._cell,
      child: Center(child: child),
    );
  }

  Widget _labelCell(String text, {bool muted = false, bool highlight = false}) {
    return Container(
      height: ScorecardScreen._rowHeight,
      padding: const EdgeInsets.only(left: 18, right: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: highlight ? AppTheme.cardRaised : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppTheme.line, width: 0.6),
        ),
      ),
      child: Text(
        muted ? text.toUpperCase() : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: muted
            ? AppTheme.label(10)
            : AppTheme.body(
                12.5,
                weight: FontWeight.w700,
                colour: highlight ? AppTheme.gold : AppTheme.textPrimary,
              ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.holes,
    required this.players,
    required this.scores,
    required this.userId,
    required this.playingHandicapFor,
    required this.strokesFor,
  });

  final List<GolfHole> holes;
  final List<RoundPlayer> players;
  final List<HoleScore> scores;
  final String? userId;
  final int Function(RoundPlayer) playingHandicapFor;
  final int? Function(String, int) strokesFor;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var index = 0; index < players.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _totalRow(players[index]),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(RoundPlayer player) {
    final playing = playingHandicapFor(player);

    var gross = 0;
    var net = 0;
    var par = 0;
    var played = 0;

    for (final hole in holes) {
      final strokes = strokesFor(player.userId, hole.number);
      if (strokes == null) continue;

      final received = HandicapCalculator.strokesReceivedOnHole(
        playingHandicap: playing,
        strokeIndex: hole.strokeIndex,
      );

      gross += strokes;
      net += HandicapCalculator.netHoleScore(
        grossScore: strokes,
        strokesReceived: received,
      );
      par += hole.par;
      played++;
    }

    final isMe = player.userId == userId;
    final toPar = played == 0 ? null : gross - par;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          GolferAvatar(name: player.displayName, size: 34, highlight: isMe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${player.displayName} (you)' : player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(13.5, weight: FontWeight.w700),
                ),
                Text(
                  played == 0
                      ? 'No holes yet'
                      : '$played of ${holes.length} holes · playing off $playing',
                  style: AppTheme.body(11, colour: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          _figure('Gross', played == 0 ? '--' : '$gross', accent: true),
          const SizedBox(width: 14),
          _figure('Net', played == 0 ? '--' : '$net'),
          const SizedBox(width: 14),
          _figure(
            'To par',
            toPar == null
                ? '--'
                : toPar == 0
                ? 'E'
                : toPar > 0
                ? '+$toPar'
                : '$toPar',
            colour: toPar != null && toPar <= 0 ? AppTheme.positive : null,
          ),
        ],
      ),
    );
  }

  Widget _figure(
    String label,
    String value, {
    bool accent = false,
    Color? colour,
  }) {
    return SizedBox(
      width: 46,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label.toUpperCase(), style: AppTheme.label(8.5)),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTheme.numeric(
              17,
              colour: colour ?? (accent ? AppTheme.gold : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Golf's own notation carries the meaning here: circles are under par,
/// squares over. Colour reinforces but never stands alone.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _item(const ScoreBadge(strokes: 2, par: 4, size: 26), 'Eagle'),
        _item(const ScoreBadge(strokes: 3, par: 4, size: 26), 'Birdie'),
        _item(const ScoreBadge(strokes: 4, par: 4, size: 26), 'Par'),
        _item(const ScoreBadge(strokes: 5, par: 4, size: 26), 'Bogey'),
        _item(const ScoreBadge(strokes: 6, par: 4, size: 26), 'Double +'),
      ],
    );
  }

  Widget _item(Widget badge, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 7),
        Text(label, style: AppTheme.body(11.5, colour: AppTheme.textMuted)),
      ],
    );
  }
}
