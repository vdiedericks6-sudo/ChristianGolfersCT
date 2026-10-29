import '../../../core/data/json_parsing.dart';

class TeeSet {
  const TeeSet({
    required this.id,
    required this.name,
    required this.colour,
    required this.courseRating,
    required this.slopeRating,
    required this.par,
    required this.totalDistance,
    required this.distanceUnit,
    this.holeDistancesMeters = const {},
  });

  final String id;
  final String name;
  final String colour;
  final double courseRating;
  final int slopeRating;
  final int par;
  final int totalDistance;
  final String distanceUnit;

  /// Official per-hole carry/course distances where the club has supplied them.
  final Map<int, int> holeDistancesMeters;

  factory TeeSet.fromJson(Json data) {
    return TeeSet(
      id: asString(data['id']),
      name: asString(data['name']),
      colour: asString(data['colour']),
      courseRating: asDouble(data['course_rating']),
      slopeRating: asInt(data['slope_rating'], 113),
      par: asInt(data['par'], 72),
      totalDistance: asInt(data['total_distance']),
      distanceUnit: asString(data['distance_unit'], 'metres'),
      holeDistancesMeters: _parseHoleDistances(data['hole_distances']),
    );
  }

  static Map<int, int> _parseHoleDistances(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (int.tryParse('${entry.key}') != null && entry.value is num)
          int.parse('${entry.key}'): (entry.value as num).round(),
    };
  }
}
