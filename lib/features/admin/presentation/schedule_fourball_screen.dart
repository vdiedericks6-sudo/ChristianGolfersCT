import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../courses/presentation/course_providers.dart';
import '../../rounds/presentation/round_providers.dart';
import '../data/admin_league_dashboard_repository.dart';

class ScheduleFourballScreen extends ConsumerStatefulWidget {
  const ScheduleFourballScreen({super.key});
  @override
  ConsumerState<ScheduleFourballScreen> createState() =>
      _ScheduleFourballState();
}

class _ScheduleFourballState extends ConsumerState<ScheduleFourballScreen> {
  final _players = <String>[];
  // Stable across network retries; a new screen represents a new allocation.
  final _request = List.generate(
    32,
    (_) => Random.secure().nextInt(16).toRadixString(16),
  ).join();
  String? _course;
  String? _tee;
  DateTime? _when;
  bool _saving = false;
  bool _submitted = false;
  String? _error;

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(
      () => _when = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_course == null ||
        _tee == null ||
        _players.isEmpty ||
        _when == null ||
        !_when!.isAfter(DateTime.now())) {
      setState(
        () => _error =
            'Choose a course, tee, future time and one to four members.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _submitted = true;
      _error = null;
    });
    try {
      await ref
          .read(supabaseClientProvider)
          .rpc(
            'admin_schedule_fourball',
            params: {
              'p_course_id': _course,
              'p_tee_set_id': _tee,
              'p_scheduled_at': _when!.toUtc().toIso8601String(),
              'p_player_ids': _players,
              'p_request_key': _request,
            },
          );
      ref.invalidate(adminLeagueDashboardProvider);
      ref.invalidate(openRoundsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not confirm scheduling. Retry this same allocation to avoid duplicates. If you leave, check the dashboard before scheduling again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(activeCoursesProvider);
    final members = ref.watch(
      adminLeagueDashboardProvider(const AdminDashboardFilter()),
    );
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Schedule a fourball')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Scheduling…'
                        : _submitted
                        ? 'Retry same allocation'
                        : 'Schedule fourball',
                  ),
                ),
              ],
            ),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _saving || _submitted,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Allocate registered members to a round. The first selected member is the host and can start it. Schedule another fourball for each group.',
              ),
              const SizedBox(height: 16),
              courses.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(activeCoursesProvider),
                  child: const Text('Retry courses'),
                ),
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _course,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Round-ready course',
                  ),
                  items: items
                      .where((c) => c.playable)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (id) => setState(() {
                    _course = id;
                    _tee = null;
                  }),
                ),
              ),
              if (_course != null)
                ref
                    .watch(courseTeeSetsProvider(_course!))
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => TextButton(
                        onPressed: () =>
                            ref.invalidate(courseTeeSetsProvider(_course!)),
                        child: const Text('Retry tees'),
                      ),
                      data: (tees) => tees.isEmpty
                          ? const Text('No tee data available for this course.')
                          : DropdownButtonFormField<String>(
                              key: ValueKey(_course),
                              initialValue: _tee,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tee for this group',
                              ),
                              items: tees
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) => setState(() => _tee = id),
                            ),
                    ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(
                  _when == null
                      ? 'Choose tee time'
                      : '${_when!.day}/${_when!.month}/${_when!.year} ${TimeOfDay.fromDateTime(_when!).format(context)}',
                ),
                subtitle: const Text(
                  'Time shown in your device’s local timezone',
                ),
                onTap: _pickTime,
              ),
              Text('Members (${_players.length}/4)'),
              members.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(adminLeagueDashboardProvider),
                  child: const Text('Retry members'),
                ),
                data: (data) => Column(
                  children: data.members
                      .map(
                        (m) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.displayName),
                          subtitle: Text(
                            _players.isNotEmpty && _players.first == m.userId
                                ? '${m.email} · Host'
                                : m.email,
                          ),
                          value: _players.contains(m.userId),
                          onChanged:
                              !_players.contains(m.userId) &&
                                  _players.length == 4
                              ? null
                              : (selected) => setState(() {
                                  if (selected == true) {
                                    _players.add(m.userId);
                                  } else {
                                    _players.remove(m.userId);
                                  }
                                }),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
