import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../domain/league_a_standings.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  int _selectedTabIndex = 0; // 0: League A, 1: League B, 2: Social

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Leagues'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Pills: League A / League B / Social matching Screen 4
            Row(
              children: [
                Expanded(
                  child: _SegmentPill(
                    label: 'League A',
                    selected: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentPill(
                    label: 'League B',
                    selected: _selectedTabIndex == 1,
                    onTap: () => setState(() => _selectedTabIndex = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentPill(
                    label: 'Social',
                    selected: _selectedTabIndex == 2,
                    onTap: () => setState(() => _selectedTabIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Text(
              _selectedTabIndex == 0
                  ? 'League A Standings'
                  : _selectedTabIndex == 1
                      ? 'League B Standings'
                      : 'Social Standings',
              style: AppTheme.body(15, weight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // Tab content matching Screen 4
            if (_selectedTabIndex == 0)
              const _StandingsTableScreen4(standings: leagueAStartingStandings)
            else if (_selectedTabIndex == 1)
              const _StandingsTableScreen4(standings: leagueBStartingStandings)
            else
              _StandingsEmptyState(
                icon: _selectedTabIndex == 1
                    ? Icons.emoji_events_outlined
                    : Icons.people_outline_rounded,
                message: _selectedTabIndex == 1
                    ? 'League B standings will appear as verified round scores are submitted.'
                    : 'Social standings will appear as verified round scores are submitted.',
              ),
          ],
        ),
      ),
    );
  }
}

class _StandingsEmptyState extends StatelessWidget {
  const _StandingsEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => ChristianGolfersCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.body(13, colour: AppTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : AppTheme.cardSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(
            13,
            weight: FontWeight.w700,
            colour: selected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Standings Table matching Screen 4 in the branding image.
class _StandingsTableScreen4 extends StatelessWidget {
  const _StandingsTableScreen4({required this.standings});

  final List<LeagueAStandingSnapshotEntry> standings;

  @override
  Widget build(BuildContext context) {
    final rows = standings;

    return Column(
      children: [
        ChristianGolfersCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.line)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#',
                        style: AppTheme.body(11.5, weight: FontWeight.w700, colour: AppTheme.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Name',
                        style: AppTheme.body(11.5, weight: FontWeight.w700, colour: AppTheme.textMuted),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        'L/S',
                        style: AppTheme.body(11.5, weight: FontWeight.w700, colour: AppTheme.textMuted),
                      ),
                    ),
                    Text(
                      'Total',
                      style: AppTheme.body(11.5, weight: FontWeight.w700, colour: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              // Table Rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = rows[index];
                  final isRank1 = item.position == 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: isRank1 ? AppTheme.primaryGreen : AppTheme.cardSecondary,
                            child: Text(
                              '${item.position}',
                              style: AppTheme.numeric(
                                11,
                                colour: isRank1 ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.firstName} ${item.initials} ${item.surname}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(13, weight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            'L',
                            style: AppTheme.body(12.5, colour: AppTheme.textMuted),
                          ),
                        ),
                        Text(
                          '${item.totalPoints}',
                          style: AppTheme.numeric(
                            13.5,
                            colour: AppTheme.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Showing ${standings.length} players',
            style: AppTheme.body(11, colour: AppTheme.textFaint),
          ),
        ),
      ],
    );
  }
}
