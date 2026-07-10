import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../domain/models/activity_log.dart';
import '../domain/models/user_stats.dart';
import 'xp_service.dart';

/// Orchestrates everything that must happen when the user completes a
/// check-in: writing the log, updating aggregate stats, awarding XP/levels,
/// bumping attribute points, and rolling the daily streak forward.
class ScoringService {
  ScoringService({
    ActivityRepository? activityRepo,
    LogRepository? logRepo,
    StatsRepository? statsRepo,
    XpService? xpService,
  })  : _activityRepo = activityRepo ?? ActivityRepository(),
        _logRepo = logRepo ?? LogRepository(),
        _statsRepo = statsRepo ?? StatsRepository(),
        _xpService = xpService ?? XpService();

  final ActivityRepository _activityRepo;
  final LogRepository _logRepo;
  final StatsRepository _statsRepo;
  final XpService _xpService;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Records a check-in for a saved activity (by id).
  Future<XpResult> recordCheckIn({
    required String activityId,
    String? notes,
  }) async {
    final activity = await _activityRepo.getById(activityId);
    if (activity == null) {
      throw ArgumentError('Activity $activityId not found');
    }
    return _applyLog(
      ActivityLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        activityId: activity.id,
        score: activity.score,
        type: activity.type,
        notes: notes,
      ),
      attributeSourceActivityId: activity.id,
    );
  }

  /// Records a fully custom ("Other") check-in. If [saveAsPermanent] and
  /// [activityToCreate] are provided, the activity is also persisted for reuse.
  Future<XpResult> recordCustomCheckIn({
    required String name,
    required int score,
    required ActivityType type,
    String? notes,
  }) async {
    return _applyLog(
      ActivityLog(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        customName: name,
        score: score,
        type: type,
        notes: notes,
      ),
    );
  }

  Future<XpResult> _applyLog(
    ActivityLog log, {
    String? attributeSourceActivityId,
  }) async {
    await _logRepo.insert(log);

    var stats = await _statsRepo.getStats();
    final now = log.timestamp;

    // Roll "today" counters if the day has changed since last reset.
    if (!_isSameDay(stats.lastResetDate, now)) {
      final wasYesterday = _isSameDay(
        stats.lastResetDate,
        now.subtract(const Duration(days: 1)),
      );
      stats = stats.copyWith(
        todayPoints: 0,
        todayGoodPoints: 0,
        todayBadPoints: 0,
        lastResetDate: now,
        // Streak continues only if the previous "today" was literally yesterday.
        currentStreakDays: wasYesterday ? stats.currentStreakDays : 0,
      );
      await _activityRepo.resetTodayAttributePoints();
    }

    final isNewDayCheckIn = stats.lastCheckInAt == null ||
        !_isSameDay(stats.lastCheckInAt!, now);

    final newStreak =
        isNewDayCheckIn ? stats.currentStreakDays + 1 : stats.currentStreakDays;

    final xpGain = _xpService.xpForCheckIn(score: log.score, type: log.type);
    final xpResult = _xpService.applyXpGain(stats.totalXp, xpGain);

    final updated = stats.copyWith(
      todayPoints: stats.todayPoints + log.score,
      overallPoints: stats.overallPoints + log.score,
      todayGoodPoints: log.type == ActivityType.good
          ? stats.todayGoodPoints + log.score
          : stats.todayGoodPoints,
      todayBadPoints: log.type == ActivityType.bad
          ? stats.todayBadPoints + log.score.abs()
          : stats.todayBadPoints,
      overallGoodPoints: log.type == ActivityType.good
          ? stats.overallGoodPoints + log.score
          : stats.overallGoodPoints,
      overallBadPoints: log.type == ActivityType.bad
          ? stats.overallBadPoints + log.score.abs()
          : stats.overallBadPoints,
      totalCheckIns: stats.totalCheckIns + 1,
      totalXp: xpResult.totalXp,
      level: xpResult.level,
      currentStreakDays: newStreak,
      longestStreakDays:
          newStreak > stats.longestStreakDays ? newStreak : stats.longestStreakDays,
      lastCheckInAt: now,
    );

    await _statsRepo.saveStats(updated);

    // Bump attribute points if this log maps back to a saved activity.
    if (attributeSourceActivityId != null) {
      final mappings =
          await _activityRepo.getMappingsForActivity(attributeSourceActivityId);
      for (final m in mappings) {
        await _activityRepo.bumpAttributePoints(m.attributeId, m.points);
      }
    }

    return xpResult;
  }

  Future<UserStats> currentStats() => _statsRepo.getStats();
}
