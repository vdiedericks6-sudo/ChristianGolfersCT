import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/app_notification_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/round_link.dart';
import 'round_providers.dart';

class RoundLobbyScreen extends ConsumerStatefulWidget {
  const RoundLobbyScreen({required this.roundId, super.key});

  final String roundId;

  @override
  ConsumerState<RoundLobbyScreen> createState() => _RoundLobbyScreenState();
}

class _RoundLobbyScreenState extends ConsumerState<RoundLobbyScreen> {
  bool _starting = false;
  bool _navigatingToLiveRound = false;
  String? _notifiedStartedRoundId;

  Future<void> _startRound() async {
    setState(() => _starting = true);

    try {
      await ref.read(roundRepositoryProvider).startRound(widget.roundId);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openLiveRound() {
    if (_navigatingToLiveRound) return;
    _navigatingToLiveRound = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/rounds/${widget.roundId}/live');
      }
    });
  }

  Future<void> _copy(String text, String toast) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(toast)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roundState = ref.watch(roundProvider(widget.roundId));
    final playersState = ref.watch(roundPlayersProvider(widget.roundId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('ROUND LOBBY'),
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
                message: 'The host may have cancelled it.',
              );
            }

            if (round.isActive) {
              if (round.hostUserId != currentUserId &&
                  _notifiedStartedRoundId != round.id) {
                _notifiedStartedRoundId = round.id;
                unawaited(
                  AppNotificationService.showRoundStarted(
                    roundId: round.id,
                    courseName: round.courseName,
                  ),
                );
              }
              _openLiveRound();
              return const Center(child: CircularProgressIndicator());
            }

            final isHost = round.hostUserId == currentUserId;
            final players = playersState.valueOrNull ?? const [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
              children: [
                Text(round.courseName.toUpperCase(), style: AppTheme.label(10)),
                const SizedBox(height: 5),
                Text('Waiting to tee off', style: AppTheme.display(30)),
                const SizedBox(height: 4),
                Text(
                  '${round.teeSetName} tees · Stroke play',
                  style: AppTheme.body(13, colour: AppTheme.textMuted),
                ),

                const SizedBox(height: 22),
                _CodeBlock(
                  code: round.joinCode,
                  link: RoundLink.forCode(round.joinCode),
                  onCopyCode: () => _copy(round.joinCode, 'Round code copied.'),
                  onShare: () => _copy(
                    RoundLink.invitation(
                      joinCode: round.joinCode,
                      courseName: round.courseName,
                    ),
                    'Invite copied. Paste it into WhatsApp.',
                  ),
                ),

                const SizedBox(height: 26),
                SectionHeader(
                  'The group',
                  action: Text(
                    '${players.length} of 4',
                    style: AppTheme.label(10, colour: AppTheme.gold),
                  ),
                ),
                playersState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => LoadFailure(what: 'the players', error: e),
                  data: (list) => Column(
                    children: [
                      for (final player in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlayerSlot(
                            name: player.displayName,
                            handicapIndex: player.handicapIndex,
                            isHost: player.isHost,
                            isMe: player.userId == currentUserId,
                          ),
                        ),
                      if (list.length < 4) const _EmptySlot(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/rounds/${widget.roundId}/scorecard'),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Open 4-ball scorecard'),
                ),
                const SizedBox(height: 10),
                if (isHost)
                  GoldButton(
                    label: 'Start the round',
                    icon: Icons.sports_golf_rounded,
                    busy: _starting,
                    onPressed: _starting ? null : _startRound,
                  )
                else
                  ChristianGolfersCard(
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Waiting for the host to start. You will be taken '
                            'to the first tee automatically.',
                            style: AppTheme.body(
                              13,
                              colour: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The round code, big enough to read across a car park.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.link,
    required this.onCopyCode,
    required this.onShare,
  });

  final String code;
  final String link;
  final VoidCallback onCopyCode;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.goldLine, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22D4AF37),
            blurRadius: 26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        children: [
          Text('ROUND CODE', style: AppTheme.label(10, colour: AppTheme.gold)),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              code,
              style: AppTheme.numeric(
                52,
                colour: AppTheme.gold,
              ).copyWith(letterSpacing: 10),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            link,
            textAlign: TextAlign.center,
            style: AppTheme.body(11, colour: AppTheme.textFaint),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Share invite',
            icon: Icons.ios_share_rounded,
            height: 50,
            onPressed: onShare,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCopyCode,
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy just the code'),
          ),
        ],
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.name,
    required this.handicapIndex,
    required this.isHost,
    required this.isMe,
  });

  final String name;
  final double? handicapIndex;
  final bool isHost;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: isMe ? AppTheme.goldLine : null,
      child: Row(
        children: [
          GolferAvatar(name: name, size: 44, highlight: isMe),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (you)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MetaPill(
                      handicapIndex == null
                          ? 'No handicap'
                          : 'HCP ${handicapIndex!.toStringAsFixed(1)}',
                      colour: handicapIndex == null
                          ? AppTheme.textFaint
                          : AppTheme.textMuted,
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      const MetaPill('Host', colour: AppTheme.gold),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.positive,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return DottedSlot(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.line),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 19,
              color: AppTheme.textFaint,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Open spot — share the code above',
              style: AppTheme.body(13, colour: AppTheme.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

/// An open seat: same shape as a filled slot, visibly waiting.
class DottedSlot extends StatelessWidget {
  const DottedSlot({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.line),
      ),
      child: child,
    );
  }
}
