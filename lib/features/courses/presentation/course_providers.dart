import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
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
  return ref.watch(courseRepositoryProvider).watchTeeSets(courseId);
});

final courseHolesProvider = StreamProvider.family<List<GolfHole>, String>((
  ref,
  courseId,
) {
  return ref.watch(courseRepositoryProvider).watchHoles(courseId);
});
