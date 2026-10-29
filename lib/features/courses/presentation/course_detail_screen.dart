import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../../core/widgets/hole_artwork.dart';
import '../../../core/widgets/osm_attribution.dart';
import '../../ranges/presentation/range_providers.dart';
import '../../rounds/presentation/round_providers.dart';
import '../domain/tee_set.dart';
import 'course_providers.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  String? _selectedTeeId;
  bool _creatingRound = false;

  Future<void> _createRound() async {
    final course = ref
        .read(selectedCourseProvider(widget.courseId))
        .valueOrNull;
    final tees = ref.read(courseTeeSetsProvider(widget.courseId)).valueOrNull;

    if (course == null ||
        !course.playable ||
        tees == null ||
        _selectedTeeId == null) {
      return;
    }

    TeeSet? selectedTee;
    for (final tee in tees) {
      if (tee.id == _selectedTeeId) {
        selectedTee = tee;
        break;
      }
    }

    if (selectedTee == null) return;

    setState(() => _creatingRound = true);

    try {
      final roundId = await ref
          .read(roundRepositoryProvider)
          .createRound(course: course, teeSet: selectedTee);

      if (mounted) {
        context.go('/rounds/$roundId/lobby');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _creatingRound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(selectedCourseProvider(widget.courseId));
    final teeSets = ref.watch(courseTeeSetsProvider(widget.courseId));
    final holes = ref.watch(courseHolesProvider(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Course details'),
      ),
      body: SafeArea(
        child: course.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (item) {
            if (item == null) {
              return const Center(child: Text('Course not found.'));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                // The course's own scene, with a real photograph taking
                // precedence when the catalogue has one.
                ClipRRect(
                  borderRadius: AppTheme.cardRadius,
                  child: Stack(
                    children: [
                      CourseArtwork(
                        seed: item.id,
                        imageUrl: item.imageUrl,
                        height: 190,
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppTheme.display(26)),
                            if (item.city != null || item.province.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  [
                                    if ((item.city ?? '').isNotEmpty)
                                      item.city!,
                                    item.province,
                                  ].where((v) => v.isNotEmpty).join(', '),
                                  style: AppTheme.body(
                                    12.5,
                                    colour: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (item.par != null) MetaPill('Par ${item.par}'),
                    if (item.holes != null) MetaPill('${item.holes} holes'),
                    MetaPill(
                      item.playable ? 'Round ready' : 'Catalogue course',
                      colour: item.playable
                          ? AppTheme.onLight
                          : AppTheme.textMuted,
                      background: item.playable ? AppTheme.gold : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  [
                    if ((item.city ?? '').isNotEmpty) item.city!,
                    item.province,
                    item.country,
                  ].join(', '),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.forest,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(item.description!),
                ],
                if ((item.address ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.forest,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.address!)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                if (!item.playable)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.sand,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_outlined, color: AppTheme.forest),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a real course catalog entry. '
                            'Round creation stays disabled until verified '
                            'tee ratings, slope ratings, stroke indexes and '
                            'hole GPS data are loaded.',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.playable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Choose tees',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  teeSets.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => Text('$error'),
                    data: (tees) {
                      if (tees.isEmpty) {
                        return const Text('No tee sets are available.');
                      }

                      _selectedTeeId ??= tees.first.id;

                      const standardTeeColours = [
                        'White',
                        'Yellow',
                        'Blue',
                        'Red',
                      ];

                      return Column(
                        children: [
                          for (final tee in tees)
                            _TeeSetTile(
                              tee: tee,
                              selected: tee.id == _selectedTeeId,
                              onTap: () {
                                setState(() => _selectedTeeId = tee.id);
                              },
                            ),
                          for (final colour in standardTeeColours)
                            if (!tees.any(
                              (tee) =>
                                  tee.colour.toLowerCase() ==
                                  colour.toLowerCase(),
                            ))
                              _MissingTeeBox(colour: colour),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Holes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  holes.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => Text('$error'),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Text('No holes are available.');
                      }

                      return Card(
                        child: Column(
                          children: items.map((hole) {
                            TeeSet? selectedTee;
                            for (final tee in teeSets.valueOrNull ?? const []) {
                              if (tee.id == _selectedTeeId) {
                                selectedTee = tee;
                                break;
                              }
                            }
                            final officialDistance =
                                selectedTee?.holeDistancesMeters[hole.number];
                            final estimate = hole.estimatedStraightLineMeters;

                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 76,
                                    child: HoleArtwork(
                                      hole: hole,
                                      seed: '${item.id}-${hole.number}',
                                      height: 60,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Hole ${hole.number}'),
                                        Text(
                                          'Par ${hole.par} · Stroke index ${hole.strokeIndex}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (officialDistance != null)
                                    Text('$officialDistance m')
                                  else if (estimate != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('~$estimate m'),
                                        Text(
                                          'GPS line',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ],
                                    )
                                  else
                                    const Text('Distance N/A'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _selectedTeeId == null || _creatingRound
                        ? null
                        : _createRound,
                    icon: const Icon(Icons.groups_rounded),
                    label: Text(
                      _creatingRound ? 'Creating round...' : 'Create round',
                    ),
                  ),
                ],
                _PracticeFacilities(courseId: widget.courseId),
                const OsmAttribution(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissingTeeBox extends StatelessWidget {
  const _MissingTeeBox({required this.colour});

  final String colour;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: _TeeMarker(colour: colour),
    title: Text('$colour tee box'),
    subtitle: const Text('Club rating and hole distances not supplied'),
    enabled: false,
  );
}

class _TeeMarker extends StatelessWidget {
  const _TeeMarker({required this.colour});

  final String colour;

  @override
  Widget build(BuildContext context) {
    final marker = switch (colour.toLowerCase()) {
      'red' => const Color(0xFFC0504D),
      'white' => const Color(0xFFE8E8E8),
      'blue' => const Color(0xFF4A7BB0),
      'yellow' => const Color(0xFFD8C35A),
      _ => AppTheme.textMuted,
    };
    return Container(
      width: 12,
      height: 32,
      decoration: BoxDecoration(
        color: marker,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.line),
      ),
    );
  }
}

class _TeeSetTile extends StatelessWidget {
  const _TeeSetTile({
    required this.tee,
    required this.selected,
    required this.onTap,
  });

  final TeeSet tee;
  final bool selected;
  final VoidCallback onTap;

  /// The physical tee marker colour, so the tile reads like the course does.
  Color get _markerColour {
    switch (tee.colour.toLowerCase()) {
      case 'red':
        return const Color(0xFFC0504D);
      case 'white':
        return const Color(0xFFE8E8E8);
      case 'black':
        return const Color(0xFF2B2B2B);
      case 'blue':
        return const Color(0xFF4A7BB0);
      case 'yellow':
        return const Color(0xFFD8C35A);
      case 'green':
        return const Color(0xFF5A8F6B);
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // "Unrated" tees come from the OpenStreetMap import, which has no course
    // ratings. Say so rather than let a placeholder read as official.
    final unrated = tee.name.toLowerCase().contains('unrated');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: ChristianGolfersCard(
          onTap: onTap,
          colour: selected ? AppTheme.cardRaised : AppTheme.card,
          border: selected ? AppTheme.gold : AppTheme.line,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppTheme.gold : AppTheme.line,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Container(
                width: 10,
                height: 34,
                decoration: BoxDecoration(
                  color: _markerColour,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tee.name,
                      style: AppTheme.body(
                        15,
                        weight: FontWeight.w700,
                        colour: selected ? AppTheme.gold : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (tee.totalDistance > 0)
                          MetaPill('${tee.totalDistance} ${tee.distanceUnit}'),
                        MetaPill('Par ${tee.par}'),
                        if (unrated)
                          const MetaPill('Unrated', colour: AppTheme.textFaint)
                        else ...[
                          MetaPill('CR ${tee.courseRating.toStringAsFixed(1)}'),
                          MetaPill('Slope ${tee.slopeRating}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeFacilities extends ConsumerWidget {
  const _PracticeFacilities({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranges = ref.watch(rangesForCourseProvider(courseId)).valueOrNull;

    if (ranges == null || ranges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Practice',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final range in ranges)
          Card(
            color: AppTheme.mint,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(
                Icons.sports_golf_rounded,
                color: AppTheme.forest,
              ),
              title: Text(
                range.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  if (range.bays != null) '${range.bays} bays',
                  if (range.floodlit == true) 'floodlit',
                  if (range.covered == true) 'covered',
                ].join(' · '),
              ),
            ),
          ),
      ],
    );
  }
}
