import '../data/repositories/log_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../domain/models/achievement.dart';
import '../domain/models/user_stats.dart';

/// Reusable achievement engine: given current stats/logs, figures out which
/// achievements should newly unlock. Call `evaluate()` after every check-in.
class AchievementService {
  AchievementService({
    StatsRepository? statsRepo,
    LogRepository? logRepo,
  })  : _statsRepo = statsRepo ?? StatsRepository(),
        _logRepo = logRepo ?? LogRepository();

  final StatsRepository _statsRepo;
  final LogRepository _logRepo;

  /// Returns the list of achievements newly unlocked by this evaluation pass.
  Future<List<Achievement>> evaluate() async {
    final stats = await _statsRepo.getStats();
    final all = await _statsRepo.getAllAchievements();
    final newlyUnlocked = <Achievement>[];

    for (final a in all) {
      if (a.unlocked) continue;
      final met = await _isMet(a, stats);
      if (met) {
        await _statsRepo.unlockAchievement(a.id);
        newlyUnlocked.add(a.copyWith(unlocked: true, unlockedAt: DateTime.now()));
      }
    }
    return newlyUnlocked;
  }

  Future<bool> _isMet(Achievement a, UserStats stats) async {
    switch (a.triggerType) {
      case AchievementTriggerType.totalXp:
        return stats.totalXp >= a.targetValue;

      case AchievementTriggerType.totalCheckIns:
        return stats.totalCheckIns >= a.targetValue;

      case AchievementTriggerType.dailyStreak:
        return stats.currentStreakDays >= a.targetValue;

      case AchievementTriggerType.productivePoints:
        return stats.overallGoodPoints >= a.targetValue;

      case AchievementTriggerType.activityCount:
        if (a.targetActivityName == null) return false;
        final logs = await _logRepo.search(query: null);
        final count = logs
            .where((l) =>
                (l.customName ?? '').toLowerCase() ==
                a.targetActivityName!.toLowerCase())
            .length;
        return count >= a.targetValue;

      case AchievementTriggerType.abstinenceStreak:
        if (a.targetActivityName == null) return false;
        final since = DateTime.now().subtract(Duration(days: a.targetValue));
        final logs = await _logRepo.getInRange(since, DateTime.now());
        final hasActivity = logs.any((l) =>
            (l.customName ?? '').toLowerCase() ==
            a.targetActivityName!.toLowerCase());
        return !hasActivity;

      // --- Daily-record achievements: compare against the best day ever,
      // including today-in-progress so they can unlock the moment it happens. ---
      case AchievementTriggerType.bestDayXp:
        final best = stats.todayXp > stats.bestDayXp ? stats.todayXp : stats.bestDayXp;
        return best >= a.targetValue;

      case AchievementTriggerType.bestDayLevel:
        final best =
            stats.todayLevel > stats.bestDayLevel ? stats.todayLevel : stats.bestDayLevel;
        return best >= a.targetValue;

      case AchievementTriggerType.bestDayPoints:
        final best =
            stats.todayPoints > stats.bestDayPoints ? stats.todayPoints : stats.bestDayPoints;
        return best >= a.targetValue;
    }
  }
}
