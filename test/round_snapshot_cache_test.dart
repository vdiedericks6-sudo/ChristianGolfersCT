import 'dart:async';

import 'package:christian_golfers/core/offline/round_snapshot_cache.dart';
import 'package:christian_golfers/features/courses/domain/tee_set.dart';
import 'package:christian_golfers/features/rounds/domain/golf_round.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'snapshots are isolated by account and survive reconstruction',
    () async {
      await RoundSnapshotCache.write('golfer-a', 'round', 'r1', {'id': 'r1'});
      expect(await RoundSnapshotCache.read('golfer-b', 'round', 'r1'), isNull);
      expect(await RoundSnapshotCache.read('golfer-a', 'round', 'r1'), {
        'id': 'r1',
      });
    },
  );

  test('reopening uses round details even before open list was cached', () async {
    await RoundSnapshotCache.write('golfer-a', 'round', 'r1', {'id':'r1', 'status':'active'});
    await RoundSnapshotCache.write('golfer-b', 'round', 'r2', {'id':'r2', 'status':'active'});
    expect(await RoundSnapshotCache.readOpenRounds('golfer-a'), [{'id':'r1', 'status':'active'}]);
    await RoundSnapshotCache.write('golfer-a', 'round_list', 'open', [{'id':'r1','status':'waiting'}]);
    await RoundSnapshotCache.write('golfer-a', 'round', 'r1', {'id':'r1', 'status':'completed'});
    expect(await RoundSnapshotCache.readOpenRounds('golfer-a'), isEmpty);
  });

  test('tee distances and round metadata survive serialization', () {
    const tee = TeeSet(
      id: 'white',
      name: 'White',
      colour: 'white',
      courseRating: 71.5,
      slopeRating: 120,
      par: 72,
      totalDistance: 6000,
      distanceUnit: 'metres',
      holeDistancesMeters: {1: 345, 18: 420},
    );
    final restored = TeeSet.fromJson(teeSnapshotJson(tee));
    expect(restored.holeDistancesMeters, {1: 345, 18: 420});
    final round = GolfRound.fromJson({
      'id': 'r',
      'host_user_id': 'u',
      'course_id': 'c',
      'course_name': 'Course',
      'tee_set_id': 'white',
      'tee_set_name': 'White',
      'join_code': 'ABC123',
      'format': 'strokePlay',
      'status': 'active',
      'current_hole': 4,
      'scheduled_at': '2026-11-22T08:00:00Z',
    });
    final result = GolfRound.fromJson(roundSnapshotJson(round));
    expect(result.currentHole, 4);
    expect(result.scheduledAt, round.scheduledAt);
  });

  test(
    'cached data appears first and refresh retries after offline error',
    () async {
      await RoundSnapshotCache.write('u', 'demo', 'x', ['old']);
      var attempts = 0;
      final values = await snapshotThenLive<List<String>>(
        userId: 'u',
        kind: 'demo',
        id: 'x',
        decode: (value) => (value as List).cast<String>(),
        encode: (value) => value,
        cacheable: (value) => value.isNotEmpty,
        live: () => ++attempts == 1
            ? Stream<List<String>>.error(StateError('offline'))
            : Stream.value(['new']),
        retryDelay: const Duration(milliseconds: 1),
      ).take(2).toList().timeout(const Duration(seconds: 2));
      expect(values, [
        ['old'],
        ['new'],
      ]);
      expect(await RoundSnapshotCache.read('u', 'demo', 'x'), ['new']);
    },
  );

  test('empty live snapshot does not erase saved data', () async {
    await RoundSnapshotCache.write('u', 'demo', 'x', ['old']);
    await snapshotThenLive<List<String>>(
      userId: 'u',
      kind: 'demo',
      id: 'x',
      decode: (value) => (value as List).cast<String>(),
      encode: (value) => value,
      cacheable: (value) => value.isNotEmpty,
      live: () => Stream.value(<String>[]),
    ).take(2).toList();
    expect(await RoundSnapshotCache.read('u', 'demo', 'x'), ['old']);
  });
}
