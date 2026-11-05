import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../../core/offline/round_snapshot_cache.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/course_repository.dart';
import '../data/supabase_course_repository.dart';
import '../domain/golf_course.dart';
import '../domain/golf_hole.dart';
import '../domain/tee_set.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.courses;

  return SupabaseCourseRepository(ref.watch(supabaseClientProvider));
});

final activeCoursesProvider = StreamProvider<List<GolfCourse>>((ref) {
  return ref.watch(courseRepositoryProvider).watchActiveCourses();
});

final selectedCourseProvider = StreamProvider.family<GolfCourse?, String>((
  ref,
  courseId,
) {
  return ref.watch(courseRepositoryProvider).watchCourse(courseId);
});

final courseTeeSetsProvider = StreamProvider.family<List<TeeSet>, String>((
  ref,
  courseId,
) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(courseRepositoryProvider);
  if (userId == null || ref.watch(demoBackendProvider) != null) {
    return repository.watchTeeSets(courseId);
  }
  return snapshotThenLive<List<TeeSet>>(
    userId: userId,
    kind: 'tees',
    id: courseId,
    decode: (value) => snapshotList(value, TeeSet.fromJson),
    encode: (value) => value.map(teeSnapshotJson).toList(),
    cacheable: (value) => value.isNotEmpty,
    live: () => repository.watchTeeSets(courseId),
  );
});

final courseHolesProvider = StreamProvider.family<List<GolfHole>, String>((
  ref,
  courseId,
) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(courseRepositoryProvider);
  if (userId == null || ref.watch(demoBackendProvider) != null) {
    return repository.watchHoles(courseId);
  }
  return snapshotThenLive<List<GolfHole>>(
    userId: userId,
    kind: 'holes',
    id: courseId,
    decode: (value) => snapshotList(value, GolfHole.fromJson),
    encode: (value) => value.map(holeSnapshotJson).toList(),
    cacheable: (value) => value.isNotEmpty,
    live: () => repository.watchHoles(courseId),
  );
});
