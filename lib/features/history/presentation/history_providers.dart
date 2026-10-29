import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../courses/presentation/course_providers.dart';
import '../../rounds/presentation/round_providers.dart';
import '../../scorecard/presentation/score_providers.dart';
import '../domain/player_stats.dart';
import '../domain/round_summary.dart';

/// Every round the golfer has played, with their own card attached.
///
/// Four reads rather than one join: the rounds, my scores in them, the courses
/// they were played on, and those courses' hole pars.
final roundHistoryProvider = FutureProvider<List<RoundSummary>>((ref) async {
  final rounds = await ref.watch(roundRepositoryProvider).myRounds();

  if (rounds.isEmpty) return const [];

  final roundIds = rounds.map((round) => round.id).toList();
  final courseIds = rounds.map((round) => round.courseId).toSet();

  final courseRepository = ref.watch(courseRepositoryProvider);

  final scores = await ref
      .watch(scoreRepositoryProvider)
      .myScoresForRounds(roundIds);
  final courses = await courseRepository.coursesByIds(courseIds);
  final holes = await courseRepository.holesForCourses(courseIds);

  final parByCourse = {
    for (final course in courses)
      if (course.par != null) course.id: course.par!,
  };

  final holeParsByCourse = {
    for (final entry in holes.entries)
      entry.key: {
        for (final hole in entry.value) hole.number: hole.par,
      },
  };

  final summaries = [
    for (final round in rounds)
      RoundSummary(
        round: round,
        myScores: scores
            .where((score) => score.roundId == round.id)
            .toList(growable: false),
        holePars: holeParsByCourse[round.courseId] ?? const <int, int>{},
        coursePar: parByCourse[round.courseId],
      ),
  ];

  summaries.sort((a, b) => b.playedAt.compareTo(a.playedAt));
  return summaries;
});

final playerStatsProvider = Provider<AsyncValue<PlayerStats>>((ref) {
  return ref.watch(roundHistoryProvider).whenData(PlayerStats.from);
});
