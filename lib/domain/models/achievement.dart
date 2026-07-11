enum AchievementTriggerType {
  // --- Overall (lifetime) achievements ---
  totalXp,
  totalCheckIns,
  activityCount, // count of check-ins for a specific activity name/category
  dailyStreak,
  productivePoints,
  abstinenceStreak, // e.g. "No Social Media for N days"

  // --- Daily-record achievements: unlock once ANY single day ever hits target ---
  bestDayXp,
  bestDayLevel,
  bestDayPoints,
}

extension AchievementTriggerTypeX on AchievementTriggerType {
  /// Daily-record trigger types are evaluated against the best-ever single
  /// day's XP/level/points rather than lifetime totals.
  bool get isDaily {
    switch (this) {
      case AchievementTriggerType.bestDayXp:
      case AchievementTriggerType.bestDayLevel:
      case AchievementTriggerType.bestDayPoints:
        return true;
      default:
        return false;
    }
  }
}

/// A single achievement definition + its unlocked state.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementTriggerType triggerType;
  final int targetValue;
  final String? targetActivityName; // for activityCount / abstinenceStreak
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.triggerType,
    required this.targetValue,
    this.targetActivityName,
    this.unlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? unlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      triggerType: triggerType,
      targetValue: targetValue,
      targetActivityName: targetActivityName,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'trigger_type': triggerType.name,
        'target_value': targetValue,
        'target_activity_name': targetActivityName,
        'unlocked': unlocked ? 1 : 0,
        'unlocked_at': unlockedAt?.millisecondsSinceEpoch,
      };

  factory Achievement.fromMap(Map<String, Object?> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      triggerType: AchievementTriggerType.values.firstWhere(
        (e) => e.name == map['trigger_type'],
      ),
      targetValue: map['target_value'] as int,
      targetActivityName: map['target_activity_name'] as String?,
      unlocked: (map['unlocked'] as int) == 1,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int)
          : null,
    );
  }
}
