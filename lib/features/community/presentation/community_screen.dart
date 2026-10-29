import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/friend.dart';
import 'add_friend_sheet.dart';
import 'community_providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendships = ref.watch(friendshipsProvider);
    final pendingCount = friendships.valueOrNull
            ?.where((friend) => friend.needsMyAnswer)
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: const Text('Community'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showAddFriendSheet(context, ref),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: AppTheme.darkNavy,
              child: TabBar(
                indicatorColor: AppTheme.primaryBlue,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textFaint,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Crew'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          _Pip(count: pendingCount),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Activity'),
                  const Tab(text: 'Standings'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [_CrewTab(), _ActivityTab(), _StandingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Crew
// -------------------------------------------------------------------------

class _CrewTab extends ConsumerWidget {
  const _CrewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendshipsProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorBody(error: error),
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyBody(
            icon: Icons.group_add_rounded,
            title: 'No crew yet',
            message: 'Add the golfers you play with by their email address. '
                "Once they accept, you'll see their rounds and how you stack "
                'up against them.',
            action: GoldButton(
              label: 'Add a golfer',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => showAddFriendSheet(context, ref),
            ),
          );
        }

        final incoming = friends.where((f) => f.needsMyAnswer).toList();
        final accepted = friends.where((f) => f.isAccepted).toList();
        final outgoing = friends.where((f) => f.isWaitingOnThem).toList();

        return RefreshIndicator(
          onRefresh: () async => invalidateCommunity(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (incoming.isNotEmpty) ...[
                const _SectionLabel('Wants to add you'),
                for (final friend in incoming)
                  _RequestTile(friend: friend),
                const SizedBox(height: 20),
              ],
              if (accepted.isNotEmpty) ...[
                _SectionLabel('Your crew (${accepted.length})'),
                for (final friend in accepted) _FriendTile(friend: friend),
                const SizedBox(height: 20),
              ],
              if (outgoing.isNotEmpty) ...[
                const _SectionLabel('Waiting on them'),
                for (final friend in outgoing)
                  ListTile(
                    leading: _Avatar(friend: friend),
                    title: Text(friend.displayName),
                    subtitle: const Text('Request sent'),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref
                            .read(communityRepositoryProvider)
                            .removeFriend(friend.id);
                        invalidateCommunity(ref);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.friend});

  final Friend friend;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);

    try {
      await ref
          .read(communityRepositoryProvider)
          .respondToRequest(requesterId: widget.friend.id, accept: accept);

      invalidateCommunity(ref);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _Avatar(friend: widget.friend),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.displayName,
                  style: AppTheme.body(14, weight: FontWeight.w700),
                ),
                Text(
                  widget.friend.email ?? 'wants to be in your crew',
                  style: AppTheme.body(12, colour: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Decline',
                      onPressed: () => _respond(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    IconButton(
                      tooltip: 'Accept',
                      onPressed: () => _respond(true),
                      icon: const Icon(Icons.check_circle_rounded),
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChristianGolfersCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _Avatar(friend: friend),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: AppTheme.body(14, weight: FontWeight.w700),
                  ),
                  Text(
                    friend.handicapIndex == null
                        ? (friend.email ?? '')
                        : 'Handicap index ${friend.handicapIndex!.toStringAsFixed(1)}',
                    style: AppTheme.body(12, colour: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value != 'remove') return;

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Remove ${friend.displayName}?'),
                    content: const Text(
                      "You'll stop seeing each other's rounds and standings. You "
                      'can add them again later.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                await ref.read(communityRepositoryProvider).removeFriend(friend.id);
                invalidateCommunity(ref);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'remove', child: Text('Remove from crew')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Activity
// -------------------------------------------------------------------------

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _when(DateTime at) {
    final days = DateTime.now().difference(at).inDays;

    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';

    return '${at.day} ${_months[at.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendActivityProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorBody(error: error),
      data: (feed) {
        if (feed.isEmpty) {
          return const _EmptyBody(
            icon: Icons.timeline_rounded,
            title: 'Nothing yet',
            message: 'When someone in your crew finishes a round, it shows up '
                'here with what they shot.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(friendActivityProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: feed.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = feed[index];

              return ChristianGolfersCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryBlueBg,
                      child: Text(
                        _initials(entry.displayName),
                        style: AppTheme.body(
                          12,
                          weight: FontWeight.w800,
                          colour: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: entry.displayName,
                                  style: AppTheme.body(
                                    13.5,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: entry.isFullRound
                                      ? ' played ${entry.courseName}'
                                      : ' played ${entry.holes} holes at '
                                          '${entry.courseName}',
                                  style: AppTheme.body(13.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _when(entry.playedAt),
                            style: AppTheme.body(
                              11.5,
                              colour: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.gross}',
                      style: AppTheme.numeric(20, colour: AppTheme.primaryBlue),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------------------
// Standings
// -------------------------------------------------------------------------

class _StandingsTab extends ConsumerWidget {
  const _StandingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendStandingsProvider);
    final myId = ref.watch(currentUserIdProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorBody(error: error),
      data: (standings) {
        if (standings.isEmpty) {
          return const _EmptyBody(
            icon: Icons.emoji_events_rounded,
            title: 'No standings yet',
            message: 'Once you and your crew have finished some full rounds, '
                'this ranks everyone by scoring average over the last year.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(friendStandingsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: standings.length,
            itemBuilder: (context, index) {
              final row = standings[index];
              final isMe = row.golferId == myId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChristianGolfersCard(
                  colour: isMe ? AppTheme.primaryBlueBg : AppTheme.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${index + 1}',
                          style: AppTheme.numeric(14, colour: AppTheme.textMuted),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? '${row.displayName} (you)' : row.displayName,
                              style: AppTheme.body(14, weight: FontWeight.w700),
                            ),
                            Text(
                              '${row.roundsPlayed} '
                              '${row.roundsPlayed == 1 ? 'round' : 'rounds'}'
                              '  ·  best ${row.bestGross}',
                              style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            row.averageGross.toStringAsFixed(1),
                            style: AppTheme.numeric(
                              20,
                              colour: isMe ? AppTheme.primaryBlue : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'average',
                            style: AppTheme.label(9, colour: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------------------
// Shared bits
// -------------------------------------------------------------------------

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final photo = friend.photoUrl;

    return CircleAvatar(
      backgroundColor: AppTheme.primaryBlueBg,
      backgroundImage: photo == null ? null : NetworkImage(photo),
      child: photo != null
          ? null
          : Text(
              _initials(friend.displayName),
              style: AppTheme.body(
                12,
                weight: FontWeight.w800,
                colour: AppTheme.primaryBlue,
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.label(10.5, colour: AppTheme.textMuted),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 40),
        Icon(icon, size: 54, color: AppTheme.primaryBlue),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.display(20),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.body(13, colour: AppTheme.textMuted),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(child: action!),
        ],
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off_rounded, size: 52),
        const SizedBox(height: 14),
        Text('$error', textAlign: TextAlign.center),
      ],
    );
  }
}
