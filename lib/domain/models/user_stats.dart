/// Aggregate, denormalized stats kept for fast dashboard reads.
/// Recomputed/updated incrementally by ScoringService & XpService.
class UserStats {
  final int todayPoints;
  final int overallPoints;
  final int todayGoodPoints;
  final int todayBadPoints;
  final int overallGoodPoints;
  final int overallBadPoints;
  final int totalCheckIns;
  final int totalXp;
  final int level;
  final int currentStreakDays; // daily check-in streak
  final int longestStreakDays;
  final DateTime? lastCheckInAt;
  final DateTime lastResetDate; // last date the "today" counters were reset

  const UserStats({
    this.todayPoints = 0,
    this.overallPoints = 0,
    this.todayGoodPoints = 0,
    this.todayBadPoints = 0,
    this.overallGoodPoints = 0,
    this.overallBadPoints = 0,
    this.totalCheckIns = 0,
    this.totalXp = 0,
    this.level = 1,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastCheckInAt,
    required this.lastResetDate,
  });

  UserStats copyWith({
    int? todayPoints,
    int? overallPoints,
    int? todayGoodPoints,
    int? todayBadPoints,
    int? overallGoodPoints,
    int? overallBadPoints,
    int? totalCheckIns,
    int? totalXp,
    int? level,
    int? currentStreakDays,
    int? longestStreakDays,
    DateTime? lastCheckInAt,
    DateTime? lastResetDate,
  }) {
    return UserStats(
      todayPoints: todayPoints ?? this.todayPoints,
      overallPoints: overallPoints ?? this.overallPoints,
      todayGoodPoints: todayGoodPoints ?? this.todayGoodPoints,
      todayBadPoints: todayBadPoints ?? this.todayBadPoints,
      overallGoodPoints: overallGoodPoints ?? this.overallGoodPoints,
      overallBadPoints: overallBadPoints ?? this.overallBadPoints,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  Map<String, Object?> toMap() => {
        'id': 1, // singleton row
        'today_points': todayPoints,
        'overall_points': overallPoints,
        'today_good_points': todayGoodPoints,
        'today_bad_points': todayBadPoints,
        'overall_good_points': overallGoodPoints,
        'overall_bad_points': overallBadPoints,
        'total_check_ins': totalCheckIns,
        'total_xp': totalXp,
        'level': level,
        'current_streak_days': currentStreakDays,
        'longest_streak_days': longestStreakDays,
        'last_check_in_at': lastCheckInAt?.millisecondsSinceEpoch,
        'last_reset_date': lastResetDate.millisecondsSinceEpoch,
      };

  factory UserStats.fromMap(Map<String, Object?> map) {
    return UserStats(
      todayPoints: map['today_points'] as int? ?? 0,
      overallPoints: map['overall_points'] as int? ?? 0,
      todayGoodPoints: map['today_good_points'] as int? ?? 0,
      todayBadPoints: map['today_bad_points'] as int? ?? 0,
      overallGoodPoints: map['overall_good_points'] as int? ?? 0,
      overallBadPoints: map['overall_bad_points'] as int? ?? 0,
      totalCheckIns: map['total_check_ins'] as int? ?? 0,
      totalXp: map['total_xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      currentStreakDays: map['current_streak_days'] as int? ?? 0,
      longestStreakDays: map['longest_streak_days'] as int? ?? 0,
      lastCheckInAt: map['last_check_in_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_check_in_at'] as int)
          : null,
      lastResetDate: map['last_reset_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_reset_date'] as int)
          : DateTime.now(),
    );
  }
}
