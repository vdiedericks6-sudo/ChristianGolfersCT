import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/course_artwork.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/christian_golfers_components.dart';
import '../../../core/widgets/osm_attribution.dart';
import '../domain/golf_course.dart';
import 'course_providers.dart';

/// Browse the South African catalogue matching Screen 3 in the branding image.
class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  final _searchController = TextEditingController();

  String _query = '';
  String _selectedRegion = 'All';

  final List<String> _regions = [
    'All',
    'Western Cape',
    'Gauteng',
    'Eastern Cape',
    'KwaZulu-Natal',
    'Free State',
    'Limpopo',
    'Mpumalanga',
    'North West',
    'Northern Cape',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(String query, List<String> haystack) {
    if (query.isEmpty) return true;
    return haystack.any((value) => value.toLowerCase().contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final coursesState = ref.watch(activeCoursesProvider);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text('Courses'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search field matching Screen 3
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: const Icon(
                    Icons.tune_rounded,
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.line),
                  ),
                ),
              ),
            ),

            // Region Filter Chips matching Screen 3
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _regions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final region = _regions[index];
                  final selected = region == _selectedRegion;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRegion = region),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryGreen
                            : AppTheme.cardSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        region,
                        style: AppTheme.body(
                          12.5,
                          weight: FontWeight.w700,
                          colour: selected
                              ? const Color(0xFF19201D)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: coursesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    _LoadFailed(what: 'courses', error: error),
                data: (items) => _buildCoursesList(context, items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, List<GolfCourse> items) {
    final query = _query.trim().toLowerCase();

    final filtered = items.where((course) {
      if (_selectedRegion != 'All' &&
          !course.province.toLowerCase().contains(
            _selectedRegion.toLowerCase(),
          )) {
        return false;
      }

      return _matches(query, [
        course.name,
        course.city ?? '',
        course.province,
        course.country,
      ]);
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        if (filtered.isEmpty)
          const _NoResults(message: 'No courses match your search.')
        else
          ...filtered.map((course) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCardScreen3(course: course),
            );
          }),
        const SizedBox(height: 8),
        const OsmAttribution(),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.what, required this.error});

  final String what;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load $what.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ChristianGolfersCard(
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

/// Course item card matching Screen 3 in the branding image.
class _CourseCardScreen3 extends StatelessWidget {
  const _CourseCardScreen3({required this.course});

  final GolfCourse course;

  @override
  Widget build(BuildContext context) {
    final location = course.province.isNotEmpty
        ? course.province
        : (course.city ?? 'South Africa');

    return ChristianGolfersCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/courses/${course.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Course Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: CourseArtwork(
                  seed: course.id,
                  imageUrl: course.imageUrl,
                  fallbackLabel: 'Course photo unavailable',
                  height: 72,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Course Title, Location & Rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(11.5, colour: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.playable
                        ? '${course.holes ?? 18} hole data available'
                        : 'Course listing',
                    style: AppTheme.body(
                      11,
                      colour: AppTheme.textMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
