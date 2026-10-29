import 'dart:math' as math;

import '../../../core/data/json_parsing.dart';

class GolfHole {
  const GolfHole({
    required this.number,
    required this.par,
    required this.strokeIndex,
    required this.teeLatitude,
    required this.teeLongitude,
    required this.greenFrontLatitude,
    required this.greenFrontLongitude,
    required this.greenCentreLatitude,
    required this.greenCentreLongitude,
    required this.greenBackLatitude,
    required this.greenBackLongitude,
    this.imageUrl,
  });

  final int number;
  final int par;
  final int strokeIndex;
  final double teeLatitude;
  final double teeLongitude;
  final double greenFrontLatitude;
  final double greenFrontLongitude;
  final double greenCentreLatitude;
  final double greenCentreLongitude;
  final double greenBackLatitude;
  final double greenBackLongitude;
  final String? imageUrl;

  /// Approximate straight-line GPS distance in metres; this is not an
  /// official scorecard yardage and is null when the coordinates are absent.
  int? get estimatedStraightLineMeters {
    if ([
      teeLatitude,
      teeLongitude,
      greenCentreLatitude,
      greenCentreLongitude,
    ].any((value) => value == 0 || !value.isFinite)) {
      return null;
    }
    const earthRadiusMeters = 6371000.0;
    final lat1 = _radians(teeLatitude);
    final lat2 = _radians(greenCentreLatitude);
    final deltaLat = _radians(greenCentreLatitude - teeLatitude);
    final deltaLon = _radians(greenCentreLongitude - teeLongitude);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final boundedA = a.clamp(0.0, 1.0);
    return (earthRadiusMeters *
            2 *
            math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA)))
        .round();
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  factory GolfHole.fromJson(Json data) {
    return GolfHole(
      number: asInt(data['number']),
      par: asInt(data['par'], 4),
      strokeIndex: asInt(data['stroke_index'], 18),
      teeLatitude: asDouble(data['tee_latitude']),
      teeLongitude: asDouble(data['tee_longitude']),
      greenFrontLatitude: asDouble(data['green_front_latitude']),
      greenFrontLongitude: asDouble(data['green_front_longitude']),
      greenCentreLatitude: asDouble(data['green_centre_latitude']),
      greenCentreLongitude: asDouble(data['green_centre_longitude']),
      greenBackLatitude: asDouble(data['green_back_latitude']),
      greenBackLongitude: asDouble(data['green_back_longitude']),
      imageUrl: asStringOrNull(data['image_url']),
    );
  }
}
