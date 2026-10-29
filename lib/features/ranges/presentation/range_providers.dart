import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/driving_range_repository.dart';
import '../data/supabase_driving_range_repository.dart';
import '../domain/driving_range.dart';

final drivingRangeRepositoryProvider = Provider<DrivingRangeRepository>((ref) {
  final demo = ref.watch(demoBackendProvider);
  if (demo != null) return demo.ranges;

  return SupabaseDrivingRangeRepository(ref.watch(supabaseClientProvider));
});

final activeDrivingRangesProvider = StreamProvider<List<DrivingRange>>((ref) {
  return ref.watch(drivingRangeRepositoryProvider).watchActiveRanges();
});

final rangesForCourseProvider =
    FutureProvider.family<List<DrivingRange>, String>((ref, courseId) {
  return ref.watch(drivingRangeRepositoryProvider).rangesForCourse(courseId);
});
