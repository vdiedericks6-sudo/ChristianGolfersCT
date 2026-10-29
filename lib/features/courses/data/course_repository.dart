import '../domain/golf_course.dart';
import '../domain/golf_hole.dart';
import '../domain/tee_set.dart';

abstract class CourseRepository {
  Stream<List<GolfCourse>> watchActiveCourses();

  Stream<GolfCourse?> watchCourse(String courseId);

  Stream<List<TeeSet>> watchTeeSets(String courseId);

  Stream<List<GolfHole>> watchHoles(String courseId);

  Future<List<GolfCourse>> coursesByIds(Iterable<String> courseIds);

  /// Hole data for several courses at once, keyed by course id. Courses with
  /// no captured holes are simply absent from the result.
  Future<Map<String, List<GolfHole>>> holesForCourses(Iterable<String> courseIds);

  Future<bool> isCurrentUserAdmin(String userId);

  /// Imports the bundled South African catalogue. Returns rows written.
  Future<int> seedSouthAfricanCourseCatalog();

  /// Imports per-hole data for the courses that have it, and marks those
  /// courses playable. Returns the number of holes written.
  Future<int> seedCourseHoles();

  Future<void> seedDevelopmentCourse();
}
