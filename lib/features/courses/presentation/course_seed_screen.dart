import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../../ranges/presentation/range_providers.dart';
import 'course_providers.dart';

class CourseSeedScreen extends ConsumerStatefulWidget {
  const CourseSeedScreen({super.key});

  @override
  ConsumerState<CourseSeedScreen> createState() => _CourseSeedScreenState();
}

class _CourseSeedScreenState extends ConsumerState<CourseSeedScreen> {
  bool _busy = false;
  String? _message;

  Future<bool> _ensureAdmin() async {
    final userId = ref.read(currentUserIdProvider);

    if (userId == null) {
      setState(() => _message = 'Sign in before importing course data.');
      return false;
    }

    final repository = ref.read(courseRepositoryProvider);
    final isAdmin = await repository.isCurrentUserAdmin(userId);

    if (!isAdmin) {
      setState(
        () => _message =
            'Set is_admin to true on profiles/$userId before importing.',
      );
      return false;
    }

    return true;
  }

  Future<void> _importNationwideCatalog() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (!await _ensureAdmin()) return;

      final courseRepository = ref.read(courseRepositoryProvider);

      final courses = await courseRepository.seedSouthAfricanCourseCatalog();
      if (mounted) {
        setState(() => _message = '$courses courses imported. Loading holes...');
      }

      final holes = await courseRepository.seedCourseHoles();
      if (mounted) {
        setState(() => _message = '$courses courses, $holes holes. '
            'Loading driving ranges...');
      }

      final ranges = await ref
          .read(drivingRangeRepositoryProvider)
          .seedDrivingRanges();

      if (mounted) {
        setState(
          () => _message = 'Imported $courses courses, $holes holes and '
              '$ranges driving ranges. Courses with a full 18-hole card are '
              'now marked round-ready.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Import failed: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshDevelopmentCourse() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (!await _ensureAdmin()) return;

      await ref.read(courseRepositoryProvider).seedDevelopmentCourse();

      if (mounted) {
        setState(() => _message = 'Development course refreshed.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Unable to seed development course: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course data tools')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'South African course catalog',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'The bundled catalog was generated from the South African '
              'province course directories during Phase 9C.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _importNationwideCatalog,
              icon: const Icon(Icons.public_rounded),
              label: Text(
                _busy ? 'Importing...' : 'Import nationwide course catalog',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _refreshDevelopmentCourse,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Refresh development course'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Catalog courses are discovery records only. '
                  'They remain non-playable until tee-specific Course Rating, '
                  'Slope Rating, hole stroke indexes and GPS coordinates '
                  'have been verified and loaded.',
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
