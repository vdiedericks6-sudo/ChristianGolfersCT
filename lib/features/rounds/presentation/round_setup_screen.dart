import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../courses/presentation/course_providers.dart';
import 'round_providers.dart';

class RoundSetupScreen extends ConsumerStatefulWidget {
  const RoundSetupScreen({required this.courseId, super.key});
  final String courseId;
  @override
  ConsumerState<RoundSetupScreen> createState() => _RoundSetupState();
}

class _RoundSetupState extends ConsumerState<RoundSetupScreen> {
  String? _teeId;
  bool _review = false, _saving = false;
  String? _error;
  Future<void> _create() async {
    if (_saving) return;
    final course = ref
        .read(selectedCourseProvider(widget.courseId))
        .valueOrNull;
    final tees =
        ref.read(courseTeeSetsProvider(widget.courseId)).valueOrNull ?? [];
    final matches = tees.where((t) => t.id == _teeId);
    if (course == null || !course.playable || matches.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(roundRepositoryProvider)
          .createRound(course: course, teeSet: matches.first);
      ref.invalidate(openRoundsProvider);
      if (mounted) context.go('/rounds/$id/lobby');
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not confirm creation. Check My Rounds before retrying if your connection dropped.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(selectedCourseProvider(widget.courseId));
    final tees = ref.watch(courseTeeSetsProvider(widget.courseId));
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          leading: _review
              ? IconButton(
                  tooltip: 'Back to tee selection',
                  onPressed: _saving
                      ? null
                      : () => setState(() => _review = false),
                  icon: const Icon(Icons.arrow_back),
                )
              : const AppBackButton(),
          title: Text(_review ? 'Round settings' : 'Select tee box'),
        ),
        body: course.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Unable to load course. Go back and retry.'),
          ),
          data: (c) {
            if (c == null)
              return const Center(child: Text('Course unavailable'));
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  _review ? '03 / REVIEW YOUR ROUND' : '02 / CHOOSE YOUR TEES',
                  style: AppTheme.label(11),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CourseArtwork(
                    seed: c.id,
                    imageUrl: c.imageUrl,
                    height: 200,
                    fallbackLabel: '${c.name}\nCourse photograph not supplied',
                  ),
                ),
                const SizedBox(height: 16),
                Text(c.name, style: AppTheme.display(26)),
                Text(
                  '${c.city ?? c.province} · ${c.holes ?? 18} holes',
                  style: AppTheme.body(13, colour: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                tees.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => TextButton(
                    onPressed: () =>
                        ref.invalidate(courseTeeSetsProvider(widget.courseId)),
                    child: const Text('Retry tee data'),
                  ),
                  data: (items) {
                    final ratedTees = items
                        .where((tee) => tee.colour.toLowerCase() != 'unrated')
                        .toList();
                    final availableTees = ratedTees.isEmpty ? items : ratedTees;
                    final selected = items
                        .where((t) => t.id == _teeId)
                        .firstOrNull;
                    if (items.isEmpty)
                      return const Text(
                        'Tee data must be supplied before starting a round.',
                      );
                    if (_review && selected != null)
                      return Column(
                        children: [
                          _setting('Tee box', selected.name),
                          _setting('Round format', 'Stroke play'),
                          _setting('Starting hole', '1'),
                          _setting('Round length', '18 holes'),
                          const SizedBox(height: 16),
                          const Text(
                            'Only you are added initially. Invite other golfers from the round lobby. Start the round when your group is ready.',
                          ),
                        ],
                      );
                    return Column(
                      children: availableTees
                          .map(
                            (t) => Card(
                              child: RadioListTile<String>(
                                value: t.id,
                                groupValue: _teeId,
                                onChanged: _saving
                                    ? null
                                    : (v) => setState(() => _teeId = v),
                                title: Text(t.name),
                                subtitle: Text(
                                  '${t.totalDistance > 0 ? '${t.totalDistance} ${t.distanceUnit}' : 'Distance not supplied'}\n${t.name.toLowerCase().contains('unrated') ? 'Ratings not verified' : 'Course rating ${t.courseRating} · Slope ${t.slopeRating}'}',
                                ),
                                secondary: CircleAvatar(
                                  radius: 9,
                                  backgroundColor: _colour(t.colour),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed:
                  _saving ||
                      _teeId == null ||
                      course.valueOrNull?.playable != true
                  ? null
                  : () => _review ? _create() : setState(() => _review = true),
              child: Text(
                _saving
                    ? 'Creating round…'
                    : _review
                    ? 'Create round'
                    : 'Continue to round settings',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setting(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
  Color _colour(String colour) => switch (colour.toLowerCase()) {
    'white' => Colors.white,
    'yellow' => Colors.yellow,
    'blue' => Colors.blue,
    'red' => Colors.red,
    _ => AppTheme.primaryGreen,
  };
}
