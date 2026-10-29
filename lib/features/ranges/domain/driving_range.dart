import '../../../core/data/json_parsing.dart';

/// Ball-tracking technology a range offers, where it is known.
enum BallTracking { none, toptracer, trackman, other }

class DrivingRange {
  const DrivingRange({
    required this.id,
    required this.name,
    required this.country,
    required this.province,
    required this.active,
    this.courseId,
    this.city,
    this.address,
    this.description,
    this.website,
    this.phone,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.bays,
    this.floodlit,
    this.covered,
    this.ballTracking,
    this.dataStatus,
    this.sourceUrl,
  });

  final String id;

  /// Set when the range belongs to a club that is also in the course list.
  final String? courseId;

  final String name;
  final String country;
  final String province;
  final String? city;
  final String? address;
  final String? description;
  final String? website;
  final String? phone;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool active;

  final int? bays;
  final bool? floodlit;
  final bool? covered;
  final BallTracking? ballTracking;

  final String? dataStatus;
  final String? sourceUrl;

  bool get isAtAClub => courseId != null;

  bool get hasLocation => latitude != null && longitude != null;

  /// Short line for a list row: the club, the town, or nothing.
  String get subtitle {
    final parts = <String>[
      if (city != null && city!.isNotEmpty) city!,
      if (province.isNotEmpty) province,
    ];
    return parts.join(', ');
  }

  factory DrivingRange.fromJson(Json data) {
    return DrivingRange(
      id: asString(data['id']),
      courseId: asStringOrNull(data['course_id']) ??
          asStringOrNull(data['courseId']),
      name: asString(data['name']),
      country: asString(data['country'], 'South Africa'),
      province: asString(data['province']),
      city: asStringOrNull(data['city']),
      address: asStringOrNull(data['address']),
      description: asStringOrNull(data['description']),
      website: asStringOrNull(data['website']),
      phone: asStringOrNull(data['phone']),
      imageUrl: asStringOrNull(data['image_url']) ??
          asStringOrNull(data['imageUrl']),
      latitude: asDoubleOrNull(data['latitude']),
      longitude: asDoubleOrNull(data['longitude']),
      active: asBool(data['active'], true),
      bays: asIntOrNull(data['bays']),
      floodlit: data['floodlit'] == null ? null : asBool(data['floodlit']),
      covered: data['covered'] == null ? null : asBool(data['covered']),
      ballTracking: _tracking(
        asStringOrNull(data['ball_tracking']) ??
            asStringOrNull(data['ballTracking']),
      ),
      dataStatus: asStringOrNull(data['data_status']) ??
          asStringOrNull(data['dataStatus']),
      sourceUrl: asStringOrNull(data['source_url']) ??
          asStringOrNull(data['sourceUrl']),
    );
  }

  static BallTracking? _tracking(String? value) {
    switch (value) {
      case 'none':
        return BallTracking.none;
      case 'toptracer':
        return BallTracking.toptracer;
      case 'trackman':
        return BallTracking.trackman;
      case 'other':
        return BallTracking.other;
      default:
        return null;
    }
  }
}
