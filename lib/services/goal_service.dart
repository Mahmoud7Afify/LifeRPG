import '../core/constants.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../domain/models/goal.dart';

/// Computes today's live progress for each goal. Goals are always "for
/// today" — nothing about progress is persisted, so it's automatically
/// correct after a day rolls over.
class GoalService {
  GoalService({
    GoalRepository? goalRepo,
    LogRepository? logRepo,
    StatsRepository? statsRepo,
  })  : _goalRepo = goalRepo ?? GoalRepository(),
        _logRepo = logRepo ?? LogRepository(),
        _statsRepo = statsRepo ?? StatsRepository();

  final GoalRepository _goalRepo;
  final LogRepository _logRepo;
  final StatsRepository _statsRepo;

  Future<List<GoalProgress>> getTodayProgress() async {
    final goals = await _goalRepo.getAll(includeDisabled: false);
    if (goals.isEmpty) return [];

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final todayLogs = await _logRepo.getInRange(startOfDay, now);
    final stats = await _statsRepo.getStats();

    return goals.map((g) {
      int progress;
      switch (g.type) {
        case GoalType.activity:
          progress = todayLogs
              .where((l) => l.activityId == g.targetActivityId)
              .length;
          break;
        case GoalType.goodActivities:
          progress =
              todayLogs.where((l) => l.type == ActivityType.good).length;
          break;
        case GoalType.xpPoints:
          progress = stats.todayXp;
          break;
      }
      return GoalProgress(goal: g, progress: progress);
    }).toList();
  }
}
