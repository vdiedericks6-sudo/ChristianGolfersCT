import '../../../core/data/json_parsing.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.preferredDistanceUnit,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.estimatedHandicapIndex,
    this.isAdmin = false,
    this.isVisitingGolfer = false,
    this.handicapSource,
    this.handicapVerifiedAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final double? estimatedHandicapIndex;
  final String preferredDistanceUnit;
  final bool isAdmin;
  final bool isVisitingGolfer;
  final String? handicapSource;
  final DateTime? handicapVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Json data) {
    return UserProfile(
      id: asString(data['id']),
      displayName: asString(data['display_name']),
      email: asString(data['email']),
      photoUrl: asStringOrNull(data['photo_url']),
      estimatedHandicapIndex: asDoubleOrNull(data['estimated_handicap_index']),
      preferredDistanceUnit:
          asString(data['preferred_distance_unit'], 'metres'),
      isAdmin: asBool(data['is_admin']),
      isVisitingGolfer: asBool(data['is_visiting_golfer']),
      handicapSource: asStringOrNull(data['handicap_source']),
      handicapVerifiedAt: data['handicap_verified_at'] == null
          ? null
          : asDate(data['handicap_verified_at']),
      createdAt: asDate(data['created_at']),
      updatedAt: asDate(data['updated_at']),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    double? estimatedHandicapIndex,
    bool clearHandicap = false,
    String? preferredDistanceUnit,
    bool? isAdmin,
    bool? isVisitingGolfer,
    String? handicapSource,
    bool clearHandicapSource = false,
    DateTime? handicapVerifiedAt,
    bool clearHandicapVerifiedAt = false,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      estimatedHandicapIndex: clearHandicap
          ? null
          : estimatedHandicapIndex ?? this.estimatedHandicapIndex,
      preferredDistanceUnit:
          preferredDistanceUnit ?? this.preferredDistanceUnit,
      isAdmin: isAdmin ?? this.isAdmin,
      isVisitingGolfer: isVisitingGolfer ?? this.isVisitingGolfer,
      handicapSource: clearHandicapSource
          ? null
          : handicapSource ?? this.handicapSource,
      handicapVerifiedAt: clearHandicapVerifiedAt
          ? null
          : handicapVerifiedAt ?? this.handicapVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
