import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/courses/domain/golf_hole.dart';
import '../../features/courses/domain/tee_set.dart';
import '../../features/rounds/domain/golf_round.dart';
import '../../features/rounds/domain/round_player.dart';

/// A last-known snapshot only: it is never a replacement for server authority.
/// Namespacing by the authenticated account prevents reuse after sign-out.
class RoundSnapshotCache {
  static String _key(String userId, String kind, String id) =>
      'cgct.snapshot.v1.$userId.$kind.$id';

  static Future<Object?> read(String userId, String kind, String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId, kind, id));
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    String userId,
    String kind,
    String id,
    Object value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _key(userId, kind, id),
      jsonEncode(value),
    );
    if (!saved) throw StateError('Could not save round snapshot.');
  }

  /// Merge the last open-round list with individual round snapshots. A golfer
  /// who started a round can therefore reopen it offline even if they never
  /// visited the open-round list again before losing connectivity.
  static Future<Object?> readOpenRounds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final byId = <String, Map<String, dynamic>>{};
      final list = prefs.getString(_key(userId, 'round_list', 'open'));
      if (list != null) {
        for (final value in jsonDecode(list) as List) {
          final map = snapshotMap(value as Object);
          if (map['id'] is String) byId[map['id'] as String] = map;
        }
      }
      final prefix = _key(userId, 'round', '');
      for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        final map = snapshotMap(jsonDecode(raw) as Object);
        if (map['id'] is String) byId[map['id'] as String] = map;
      }
      if (byId.isEmpty) return null;
      return byId.values.where((row) => row['status'] == 'waiting' || row['status'] == 'active').toList();
    } catch (_) {
      return null;
    }
  }
}

/// Return cached data immediately, then subscribe to fresh data. Failed or
/// empty responses never erase an existing snapshot. A disconnected stream is
/// resubscribed so that reconnection can refresh the screen automatically.
Stream<T> snapshotThenLive<T>({
  required String userId,
  required String kind,
  required String id,
  required T Function(Object) decode,
  required Object Function(T) encode,
  required bool Function(T) cacheable,
  required Stream<T> Function() live,
  Future<Object?> Function()? readCached,
  Duration retryDelay = const Duration(seconds: 10),
}) async* {
  var hasSnapshot = false;
  final raw = await (readCached?.call() ?? RoundSnapshotCache.read(userId, kind, id));
  if (raw != null) {
    try {
      final cached = decode(raw);
      hasSnapshot = true;
      yield cached;
    } catch (_) {
      // Invalid or old cache data is ignored, not used for scoring.
    }
  }
  while (true) {
    try {
      await for (final value in live()) {
        if (cacheable(value)) {
          try {
            await RoundSnapshotCache.write(userId, kind, id, encode(value));
            hasSnapshot = true;
          } catch (_) {
            // The live value remains usable even if caching fails.
          }
        }
        yield value;
      }
    } catch (error, stack) {
      if (!hasSnapshot) yield* Stream<T>.error(error, stack);
    }
    await Future<void>.delayed(retryDelay);
  }
}

Map<String, dynamic> roundSnapshotJson(GolfRound r) => {
  'id': r.id,
  'host_user_id': r.hostUserId,
  'course_id': r.courseId,
  'course_name': r.courseName,
  'tee_set_id': r.teeSetId,
  'tee_set_name': r.teeSetName,
  'join_code': r.joinCode,
  'format': r.format,
  'status': r.status,
  'current_hole': r.currentHole,
  'created_at': r.createdAt?.toUtc().toIso8601String(),
  'started_at': r.startedAt?.toUtc().toIso8601String(),
  'completed_at': r.completedAt?.toUtc().toIso8601String(),
  'scheduled_at': r.scheduledAt?.toUtc().toIso8601String(),
};

Map<String, dynamic> playerSnapshotJson(RoundPlayer p) => {
  'user_id': p.userId,
  'display_name': p.displayName,
  'role': p.role,
  'active': p.active,
  'handicap_index': p.handicapIndex,
  'course_handicap': p.courseHandicap,
  'playing_handicap': p.playingHandicap,
  'joined_at': p.joinedAt?.toUtc().toIso8601String(),
  'tee_set_id': p.teeSetId,
};

Map<String, dynamic> holeSnapshotJson(GolfHole h) => {
  'number': h.number,
  'par': h.par,
  'stroke_index': h.strokeIndex,
  'tee_latitude': h.teeLatitude,
  'tee_longitude': h.teeLongitude,
  'green_front_latitude': h.greenFrontLatitude,
  'green_front_longitude': h.greenFrontLongitude,
  'green_centre_latitude': h.greenCentreLatitude,
  'green_centre_longitude': h.greenCentreLongitude,
  'green_back_latitude': h.greenBackLatitude,
  'green_back_longitude': h.greenBackLongitude,
  'image_url': h.imageUrl,
};

Map<String, dynamic> teeSnapshotJson(TeeSet t) => {
  'id': t.id,
  'name': t.name,
  'colour': t.colour,
  'course_rating': t.courseRating,
  'slope_rating': t.slopeRating,
  'par': t.par,
  'total_distance': t.totalDistance,
  'distance_unit': t.distanceUnit,
  'selectable': t.selectable,
  'hole_distances': {
    for (final e in t.holeDistancesMeters.entries) '${e.key}': e.value,
  },
};

Map<String, dynamic> snapshotMap(Object value) =>
    Map<String, dynamic>.from(value as Map);

List<T> snapshotList<T>(
  Object value,
  T Function(Map<String, dynamic>) decode,
) =>
    (value as List).map((item) => decode(snapshotMap(item as Object))).toList();
