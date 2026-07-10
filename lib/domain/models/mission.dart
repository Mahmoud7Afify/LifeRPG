enum MissionPeriod { daily, weekly }

enum MissionTriggerType {
  earnXp,
  activityCountByName, // "Study 3 times"
  activityCountByCategory,
  abstain, // "No Social Media for N days"
}

class Mission {
  final String id;
  final String title;
  final MissionPeriod period;
  final MissionTriggerType triggerType;
  final int targetValue;
  final String? targetName; // activity name/category for relevant trigger types
  final int progress;
  final bool completed;
  final DateTime periodStart; // start of the day/week this mission belongs to

  const Mission({
    required this.id,
    required this.title,
    required this.period,
    required this.triggerType,
    required this.targetValue,
    this.targetName,
    this.progress = 0,
    this.completed = false,
    required this.periodStart,
  });

  Mission copyWith({int? progress, bool? completed}) {
    return Mission(
      id: id,
      title: title,
      period: period,
      triggerType: triggerType,
      targetValue: targetValue,
      targetName: targetName,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      periodStart: periodStart,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'period': period.name,
        'trigger_type': triggerType.name,
        'target_value': targetValue,
        'target_name': targetName,
        'progress': progress,
        'completed': completed ? 1 : 0,
        'period_start': periodStart.millisecondsSinceEpoch,
      };

  factory Mission.fromMap(Map<String, Object?> map) {
    return Mission(
      id: map['id'] as String,
      title: map['title'] as String,
      period: MissionPeriod.values.firstWhere((e) => e.name == map['period']),
      triggerType: MissionTriggerType.values
          .firstWhere((e) => e.name == map['trigger_type']),
      targetValue: map['target_value'] as int,
      targetName: map['target_name'] as String?,
      progress: map['progress'] as int? ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      periodStart:
          DateTime.fromMillisecondsSinceEpoch(map['period_start'] as int),
    );
  }
}
