/// A daily goal the user sets for themselves. Goals always track "today"
/// and reset naturally each day since their progress is computed live from
/// today's logs/stats rather than stored.
enum GoalType {
  activity, // check in a specific activity N times today
  goodActivities, // do N good activities (any) today
  xpPoints, // earn N XP today
}

class Goal {
  final String id;
  final String title;
  final GoalType type;
  final String? targetActivityId; // used when type == GoalType.activity
  final int targetValue;
  final bool enabled;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.type,
    this.targetActivityId,
    required this.targetValue,
    this.enabled = true,
    required this.createdAt,
  });

  Goal copyWith({
    String? title,
    GoalType? type,
    String? targetActivityId,
    int? targetValue,
    bool? enabled,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetActivityId: targetActivityId ?? this.targetActivityId,
      targetValue: targetValue ?? this.targetValue,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'type': type.name,
        'target_activity_id': targetActivityId,
        'target_value': targetValue,
        'enabled': enabled ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Goal.fromMap(Map<String, Object?> map) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      type: GoalType.values.firstWhere((e) => e.name == map['type']),
      targetActivityId: map['target_activity_id'] as String?,
      targetValue: map['target_value'] as int,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

/// A goal paired with its live progress for "today".
class GoalProgress {
  final Goal goal;
  final int progress;

  const GoalProgress({required this.goal, required this.progress});

  bool get completed => progress >= goal.targetValue;

  double get fraction =>
      goal.targetValue <= 0 ? 1.0 : (progress / goal.targetValue).clamp(0.0, 1.0);
}
