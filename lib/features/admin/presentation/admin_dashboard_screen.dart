import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../handicap/domain/handicap_calculator.dart';
import '../../leagues/domain/season_competition.dart';
import '../data/admin_league_dashboard_repository.dart';

enum _DashboardTab { standings, rounds, members }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  AdminDashboardFilter _filter = const AdminDashboardFilter();
  _DashboardTab _tab = _DashboardTab.standings;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        ref.invalidate(adminLeagueDashboardProvider(_filter));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(adminLeagueDashboardProvider(_filter));
    await ref.read(adminLeagueDashboardProvider(_filter).future);
  }

  Future<void> _chooseDateRange() async {
    final now = DateTime.now();
    final selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: _filter.from ?? DateTime(now.year, 1, 1),
        end: _filter.to ?? DateTime(now.year, now.month, now.day),
      ),
      helpText: 'Filter rounds by South African playing date',
    );
    if (selection == null || !mounted) return;
    setState(() {
      _filter = AdminDashboardFilter(from: selection.start, to: selection.end);
    });
  }

  Future<void> _inviteMember() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final invite = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite a golfer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter the golfer’s name'
                    : null,
              ),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (value) => (value?.contains('@') ?? false)
                    ? null
                    : 'Enter a valid email',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, (
                  name.text.trim(),
                  email.text.trim(),
                ));
              }
            },
            child: const Text('Send invite'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    if (invite == null || !mounted) return;

    try {
      final response = await ref
          .read(supabaseClientProvider)
          .functions
          .invoke(
            'admin-invite-member',
            body: {'displayName': invite.$1, 'email': invite.$2},
          );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('Invite failed (HTTP ${response.status}).');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to ${invite.$2}.')),
        );
      }
      ref.invalidate(adminLeagueDashboardProvider(_filter));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not invite golfer: $error')),
        );
      }
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final local = value.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }

  String get _rangeLabel {
    if (_filter.from == null && _filter.to == null) return 'All dates';
    return '${_date(_filter.from)} – ${_date(_filter.to)}';
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(adminLeagueDashboardProvider(_filter));
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        leading: const AppBackButton(),
        title: const Text('League dashboard'),
        actions: [
          if (_tab == _DashboardTab.members)
            IconButton(
              tooltip: 'Invite golfer',
              onPressed: _inviteMember,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          IconButton(
            tooltip: 'Refresh scores',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 42),
                const SizedBox(height: 12),
                const Text(
                  'Could not load league data. Confirm your owner or captain access and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('Try again'),
                ),
                if (!const bool.fromEnvironment('dart.vm.product'))
                  Text('$error', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: [
              Text('Owner & captain view', style: AppTheme.display(23)),
              const SizedBox(height: 4),
              Text(
                'All app members, submitted cards and completed-round results.',
                style: AppTheme.body(12.5, colour: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              _DateFilterCard(
                label: _rangeLabel,
                isFiltered: _filter.from != null || _filter.to != null,
                onPick: _chooseDateRange,
                onClear: () =>
                    setState(() => _filter = const AdminDashboardFilter()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Members',
                      value: '${data.members.length}',
                      icon: Icons.people_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Rounds',
                      value: '${data.rounds.length}',
                      icon: Icons.golf_course_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricCard(
                      label: 'Scores',
                      value: '${data.confirmedScores}',
                      icon: Icons.fact_check_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SegmentedButton<_DashboardTab>(
                segments: const [
                  ButtonSegment(
                    value: _DashboardTab.standings,
                    label: Text('Standings'),
                  ),
                  ButtonSegment(
                    value: _DashboardTab.rounds,
                    label: Text('Rounds'),
                  ),
                  ButtonSegment(
                    value: _DashboardTab.members,
                    label: Text('Members'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              const SizedBox(height: 16),
              switch (_tab) {
                _DashboardTab.standings => _StandingsView(data: data),
                _DashboardTab.rounds => _RoundsView(data: data, date: _date),
                _DashboardTab.members => _MembersView(data: data),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _DateFilterCard extends StatelessWidget {
  const _DateFilterCard({
    required this.label,
    required this.isFiltered,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final bool isFiltered;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => ChristianGolfersCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(
      children: [
        const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: AppTheme.body(13, weight: FontWeight.w700)),
        ),
        if (isFiltered)
          IconButton(
            tooltip: 'Show all dates',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        IconButton(
          tooltip: 'Choose date range',
          onPressed: onPick,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ChristianGolfersCard(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 9),
    child: Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.numeric(20, weight: FontWeight.w800)),
        Text(label, style: AppTheme.body(10.5, colour: AppTheme.textMuted)),
      ],
    ),
  );
}

class _StandingsView extends StatelessWidget {
  const _StandingsView({required this.data});
  final AdminLeagueDashboard data;

  @override
  Widget build(BuildContext context) {
    final results = data.competitionResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points accumulated · selected dates',
          style: AppTheme.body(12, colour: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        for (final division in [
          CompetitionDivision.leagueA,
          CompetitionDivision.leagueB,
          CompetitionDivision.social,
        ]) ...[
          _DivisionStandings(division: division, results: results),
          const SizedBox(height: 14),
        ],
        Text(
          'Standings include completed 18-hole rounds. In-progress cards are available under Rounds.',
          style: AppTheme.body(11, colour: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _DivisionStandings extends StatelessWidget {
  const _DivisionStandings({required this.division, required this.results});
  final CompetitionDivision division;
  final List<CompetitionRoundResult> results;

  String get _title => switch (division) {
    CompetitionDivision.leagueA => 'League A',
    CompetitionDivision.leagueB => 'League B',
    CompetitionDivision.social => 'Social',
  };

  @override
  Widget build(BuildContext context) {
    final standings = SeasonCompetitionCalculator.calculateLive(
      results,
      division: division,
    );
    return ChristianGolfersCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: AppTheme.body(15, weight: FontWeight.w800)),
          const SizedBox(height: 7),
          if (standings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No eligible completed rounds yet.',
                style: AppTheme.body(12, colour: AppTheme.textMuted),
              ),
            )
          else ...[
            const Row(
              children: [
                SizedBox(width: 28, child: Text('#')),
                Expanded(child: Text('Golfer')),
                SizedBox(
                  width: 58,
                  child: Text('Rounds', textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 50,
                  child: Text('Points', textAlign: TextAlign.right),
                ),
              ],
            ),
            const Divider(height: 13),
            for (var i = 0; i < standings.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: AppTheme.numeric(12, weight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        standings[i].playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(12.5, weight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 58,
                      child: Text(
                        '${standings[i].eligibleRounds}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${standings[i].totalPoints}',
                        textAlign: TextAlign.right,
                        style: AppTheme.numeric(13, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RoundsView extends StatelessWidget {
  const _RoundsView({required this.data, required this.date});
  final AdminLeagueDashboard data;
  final String Function(DateTime?) date;

  @override
  Widget build(BuildContext context) {
    if (data.rounds.isEmpty) {
      return const ChristianGolfersCard(
        child: Text('No rounds found for these dates.'),
      );
    }
    return Column(
      children: [
        for (final round in data.rounds)
          Builder(
            builder: (context) {
              final players = data.players
                  .where((p) => p.roundId == round.id)
                  .toList();
              final scores = data.scores
                  .where((s) => s.roundId == round.id)
                  .toList();
              final complete = scores.where((s) => s.confirmed).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ChristianGolfersCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _AdminRoundDetailScreen(
                        data: data,
                        round: round,
                        date: date,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.golf_course_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              round.courseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(14, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${date(round.playedAt)} · ${round.status.toUpperCase()} · ${players.length}/4 golfers',
                              style: AppTheme.body(
                                10.5,
                                colour: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$complete confirmed hole scores · host ${round.hostName}',
                              style: AppTheme.body(
                                11,
                                colour: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MembersView extends StatelessWidget {
  const _MembersView({required this.data});
  final AdminLeagueDashboard data;

  String _division(AdminLeagueMember member, AdminLeagueDashboard data) {
    if (member.visiting) return 'Visiting';
    final index = member.handicapIndex;
    if (index == null || index > data.leagueBMaxHandicap) return 'Social';
    if (index <= data.leagueAMaxHandicap) return 'League A';
    return 'League B';
  }

  @override
  Widget build(BuildContext context) {
    if (data.members.isEmpty) {
      return const ChristianGolfersCard(child: Text('No app members found.'));
    }
    return Column(
      children: [
        for (final member in data.members)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChristianGolfersCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  GolferAvatar(name: member.displayName, size: 42),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: AppTheme.body(13, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            10.5,
                            colour: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        member.handicapIndex?.toStringAsFixed(1) ?? 'No HI',
                        style: AppTheme.numeric(12, weight: FontWeight.w700),
                      ),
                      Text(
                        _division(member, data),
                        style: AppTheme.body(10, colour: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminRoundDetailScreen extends StatelessWidget {
  const _AdminRoundDetailScreen({
    required this.data,
    required this.round,
    required this.date,
  });
  final AdminLeagueDashboard data;
  final AdminLeagueRound round;
  final String Function(DateTime?) date;

  int _net(AdminRoundPlayer player, List<AdminHoleScore> scores) {
    final handicap = player.playingHandicap ?? player.courseHandicap ?? 0;
    return scores.where((score) => score.confirmed).fold<int>(0, (sum, score) {
      final received = score.strokeIndex == null
          ? 0
          : HandicapCalculator.strokesReceivedOnHole(
              playingHandicap: handicap,
              strokeIndex: score.strokeIndex!,
            );
      return sum + score.gross - received;
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = data.players
        .where((player) => player.roundId == round.id && player.active)
        .toList();
    final allScores = data.scores
        .where((score) => score.roundId == round.id)
        .toList();
    final results = {
      for (final result in data.results.where(
        (result) => result.roundId == round.id,
      ))
        result.playerId: result,
    };
    final holes = List<int>.generate(18, (index) => index + 1);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        leading: const AppBackButton(),
        title: const Text('Round scorecards'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(round.courseName, style: AppTheme.display(23)),
          const SizedBox(height: 4),
          Text(
            '${date(round.playedAt)} · ${round.teeSetName} · ${round.status.toUpperCase()}',
            style: AppTheme.body(12, colour: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Host: ${round.hostName} · ${players.length} active golfers · ${allScores.where((score) => score.confirmed).length} confirmed scores',
            style: AppTheme.body(11, colour: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          Text(
            'Hole-by-hole scorecard',
            style: AppTheme.body(16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (players.isEmpty)
            const ChristianGolfersCard(
              child: Text('No golfers joined this round.'),
            )
          else
            for (final player in players)
              Builder(
                builder: (context) {
                  final playerScores = allScores
                      .where((score) => score.playerId == player.userId)
                      .toList();
                  final byHole = {
                    for (final score in playerScores) score.holeNumber: score,
                  };
                  final completedResult = results[player.userId];
                  final confirmedScores = playerScores
                      .where((score) => score.confirmed)
                      .toList();
                  final gross = confirmedScores.fold<int>(
                    0,
                    (total, score) => total + score.gross,
                  );
                  final net =
                      completedResult?.netStrokes ?? _net(player, playerScores);
                  final putts = confirmedScores.fold<int>(
                    0,
                    (total, score) => total + score.putts,
                  );
                  final penalties = confirmedScores.fold<int>(
                    0,
                    (total, score) => total + score.penalties,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ChristianGolfersCard(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.displayName,
                                  style: AppTheme.body(
                                    14,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (completedResult != null)
                                Text(
                                  '#${completedResult.position}',
                                  style: AppTheme.body(
                                    12,
                                    colour: AppTheme.primaryGreen,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'HI ${player.handicapIndex?.toStringAsFixed(1) ?? '—'} · gross $gross · net $net · putts $putts · penalties $penalties',
                            style: AppTheme.body(
                              10.5,
                              colour: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              horizontalMargin: 4,
                              columnSpacing: 12,
                              headingRowHeight: 34,
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 44,
                              columns: [
                                const DataColumn(label: Text('Hole')),
                                for (final hole in holes)
                                  DataColumn(label: Text('$hole')),
                                const DataColumn(label: Text('Gross')),
                                const DataColumn(label: Text('Net')),
                              ],
                              rows: [
                                DataRow(
                                  cells: [
                                    const DataCell(Text('Score')),
                                    for (final hole in holes)
                                      DataCell(
                                        Text(
                                          byHole[hole] == null
                                              ? '–'
                                              : '${byHole[hole]!.gross}${byHole[hole]!.confirmed ? '' : '*'}',
                                        ),
                                      ),
                                    DataCell(
                                      Text(
                                        '$gross',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '$net',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    const DataCell(Text('Putts')),
                                    for (final hole in holes)
                                      DataCell(
                                        Text(
                                          byHole[hole]?.putts.toString() ?? '–',
                                        ),
                                      ),
                                    DataCell(Text('$putts')),
                                    const DataCell(Text('')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (playerScores.any((score) => !score.confirmed))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '* Score awaiting confirmation; excluded from confirmed totals.',
                                style: AppTheme.body(
                                  10,
                                  colour: AppTheme.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
