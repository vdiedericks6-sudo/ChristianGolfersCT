import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
import '../domain/score_voice_parser.dart';
import 'score_providers.dart';
import 'score_outbox_provider.dart';
import '../data/score_outbox.dart';
import 'green_distance_card.dart';

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
  int _sandShots = 0;
  String? _fairway;
  bool? _greenInRegulation;
  int? _loadedHole;
  String? _loadedPlayerId;
  String? _loadedScoreVersion;
  bool _loadedScoreExists = false;
  DateTime? _loadedScoreUpdatedAt;
  String? _selectedPlayerId;
  bool _saving = false;
  bool _completing = false;
  int _editRevision = 0;
  bool _dirty = false;
  int? _localHole;
  bool _movingHole = false;

  Future<void> _reviewQueued(QueuedScore item) async {
    if (item.status != QueuedScoreStatus.blocked) return;
    try {
      final row = await ref.read(supabaseClientProvider).from('hole_scores').select().eq('round_id', item.roundId).eq('player_id', item.playerId).eq('hole_number', item.holeNumber).maybeSingle().timeout(const Duration(seconds: 10));
      final server = row == null ? null : HoleScore.fromJson(row);
      if (!mounted) return;
      final decision = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Review unsynced score'),
        content: Text('Hole ${item.holeNumber}: this phone has ${item.strokes + item.penaltyStrokes} gross. Server: ${server == null ? 'no score' : '${server.totalStrokes} gross'}.\n\n${item.error ?? 'Score needs review.'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, 'server'), child: const Text('Keep server score')), TextButton(onPressed: () => Navigator.pop(ctx, 'retry'), child: const Text('Submit phone score'))],
      ));
      final outbox = ref.read(scoreOutboxProvider);
      if (decision == 'server') await outbox.discard(item.id);
      if (decision == 'retry') await outbox.retryBlocked(item.id, expectedExists: server != null, expectedUpdatedAt: server?.updatedAt);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connect to review this score: $error')));
    }
  }

  void _showQueue(List<QueuedScore> items) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Scores waiting to sync'),
      content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: [for (final item in items) ListTile(
        title: Text('Hole ${item.holeNumber} · ${item.strokes + item.penaltyStrokes} gross'),
        subtitle: Text(item.status == QueuedScoreStatus.blocked ? 'Needs review: ${item.error ?? ''}' : 'Waiting for connection'),
        onTap: item.status == QueuedScoreStatus.blocked ? () { Navigator.pop(ctx); _reviewQueued(item); } : null,
      )])),
      actions: [TextButton(onPressed: () { ref.read(scoreOutboxProvider).sync(); Navigator.pop(ctx); }, child: const Text('Retry sync')), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
  final _speech = SpeechToText();
  bool _listening = false;
  bool _voiceBusy = false;
  String _voiceLanguage = 'en';
  String _voiceMessage = 'Say “Hole seven, six strokes”.';

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleVoice(int holeNumber, String playerId) async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (_voiceBusy) return;
    setState(() => _voiceBusy = true);
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _listening = false;
              _voiceMessage =
                  'Could not hear a score. Try again or use the buttons.';
            });
          }
        },
      );
      if (!available) {
        if (mounted) {
          setState(
            () => _voiceMessage =
                'Speech recognition unavailable or microphone permission denied.',
          );
        }
        return;
      }
      final locales = await _speech.locales();
      final matches = locales
          .where(
            (locale) => locale.localeId
                .toLowerCase()
                .replaceAll('-', '_')
                .startsWith(_voiceLanguage),
          )
          .toList();
      final za = matches.where(
        (locale) =>
            locale.localeId.toLowerCase().replaceAll('-', '_').endsWith('_za'),
      );
      final localeId = za.isNotEmpty
          ? za.first.localeId
          : (matches.isEmpty ? null : matches.first.localeId);
      if (localeId == null && mounted) {
        setState(
          () => _voiceMessage =
              'Selected language unavailable; using the phone default.',
        );
      }
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult ||
              !mounted ||
              _loadedHole != holeNumber ||
              _loadedPlayerId != playerId) {
            return;
          }
          final spoken = result.recognizedWords;
          final gross = ScoreVoiceParser.parse(spoken, currentHole: holeNumber);
          if (gross == null || gross <= _penalties || gross - _penalties > 20) {
            setState(
              () => _voiceMessage =
                  'Heard “$spoken”. Check the hole and score, then try again.',
            );
            return;
          }
          _edit(() {
            _strokes = gross - _penalties;
            _voiceMessage =
                'Heard “$spoken”: $gross gross. Review and save below.';
          });
        },
        listenOptions: SpeechListenOptions(
          partialResults: false,
          listenMode: ListenMode.confirmation,
          localeId: localeId,
        ),
      );
      if (mounted) setState(() => _listening = _speech.isListening);
    } catch (_) {
      if (mounted) {
        setState(
          () => _voiceMessage =
              'Voice entry failed. You can still use the buttons.',
        );
      }
    } finally {
      if (mounted) setState(() => _voiceBusy = false);
    }
  }

  void _edit(VoidCallback change) {
    setState(() {
      change();
      _editRevision++;
      _dirty = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved hole'),
            content: const Text(
              'Your changes to this hole have not been saved. Stay here to save them, or discard them.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard changes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _loadExistingScore(
    int holeNumber,
    String playerId,
    HoleScore? score,
    int par,
  ) {
    final version = _scoreVersion(score);
    final sameDraft = _loadedHole == holeNumber && _loadedPlayerId == playerId;
    if (sameDraft && (_loadedScoreVersion == version || _dirty || _saving)) {
      return;
    }
    _loadedHole = holeNumber;
    _loadedPlayerId = playerId;
    _loadedScoreVersion = version;
    _loadedScoreExists = score != null;
    _loadedScoreUpdatedAt = score?.updatedAt;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _loadedHole != holeNumber ||
          _loadedPlayerId != playerId) {
        return;
      }

      setState(() {
        _dirty = false;
        _strokes = score?.strokes ?? par;
        _putts = score?.putts ?? 2;
        _penalties = score?.penaltyStrokes ?? 0;
        _sandShots = score?.sandShots ?? 0;
        _fairway = score?.fairway;
        _greenInRegulation = score?.greenInRegulation;
      });
    });
  }

  String _scoreVersion(HoleScore? score) => score == null
      ? 'missing'
      : '${score.updatedAt?.toUtc().toIso8601String()}|${score.strokes}|${score.putts}|${score.penaltyStrokes}|${score.sandShots}|${score.fairway}|${score.greenInRegulation}|${score.confirmed}';

  Future<bool> _saveScore(
    int holeNumber,
    String playerId,
    String? userId,
  ) async {
    final savedRevision = _editRevision;
    setState(() => _saving = true);

    try {
      if (userId == null) throw StateError('Sign in to save scores.');
      await ref.read(scoreOutboxProvider).enqueue(
        actorId: userId,
        roundId: widget.roundId,
        playerId: playerId,
        holeNumber: holeNumber,
        strokes: _strokes,
        putts: _putts,
        penaltyStrokes: _penalties,
        expectedExists: _loadedScoreExists,
        expectedUpdatedAt: _loadedScoreUpdatedAt,
        sandShots: _sandShots,
        fairway: _fairway,
        greenInRegulation: _greenInRegulation,
      );

      if (mounted) {
        if (_editRevision == savedRevision) setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              playerId == userId
                  ? 'Saved on this device. Waiting to sync.'
                  : 'Saved on this device. The player must confirm it after sync.',
            ),
          ),
        );
      }
      return true;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectPlayer(String? playerId) async {
    if (playerId == null || playerId == _selectedPlayerId || _saving) return;
    if (!await _confirmDiscard() || !mounted) return;
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _dirty = false;
      _selectedPlayerId = playerId;
      _loadedPlayerId = null;
    });
  }

  Future<void> _changeSharedHole(int currentHole, int delta) async {
    final next = ((currentHole - 1 + delta + 18) % 18) + 1;
    if (_saving || _movingHole || !await _confirmDiscard() || !mounted) return;
    final round = ref.read(roundProvider(widget.roundId)).valueOrNull;
    final userId = ref.read(currentUserIdProvider);
    setState(() {
      _dirty = false;
      _localHole = next;
      _loadedHole = null;
      _movingHole = true;
    });

    try {
      if (round?.hostUserId == userId) {
        await ref.read(roundRepositoryProvider)
            .setCurrentHole(roundId: widget.roundId, holeNumber: next)
            .timeout(const Duration(seconds: 3));
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(
        'Hole changed on this phone. The shared round may update when connected.',
      )));
    } finally {
      if (mounted) setState(() => _movingHole = false);
    }
  }

  Future<void> _completeRound() async {
    if (_saving || !await _confirmDiscard() || !mounted) return;
    final actor = ref.read(currentUserIdProvider);
    final outbox = ref.read(scoreOutboxProvider);
    await outbox.ready;
    if (actor != null && outbox.pendingForRound(actor, widget.roundId).isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync all scores before finishing the round.')));
      return;
    }
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
    final outbox = ref.watch(scoreOutboxProvider);
    final List<QueuedScore> pending = userId == null ? const <QueuedScore>[] : outbox.pendingForRound(userId, widget.roundId);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Live round'),
        actions: [
          if (pending.isNotEmpty) IconButton(
            tooltip: '${pending.length} scores waiting to sync',
            onPressed: () => _showQueue(pending),
            icon: const Icon(Icons.sync_problem),
          ),
          IconButton(
            tooltip: 'Hole view',
            onPressed: () =>
                context.push('/rounds/${widget.roundId}/hole-view'),
            icon: const Icon(Icons.map_outlined),
          ),
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
                // A host may move the shared hole while someone is editing.
                // Keep their draft attached to its original hole until saved.
                final editingHole = _dirty
                    ? (_loadedHole ?? _localHole ?? round.currentHole)
                    : (_localHole ?? round.currentHole);
                final hole = _holeForNumber(holes, editingHole);
                if (hole == null) {
                  return const Center(child: Text('Hole data unavailable.'));
                }

                return teesState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('$error')),
                  data: (tees) {
                    return playersState.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          Center(child: Text('$error')),
                      data: (players) {
                        final activePlayers = players
                            .where((player) => player.active)
                            .toList();
                        final selectedId =
                            activePlayers.any(
                              (p) => p.userId == _selectedPlayerId,
                            )
                            ? _selectedPlayerId
                            : userId;
                        final selectedPlayer = _playerForId(
                          activePlayers,
                          selectedId,
                        );
                        if (selectedPlayer == null) {
                          return const Center(
                            child: Text(
                              'You are not an active player in this round.',
                            ),
                          );
                        }
                        final tee = _teeForId(
                          tees,
                          selectedPlayer.teeSetId ?? round.teeSetId,
                        );

                        return scoresState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) =>
                              Center(child: Text('$error')),
                          data: (scores) {
                            final displayedScores = <HoleScore>[
                              ...scores.where((s) => !pending.any((q) => q.playerId == s.playerId && q.holeNumber == s.holeNumber)),
                              for (final q in pending) HoleScore(roundId: q.roundId, playerId: q.playerId, holeNumber: q.holeNumber, strokes: q.strokes, putts: q.putts, penaltyStrokes: q.penaltyStrokes, sandShots: q.sandShots, fairway: q.fairway, greenInRegulation: q.greenInRegulation, confirmed: false, updatedAt: q.expectedUpdatedAt),
                            ];
                            final queued = pending.where((q) => q.playerId == selectedPlayer.userId && q.holeNumber == hole.number).firstOrNull;
                            final serverScore = _scoreFor(
                              scores,
                              selectedId,
                              hole.number,
                            );
                            final existingScore = queued == null ? serverScore : HoleScore(roundId: queued.roundId, playerId: queued.playerId, holeNumber: queued.holeNumber, strokes: queued.strokes, putts: queued.putts, penaltyStrokes: queued.penaltyStrokes, sandShots: queued.sandShots, fairway: queued.fairway, greenInRegulation: queued.greenInRegulation, confirmed: false, updatedAt: queued.expectedUpdatedAt);

                            _loadExistingScore(
                              hole.number,
                              selectedPlayer.userId,
                              existingScore,
                              hole.par,
                            );

                            final handicapIndex = selectedPlayer.handicapIndex;
                            final courseHandicap =
                                handicapIndex != null && tee != null
                                ? HandicapCalculator.courseHandicap(
                                    handicapIndex: handicapIndex,
                                    slopeRating: tee.slopeRating,
                                    courseRating: tee.courseRating,
                                    par: tee.par,
                                  )
                                : null;

                            final playingHandicap =
                                selectedPlayer.playingHandicap ??
                                (courseHandicap == null
                                    ? null
                                    : HandicapCalculator.playingHandicap(
                                        courseHandicap: courseHandicap,
                                      ));

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
                              scores: displayedScores,
                              userId: userId,
                              selectedPlayer: selectedPlayer,
                              onPlayerSelected: _selectPlayer,
                              needsConfirmation:
                                  existingScore != null &&
                                  !existingScore.confirmed,
                              scoreLocked:
                                  queued != null ||
                                  existingScore?.confirmed == true &&
                                  selectedPlayer.userId != userId,
                              scoreConflict:
                                  _dirty &&
                                  _loadedScoreVersion !=
                                      _scoreVersion(existingScore),
                              queuedScore: queued != null,
                              onReloadScore: () => setState(() {
                                _dirty = false;
                                _loadedScoreVersion = null;
                              }),
                              groupOnDifferentHole:
                                  hole.number != round.currentHole,
                              voiceLanguage: _voiceLanguage,
                              voiceMessage: _voiceMessage,
                              listening: _listening,
                              voiceBusy: _voiceBusy,
                              onVoiceLanguage: (value) => setState(() {
                                _voiceLanguage = value;
                                _voiceMessage = value == 'af'
                                    ? 'Sê “Putjie sewe, ses houe”.'
                                    : 'Say “Hole seven, six strokes”.';
                              }),
                              onVoice: () => _toggleVoice(
                                hole.number,
                                selectedPlayer.userId,
                              ),
                              isHost: isHost,
                              playingHandicap: playingHandicap,
                              strokesReceived: strokesReceived,
                              gross: gross,
                              net: net,
                              strokes: _strokes,
                              putts: _putts,
                              penalties: _penalties,
                              sandShots: _sandShots,
                              fairway: _fairway,
                              greenInRegulation: _greenInRegulation,
                              saving: _saving,
                              completing: _completing,
                              onStrokes: (value) =>
                                  _edit(() => _strokes = value - _penalties),
                              onPutts: (value) => _edit(() => _putts = value),
                              onPenalties: (value) => _edit(() {
                                final gross = _strokes + _penalties;
                                _penalties = value;
                                _strokes = (gross - value).clamp(1, 20);
                              }),
                              onSandShots: (value) =>
                                  _edit(() => _sandShots = value),
                              onFairway: (value) =>
                                  _edit(() => _fairway = value),
                              onGreenInRegulation: (value) =>
                                  _edit(() => _greenInRegulation = value),
                              onSave: () async {
                                final saved = await _saveScore(
                                  hole.number,
                                  selectedPlayer.userId,
                                  userId,
                                );
                                if (!saved ||
                                    !mounted ||
                                    _dirty ||
                                    activePlayers.length < 2) {
                                  return;
                                }
                                final index = activePlayers.indexWhere(
                                  (p) => p.userId == selectedPlayer.userId,
                                );
                                await _selectPlayer(
                                  activePlayers[(index + 1) %
                                          activePlayers.length]
                                      .userId,
                                );
                              },
                              onMoveHole: (delta) =>
                                  _changeSharedHole(hole.number, delta),
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
    required this.selectedPlayer,
    required this.onPlayerSelected,
    required this.needsConfirmation,
    required this.scoreLocked,
    required this.queuedScore,
    required this.scoreConflict,
    required this.onReloadScore,
    required this.groupOnDifferentHole,
    required this.voiceLanguage,
    required this.voiceMessage,
    required this.listening,
    required this.voiceBusy,
    required this.onVoiceLanguage,
    required this.onVoice,
    required this.isHost,
    required this.playingHandicap,
    required this.strokesReceived,
    required this.gross,
    required this.net,
    required this.strokes,
    required this.putts,
    required this.penalties,
    required this.sandShots,
    required this.fairway,
    required this.greenInRegulation,
    required this.saving,
    required this.completing,
    required this.onStrokes,
    required this.onPutts,
    required this.onPenalties,
    required this.onSandShots,
    required this.onFairway,
    required this.onGreenInRegulation,
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
  final RoundPlayer selectedPlayer;
  final ValueChanged<String?> onPlayerSelected;
  final bool needsConfirmation;
  final bool scoreLocked;
  final bool queuedScore;
  final bool scoreConflict;
  final VoidCallback onReloadScore;
  final bool groupOnDifferentHole;
  final String voiceLanguage;
  final String voiceMessage;
  final bool listening;
  final bool voiceBusy;
  final ValueChanged<String> onVoiceLanguage;
  final VoidCallback onVoice;
  final bool isHost;
  final int? playingHandicap;
  final int strokesReceived;
  final int gross;
  final int net;
  final int strokes;
  final int putts;
  final int penalties;
  final int sandShots;
  final String? fairway;
  final bool? greenInRegulation;
  final bool saving;
  final bool completing;
  final ValueChanged<int> onStrokes;
  final ValueChanged<int> onPutts;
  final ValueChanged<int> onPenalties;
  final ValueChanged<int> onSandShots;
  final ValueChanged<String?> onFairway;
  final ValueChanged<bool?> onGreenInRegulation;
  final VoidCallback onSave;
  final ValueChanged<int> onMoveHole;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final stableford = (2 + hole.par - net).clamp(0, 99);
    final officialDistance = tee?.holeDistancesMeters[hole.number];
    final gpsEstimate = hole.estimatedStraightLineMeters;
    final activePlayers = players.where((player) => player.active).toList();
    final allConfirmed =
        activePlayers.isNotEmpty &&
        activePlayers.every(
          (player) =>
              scores
                  .where(
                    (score) =>
                        score.playerId == player.userId && score.confirmed,
                  )
                  .map((score) => score.holeNumber)
                  .toSet()
                  .length >=
              18,
        );

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
                    enabled: !saving && !listening && !voiceBusy,
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
                    enabled: !saving && !listening && !voiceBusy,
                    onTap: () => onMoveHole(1),
                    semantic: 'Next hole',
                  ),
                ],
              ),
              if (!isHost) ...[
                const SizedBox(height: 10),
                Text(
                  'Use the arrows to view another hole on this phone.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(11.5, colour: AppTheme.textFaint),
                ),
              ],
            ],
          ),
        ),

        if (groupOnDifferentHole) ...[
          const SizedBox(height: 10),
          const Text(
            'You are viewing a different hole from the shared round.',
          ),
        ],
        const SizedBox(height: 14),
        DropdownButton<String>(
          value: selectedPlayer.userId,
          isExpanded: true,
          hint: const Text('Score for'),
          items: [
            for (final player in players.where((player) => player.active))
              DropdownMenuItem(
                value: player.userId,
                child: Text(
                  player.userId == userId
                      ? '${player.displayName} (you)'
                      : player.displayName,
                ),
              ),
          ],
          onChanged: saving || listening || voiceBusy ? null : onPlayerSelected,
        ),
        const SizedBox(height: 8),
        Text(
          queuedScore
              ? 'Saved on this phone and waiting to sync. Use the sync icon to review any problem.'
              : scoreLocked
              ? 'This player confirmed their score. Only they can change it.'
              : selectedPlayer.userId == userId
              ? (needsConfirmation
                    ? 'Review and save to confirm this score.'
                    : 'Enter your gross score, including penalties.')
              : 'Scores entered for another player are provisional until they confirm them.',
          style: AppTheme.body(11.5, colour: AppTheme.textMuted),
        ),
        if (selectedPlayer.teeSetId == null)
          Text(
            'Preview uses the round tee; individual tee selection is not yet available here.',
            style: AppTheme.body(11, colour: AppTheme.textMuted),
          ),
        if (scoreConflict) ...[
          const Text(
            'This score changed on another device. Reload before saving to avoid overwriting it.',
          ),
          TextButton(
            onPressed: onReloadScore,
            child: const Text('Discard draft and reload'),
          ),
        ],

        // --- Running total --------------------------------------------------
        Row(
          children: [
            Expanded(
              child: _Readout(label: 'Gross', value: '$gross', accent: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Readout(
                label: 'Net',
                value: playingHandicap == null ? '--' : '$net',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Readout(
                label: 'Stableford',
                value: playingHandicap == null ? '--' : '$stableford',
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // --- Entry ----------------------------------------------------------
        IgnorePointer(
          ignoring: saving || scoreLocked || scoreConflict,
          child: Column(
            children: [
              ChristianGolfersCard(
                child: ScoreStepper(
                  label: 'Gross strokes',
                  value: gross,
                  min: penalties + 1,
                  max: penalties + 20,
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
              const SizedBox(height: 6),
              Text(
                'Gross includes penalties. Adjust penalties without counting them twice.',
                style: AppTheme.body(11, colour: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('English')),
                        ButtonSegment(value: 'af', label: Text('Afrikaans')),
                      ],
                      selected: {voiceLanguage},
                      onSelectionChanged: listening || voiceBusy
                          ? null
                          : (value) => onVoiceLanguage(value.first),
                    ),
                  ),
                  IconButton(
                    tooltip: listening ? 'Stop listening' : 'Speak gross score',
                    onPressed: voiceBusy ? null : onVoice,
                    icon: Icon(
                      listening
                          ? Icons.stop_circle_outlined
                          : Icons.mic_outlined,
                    ),
                  ),
                ],
              ),
              Text(
                voiceMessage,
                style: AppTheme.body(11, colour: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GoldButton(
          label: needsConfirmation && selectedPlayer.userId == userId
              ? (activePlayers.length > 1
                    ? 'Confirm, save & next player'
                    : 'Confirm and save')
              : (activePlayers.length > 1
                    ? 'Save & next player'
                    : 'Save hole ${hole.number}'),
          icon: Icons.check_rounded,
          busy: saving,
          onPressed:
              saving || listening || voiceBusy || scoreLocked || scoreConflict
              ? null
              : onSave,
        ),
        const SizedBox(height: 8),
        Text(
          'Scores reach the dashboard after the server confirms the save.',
          style: AppTheme.body(11, colour: AppTheme.textMuted),
        ),
        IgnorePointer(
          ignoring: saving || scoreLocked || scoreConflict,
          child: Column(
            children: [
              const SizedBox(height: 12),
              ChristianGolfersCard(
                child: ScoreStepper(
                  label: 'Sand shots',
                  value: sandShots,
                  min: 0,
                  max: 10,
                  quickValues: const [0, 1, 2, 3],
                  lastQuickIsPlus: true,
                  onChanged: onSandShots,
                ),
              ),
              const SizedBox(height: 12),
              ChristianGolfersCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FAIRWAY', style: AppTheme.label(10)),
                    const SizedBox(height: 10),
                    SegmentedButton<String?>(
                      emptySelectionAllowed: true,
                      multiSelectionEnabled: false,
                      segments: const [
                        ButtonSegment<String?>(
                          value: 'left',
                          label: Text('Left'),
                        ),
                        ButtonSegment<String?>(
                          value: 'hit',
                          label: Text('Hit'),
                        ),
                        ButtonSegment<String?>(
                          value: 'right',
                          label: Text('Right'),
                        ),
                        ButtonSegment<String?>(
                          value: 'missed',
                          label: Text('Miss'),
                        ),
                      ],
                      selected: fairway == null ? const {} : {fairway!},
                      onSelectionChanged: (values) =>
                          onFairway(values.isEmpty ? null : values.first),
                    ),
                    const SizedBox(height: 8),
                    const Text('Green in regulation'),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      emptySelectionAllowed: true,
                      segments: const [
                        ButtonSegment(value: true, label: Text('Yes')),
                        ButtonSegment(value: false, label: Text('No')),
                      ],
                      selected: greenInRegulation == null
                          ? const <bool>{}
                          : {greenInRegulation!},
                      onSelectionChanged: (values) => onGreenInRegulation(
                        values.isEmpty ? null : values.first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        GoldButton(
          label: activePlayers.length > 1
              ? 'Save & next player'
              : 'Save hole ${hole.number}',
          icon: Icons.check_rounded,
          busy: saving,
          onPressed:
              saving || listening || voiceBusy || scoreLocked || scoreConflict
              ? null
              : onSave,
        ),

        const SizedBox(height: 14),
        HoleArtwork(
          hole: hole,
          seed: '${round.courseId}-${hole.number}',
          height: 190,
        ),
        GreenDistanceCard(key: ValueKey('gps-${hole.number}'), hole: hole),
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
          if (!allConfirmed)
            const Text(
              'All active players must confirm 18 holes before the round can be finished.',
            ),
          TextButton.icon(
            onPressed: completing || listening || voiceBusy || !allConfirmed
                ? null
                : onComplete,
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
    this.accent = false,
  });

  final String label;
  final String value;
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
              colour: accent ? AppTheme.gold : AppTheme.textPrimary,
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
    final provisional = thisHole.isNotEmpty && !thisHole.first.confirmed;

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
                  provisional
                      ? 'Hole $currentHole awaiting player confirmation'
                      : played == 0
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
