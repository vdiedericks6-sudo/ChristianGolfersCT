import '../domain/driving_range.dart';

abstract class DrivingRangeRepository {
  Stream<List<DrivingRange>> watchActiveRanges();

  /// Ranges belonging to a particular club.
  Future<List<DrivingRange>> rangesForCourse(String courseId);

  /// Imports the bundled catalogue. Requires admin. Returns rows written.
  Future<int> seedDrivingRanges();
}
