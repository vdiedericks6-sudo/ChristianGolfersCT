import '../../../core/data/json_parsing.dart';

class GolfRound {
  const GolfRound({
    required this.id,
    required this.hostUserId,
    required this.courseId,
    required this.courseName,
    required this.teeSetId,
    required this.teeSetName,
    required this.joinCode,
    required this.format,
    required this.status,
    required this.currentHole,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String hostUserId;
  final String courseId;
  final String courseName;
  final String teeSetId;
  final String teeSetName;
  final String joinCode;
  final String format;
  final String status;
  final int currentHole;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  factory GolfRound.fromJson(Json data) {
    return GolfRound(
      id: asString(data['id']),
      hostUserId: asString(data['host_user_id']),
      courseId: asString(data['course_id']),
      courseName: asString(data['course_name']),
      teeSetId: asString(data['tee_set_id']),
      teeSetName: asString(data['tee_set_name']),
      joinCode: asString(data['join_code']),
      format: asString(data['format'], 'strokePlay'),
      status: asString(data['status'], 'waiting'),
      currentHole: asInt(data['current_hole'], 1),
      createdAt: asDateOrNull(data['created_at']),
      startedAt: asDateOrNull(data['started_at']),
      completedAt: asDateOrNull(data['completed_at']),
    );
  }
}
