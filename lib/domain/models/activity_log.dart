import '../../core/constants.dart';

/// A single check-in record: "at this timestamp, user was doing X".
class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String? activityId; // null if fully custom one-off entry
  final String? customName; // used for "Other" entries
  final int score;
  final ActivityType type;
  final String? notes;

  const ActivityLog({
    required this.id,
    required this.timestamp,
    this.activityId,
    this.customName,
    required this.score,
    required this.type,
    this.notes,
  });

  ActivityLog copyWith({
    DateTime? timestamp,
    String? activityId,
    String? customName,
    int? score,
    ActivityType? type,
    String? notes,
  }) {
    return ActivityLog(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      activityId: activityId ?? this.activityId,
      customName: customName ?? this.customName,
      score: score ?? this.score,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'activity_id': activityId,
      'custom_name': customName,
      'score': score,
      'type': type.name,
      'notes': notes,
    };
  }

  factory ActivityLog.fromMap(Map<String, Object?> map) {
    return ActivityLog(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      activityId: map['activity_id'] as String?,
      customName: map['custom_name'] as String?,
      score: map['score'] as int,
      type: ActivityTypeX.fromString(map['type'] as String),
      notes: map['notes'] as String?,
    );
  }
}
