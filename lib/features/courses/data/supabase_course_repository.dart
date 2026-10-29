import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/golf_course.dart';
import '../domain/golf_hole.dart';
import '../domain/tee_set.dart';
import 'course_repository.dart';

class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _courses => _client.from('courses');

  @override
  Stream<List<GolfCourse>> watchActiveCourses() {
    return _courses
        .stream(primaryKey: ['id'])
        .eq('active', true)
        .order('name', ascending: true)
        .map((rows) => rows.map(GolfCourse.fromJson).toList(growable: false));
  }

  @override
  Stream<GolfCourse?> watchCourse(String courseId) {
    return _courses
        .stream(primaryKey: ['id'])
        .eq('id', courseId)
        .map((rows) => rows.isEmpty ? null : GolfCourse.fromJson(rows.first));
  }

  @override
  Stream<List<TeeSet>> watchTeeSets(String courseId) {
    return _client
        .from('tee_sets')
        .stream(primaryKey: ['course_id', 'id'])
        .eq('course_id', courseId)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <TeeSet>[];
          final teeIds = rows.map((row) => row['id'] as String).toList();
          final distanceRows = await _client
              .from('tee_box_hole_distances')
              .select('tee_set_id,hole_number,distance_meters')
              .eq('course_id', courseId)
              .inFilter('tee_set_id', teeIds);
          final distances = <String, Map<int, int>>{};
          for (final row in distanceRows) {
            final teeId = row['tee_set_id'] as String;
            (distances[teeId] ??= {})[row['hole_number'] as int] =
                row['distance_meters'] as int;
          }
          final tees = rows.map((row) {
            return TeeSet.fromJson({
              ...row,
              'hole_distances': distances[row['id']] ?? const <int, int>{},
            });
          }).toList();
          tees.sort((a, b) => a.totalDistance.compareTo(b.totalDistance));
          return tees;
        });
  }

  @override
  Stream<List<GolfHole>> watchHoles(String courseId) {
    return _client
        .from('holes')
        .stream(primaryKey: ['course_id', 'number'])
        .eq('course_id', courseId)
        .order('number', ascending: true)
        .map((rows) => rows.map(GolfHole.fromJson).toList(growable: false));
  }

  @override
  Future<bool> isCurrentUserAdmin(String userId) async {
    if (_client.auth.currentUser?.id != userId) return false;
    return _client.rpc<bool>('is_admin');
  }

  /// Imports the bundled South African course catalogue.
  ///
  /// Requires an allowlisted administrator — database RLS rejects other users.
  @override
  Future<int> seedSouthAfricanCourseCatalog() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/sa_golf_courses.json',
    );

    final raw = jsonDecode(jsonText) as List<dynamic>;
    var written = 0;

    // Upsert in chunks so a slow connection does not time out on one request.
    for (var start = 0; start < raw.length; start += 100) {
      final end = (start + 100 < raw.length) ? start + 100 : raw.length;

      final chunk = <Map<String, dynamic>>[
        for (var index = start; index < end; index++)
          _courseRow(Map<String, dynamic>.from(raw[index] as Map)),
      ];

      await _courses.upsert(chunk, onConflict: 'id');
      written += chunk.length;
    }

    return written;
  }

  Map<String, dynamic> _courseRow(Map<String, dynamic> item) {
    return <String, dynamic>{
      'id': item['id'],
      'name': item['name'] ?? '',
      'country': item['country'] ?? '',
      'province': item['province'] ?? '',
      'city': item['city'],
      'address': item['address'],
      'description': item['description'],
      'website': item['website'],
      'phone': item['phone'],
      'image_url': item['imageUrl'] ?? item['image_url'],
      'latitude': item['latitude'],
      'longitude': item['longitude'],
      'par': item['par'],
      'holes': item['holes'],
      'active': item['active'] ?? false,
      'playable': item['playable'] ?? true,
      'data_status': item['dataStatus'] ?? item['data_status'],
      'source_url': item['sourceUrl'] ?? item['source_url'],
    };
  }

  /// Creates the internal 18-hole test course used during development.
  @override
  Future<void> seedDevelopmentCourse() async {
    const courseId = 'christian-golfers-demo-course';

    await _courses.upsert({
      'id': courseId,
      'name': 'Christian Golfers Demo Course',
      'country': 'South Africa',
      'province': 'Western Cape',
      'city': 'Cape Town',
      'description':
          'Christian Golfers internal demo course with complete round data. Not a real club.',
      'latitude': -33.9249,
      'longitude': 18.4241,
      'active': true,
      'playable': true,
      'holes': 18,
      'par': 72,
      'data_status': 'development',
    }, onConflict: 'id');

    await _client.from('tee_sets').upsert([
      {
        'course_id': courseId,
        'id': 'red',
        'name': 'Red tees',
        'colour': 'Red',
        'course_rating': 70.1,
        'slope_rating': 118,
        'par': 72,
        'total_distance': 5310,
        'distance_unit': 'metres',
      },
      {
        'course_id': courseId,
        'id': 'yellow',
        'name': 'Yellow tees',
        'colour': 'Yellow',
        'course_rating': 71.5,
        'slope_rating': 122,
        'par': 72,
        'total_distance': 5740,
        'distance_unit': 'metres',
      },
      {
        'course_id': courseId,
        'id': 'blue',
        'name': 'Blue tees',
        'colour': 'Blue',
        'course_rating': 73.5,
        'slope_rating': 134,
        'par': 72,
        'total_distance': 6120,
        'distance_unit': 'metres',
      },
      {
        'course_id': courseId,
        'id': 'club',
        'name': 'White tees',
        'colour': 'White',
        'course_rating': 72.4,
        'slope_rating': 126,
        'par': 72,
        'total_distance': 6350,
        'distance_unit': 'metres',
      },
    ], onConflict: 'course_id,id');

    const pars = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4, 4];
    const strokeIndexes = [
      9,
      3,
      17,
      1,
      11,
      5,
      15,
      7,
      13,
      10,
      4,
      18,
      2,
      12,
      6,
      16,
      8,
      14,
    ];

    final holes = <Map<String, dynamic>>[];

    for (var index = 0; index < 18; index++) {
      final latitude = -33.9249 + (index * 0.00035);
      final longitude = 18.4241 + (index * 0.00028);

      holes.add({
        'course_id': courseId,
        'number': index + 1,
        'par': pars[index],
        'stroke_index': strokeIndexes[index],
        'tee_latitude': latitude,
        'tee_longitude': longitude,
        'green_front_latitude': latitude + 0.0018,
        'green_front_longitude': longitude + 0.0015,
        'green_centre_latitude': latitude + 0.0019,
        'green_centre_longitude': longitude + 0.0016,
        'green_back_latitude': latitude + 0.0020,
        'green_back_longitude': longitude + 0.0017,
      });
    }

    await _client.from('holes').upsert(holes, onConflict: 'course_id,number');

    const teeDistanceRanges = <String, List<int>>{
      'red': [130, 305, 435],
      'yellow': [145, 330, 465],
      'blue': [160, 350, 495],
      'club': [165, 365, 510],
    };
    final distances = <Map<String, dynamic>>[];
    for (final entry in teeDistanceRanges.entries) {
      for (var index = 0; index < pars.length; index++) {
        final par = pars[index];
        distances.add({
          'course_id': courseId,
          'tee_set_id': entry.key,
          'hole_number': index + 1,
          'distance_meters': par == 3
              ? entry.value[0]
              : par == 5
              ? entry.value[2]
              : entry.value[1],
          'source_url': 'internal demo data',
        });
      }
    }
    await _client
        .from('tee_box_hole_distances')
        .upsert(distances, onConflict: 'course_id,tee_set_id,hole_number');
  }

  @override
  Future<List<GolfCourse>> coursesByIds(Iterable<String> courseIds) async {
    final ids = courseIds.toSet().toList();
    if (ids.isEmpty) return const [];

    final rows = await _courses.select().inFilter('id', ids);

    return rows.map(GolfCourse.fromJson).toList(growable: false);
  }

  @override
  Future<Map<String, List<GolfHole>>> holesForCourses(
    Iterable<String> courseIds,
  ) async {
    final ids = courseIds.toSet().toList();
    if (ids.isEmpty) return const {};

    final rows = await _client
        .from('holes')
        .select()
        .inFilter('course_id', ids)
        .order('number', ascending: true);

    final grouped = <String, List<GolfHole>>{};
    for (final row in rows) {
      final courseId = row['course_id'] as String?;
      if (courseId == null) continue;
      (grouped[courseId] ??= <GolfHole>[]).add(GolfHole.fromJson(row));
    }
    return grouped;
  }

  /// Loads assets/data/sa_course_holes.json - a map of course id to its 18
  /// holes - and marks every course that gets a full card as playable.
  @override
  Future<int> seedCourseHoles() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/sa_course_holes.json',
    );

    final raw = jsonDecode(jsonText) as Map<String, dynamic>;
    final rows = <Map<String, dynamic>>[];
    final playableCourseIds = <String>[];

    raw.forEach((courseId, value) {
      final holes = (value as List<dynamic>).cast<Map<String, dynamic>>();

      if (holes.length >= 18) playableCourseIds.add(courseId);

      for (final hole in holes) {
        rows.add({
          'course_id': courseId,
          'number': hole['number'],
          'par': hole['par'],
          'stroke_index': hole['strokeIndex'],
          'tee_latitude': hole['teeLatitude'],
          'tee_longitude': hole['teeLongitude'],
          'green_front_latitude': hole['greenFrontLatitude'],
          'green_front_longitude': hole['greenFrontLongitude'],
          'green_centre_latitude': hole['greenCentreLatitude'],
          'green_centre_longitude': hole['greenCentreLongitude'],
          'green_back_latitude': hole['greenBackLatitude'],
          'green_back_longitude': hole['greenBackLongitude'],
          'image_url': hole['imageUrl'] ?? hole['image_url'],
        });
      }
    });

    for (var start = 0; start < rows.length; start += 200) {
      final end = (start + 200 < rows.length) ? start + 200 : rows.length;
      await _client
          .from('holes')
          .upsert(rows.sublist(start, end), onConflict: 'course_id,number');
    }

    // A course with a full card can host a real round.
    for (var start = 0; start < playableCourseIds.length; start += 100) {
      final end = (start + 100 < playableCourseIds.length)
          ? start + 100
          : playableCourseIds.length;

      await _courses
          .update({'playable': true})
          .inFilter('id', playableCourseIds.sublist(start, end));
    }

    // Starting a round needs a tee set, and OpenStreetMap has no course
    // ratings. Give every playable course one neutral set so it can be used
    // today. Slope 113 is the definitional standard - at it a course handicap
    // equals the handicap index - and the rating is taken as par. The name
    // says "unrated" so nobody mistakes these for official SAGA ratings.
    final tees = <Map<String, dynamic>>[];
    for (final courseId in playableCourseIds) {
      final par = (raw[courseId] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .fold<int>(0, (total, hole) => total + (hole['par'] as int));

      tees.add({
        'course_id': courseId,
        'id': 'default',
        'name': 'Club (unrated)',
        'colour': 'Unrated',
        'course_rating': par,
        'slope_rating': 113,
        'par': par,
        'total_distance': 0,
        'distance_unit': 'metres',
      });
    }

    for (var start = 0; start < tees.length; start += 200) {
      final end = (start + 200 < tees.length) ? start + 200 : tees.length;
      await _client
          .from('tee_sets')
          .upsert(tees.sublist(start, end), onConflict: 'course_id,id');
    }

    return rows.length;
  }
}
