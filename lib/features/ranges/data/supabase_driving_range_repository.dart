import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/driving_range.dart';
import 'driving_range_repository.dart';

class SupabaseDrivingRangeRepository implements DrivingRangeRepository {
  SupabaseDrivingRangeRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _ranges => _client.from('driving_ranges');

  @override
  Stream<List<DrivingRange>> watchActiveRanges() {
    return _ranges
        .stream(primaryKey: ['id'])
        .eq('active', true)
        .order('name', ascending: true)
        .map((rows) => rows.map(DrivingRange.fromJson).toList(growable: false));
  }

  @override
  Future<List<DrivingRange>> rangesForCourse(String courseId) async {
    final rows = await _ranges.select().eq('course_id', courseId);

    return rows.map(DrivingRange.fromJson).toList(growable: false);
  }

  @override
  Future<int> seedDrivingRanges() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/sa_driving_ranges.json',
    );

    final raw = jsonDecode(jsonText) as List<dynamic>;
    var written = 0;

    for (var start = 0; start < raw.length; start += 100) {
      final end = (start + 100 < raw.length) ? start + 100 : raw.length;

      final chunk = <Map<String, dynamic>>[
        for (var index = start; index < end; index++)
          _rangeRow(Map<String, dynamic>.from(raw[index] as Map)),
      ];

      await _ranges.upsert(chunk, onConflict: 'id');
      written += chunk.length;
    }

    return written;
  }

  Map<String, dynamic> _rangeRow(Map<String, dynamic> item) {
    return <String, dynamic>{
      'id': item['id'],
      'course_id': item['courseId'],
      'name': item['name'] ?? '',
      'country': item['country'] ?? 'South Africa',
      'province': item['province'] ?? '',
      'city': item['city'],
      'address': item['address'],
      'description': item['description'],
      'website': item['website'],
      'phone': item['phone'],
      'image_url': item['imageUrl'],
      'latitude': item['latitude'],
      'longitude': item['longitude'],
      'active': item['active'] ?? true,
      'data_status': item['dataStatus'],
      'source_url': item['sourceUrl'],
    };
  }
}
