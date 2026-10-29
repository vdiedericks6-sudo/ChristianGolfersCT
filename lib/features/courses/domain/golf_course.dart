import '../../../core/data/json_parsing.dart';

class GolfCourse {
  const GolfCourse({
    required this.id,
    required this.name,
    required this.country,
    required this.province,
    required this.active,
    required this.playable,
    this.city,
    this.address,
    this.description,
    this.website,
    this.phone,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.par,
    this.holes,
    this.dataStatus,
    this.sourceUrl,
  });

  final String id;
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
  final int? par;
  final int? holes;
  final bool active;
  final bool playable;
  final String? dataStatus;
  final String? sourceUrl;

  factory GolfCourse.fromJson(Json data) {
    return GolfCourse(
      id: asString(data['id']),
      name: asString(data['name']),
      country: asString(data['country']),
      province: asString(data['province']),
      city: asStringOrNull(data['city']),
      address: asStringOrNull(data['address']),
      description: asStringOrNull(data['description']),
      website: asStringOrNull(data['website']),
      phone: asStringOrNull(data['phone']),
      imageUrl: asStringOrNull(data['image_url']),
      latitude: asDoubleOrNull(data['latitude']),
      longitude: asDoubleOrNull(data['longitude']),
      par: asIntOrNull(data['par']),
      holes: asIntOrNull(data['holes']),
      active: asBool(data['active']),
      playable: asBool(data['playable'], true),
      dataStatus: asStringOrNull(data['data_status']),
      sourceUrl: asStringOrNull(data['source_url']),
    );
  }
}
