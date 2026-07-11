import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/log_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_log.dart';
import '../../domain/models/attribute.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/user_stats.dart';
import '../../services/achievement_service.dart';
import '../../services/goal_service.dart';
import '../../services/notification_service.dart';
import '../../services/scoring_service.dart';
import '../../services/xp_service.dart';

// --- Repositories / Services (singletons) ---

final activityRepositoryProvider = Provider((ref) => ActivityRepository());
final logRepositoryProvider = Provider((ref) => LogRepository());
final statsRepositoryProvider = Provider((ref) => StatsRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
final goalRepositoryProvider = Provider((ref) => GoalRepository());

final xpServiceProvider = Provider((ref) => XpService());
final scoringServiceProvider = Provider((ref) => ScoringService());
final achievementServiceProvider = Provider((ref) => AchievementService());
final goalServiceProvider = Provider((ref) => GoalService());

// --- Activities ---

final activitiesProvider =
    AsyncNotifierProvider<ActivitiesNotifier, List<Activity>>(
        ActivitiesNotifier.new);

class ActivitiesNotifier extends AsyncNotifier<List<Activity>> {
  @override
  Future<List<Activity>> build() async {
    return ref.read(activityRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(activityRepositoryProvider).getAll());
  }

  Future<void> addActivity(Activity activity) async {
    await ref.read(activityRepositoryProvider).insert(activity);
    await refresh();
  }

  Future<void> updateActivity(Activity activity) async {
    await ref.read(activityRepositoryProvider).update(activity);
    await refresh();
  }

  Future<void> deleteActivity(String id) async {
    await ref.read(activityRepositoryProvider).delete(id);
    await refresh();
  }

  Future<void> archiveActivity(String id, bool archived) async {
    await ref.read(activityRepositoryProvider).setArchived(id, archived);
    await refresh();
  }

  Future<void> reorder(List<String> orderedIds) async {
    await ref.read(activityRepositoryProvider).reorder(orderedIds);
    await refresh();
  }
}

// --- Character attributes ("Character States") ---

final attributesProvider =
    AsyncNotifierProvider<AttributesNotifier, List<CharacterAttribute>>(
        AttributesNotifier.new);

class AttributesNotifier extends AsyncNotifier<List<CharacterAttribute>> {
  @override
  Future<List<CharacterAttribute>> build() async {
    return ref.read(activityRepositoryProvider).getAllAttributes();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(activityRepositoryProvider).getAllAttributes());
  }

  Future<void> addAttribute(String name, {int? maxValue}) async {
    final repo = ref.read(activityRepositoryProvider);
    final defaultMax = maxValue ??
        await ref.read(settingsRepositoryProvider).getDefaultAttributeMax();
    await repo.addAttribute(CharacterAttribute(
      id: const Uuid().v4(),
      name: name,
      maxValue: defaultMax,
    ));
    await refresh();
  }

  Future<void> updateAttribute(CharacterAttribute attribute) async {
    await ref.read(activityRepositoryProvider).updateAttribute(attribute);
    await refresh();
  }

  Future<void> deleteAttribute(String id) async {
    await ref.read(activityRepositoryProvider).deleteAttribute(id);
    await refresh();
  }
}

// --- Stats (dashboard) ---

final statsProvider = AsyncNotifierProvider<StatsNotifier, UserStats>(StatsNotifier.new);

class StatsNotifier extends AsyncNotifier<UserStats> {
  @override
  Future<UserStats> build() async {
    return ref.read(statsRepositoryProvider).getStats();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(statsRepositoryProvider).getStats());
  }
}

// --- Logs / History ---

final recentLogsProvider = FutureProvider.autoDispose<List<ActivityLog>>((ref) async {
  return ref.read(logRepositoryProvider).getAll(limit: 200);
});

// --- Achievements ---

final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  return ref.read(statsRepositoryProvider).getAllAchievements();
});

// --- Goals ---

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    return ref.read(goalRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(goalRepositoryProvider).getAll());
  }

  Future<void> addGoal(Goal goal) async {
    await ref.read(goalRepositoryProvider).insert(goal);
    await refresh();
    ref.invalidate(goalProgressProvider);
  }

  Future<void> updateGoal(Goal goal) async {
    await ref.read(goalRepositoryProvider).update(goal);
    await refresh();
    ref.invalidate(goalProgressProvider);
  }

  Future<void> deleteGoal(String id) async {
    await ref.read(goalRepositoryProvider).delete(id);
    await refresh();
    ref.invalidate(goalProgressProvider);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await ref.read(goalRepositoryProvider).setEnabled(id, enabled);
    await refresh();
    ref.invalidate(goalProgressProvider);
  }
}

/// Today's live progress for every enabled goal.
final goalProgressProvider = FutureProvider.autoDispose<List<GoalProgress>>((ref) async {
  ref.watch(goalsProvider);
  return ref.read(goalServiceProvider).getTodayProgress();
});

// --- Settings ---

final checkInIntervalProvider =
    AsyncNotifierProvider<CheckInIntervalNotifier, int>(CheckInIntervalNotifier.new);

class CheckInIntervalNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.read(settingsRepositoryProvider).getIntervalMinutes();

  Future<void> setInterval(int minutes) async {
    await ref.read(settingsRepositoryProvider).setIntervalMinutes(minutes);
    state = AsyncData(minutes);
    await NotificationService.instance.scheduleNext(minutes);
  }
}

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(settingsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final current = state.value ?? false;
    final next = !current;
    await ref.read(settingsRepositoryProvider).setDarkMode(next);
    state = AsyncData(next);
  }
}

/// The default "out of" max value applied to newly created character states.
final defaultAttributeMaxProvider =
    AsyncNotifierProvider<DefaultAttributeMaxNotifier, int>(
        DefaultAttributeMaxNotifier.new);

class DefaultAttributeMaxNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() =>
      ref.read(settingsRepositoryProvider).getDefaultAttributeMax();

  Future<void> setValue(int value) async {
    await ref.read(settingsRepositoryProvider).setDefaultAttributeMax(value);
    state = AsyncData(value);
  }
}

/// Convenience notifier that performs a full check-in and refreshes all
/// dependent providers (stats, attributes, achievements, goals) in one call.
final checkInActionProvider = Provider((ref) => CheckInAction(ref));

class CheckInAction {
  CheckInAction(this._ref);
  final Ref _ref;

  Future<List<Achievement>> submitForActivity(String activityId, {String? notes}) async {
    await _ref.read(scoringServiceProvider).recordCheckIn(
          activityId: activityId,
          notes: notes,
        );
    return _afterCheckIn();
  }

  Future<List<Achievement>> submitCustom({
    required String name,
    required int score,
    required dynamic type, // ActivityType, kept dynamic to avoid import cycle
    String? notes,
  }) async {
    await _ref.read(scoringServiceProvider).recordCustomCheckIn(
          name: name,
          score: score,
          type: type,
          notes: notes,
        );
    return _afterCheckIn();
  }

  Future<List<Achievement>> _afterCheckIn() async {
    final unlocked = await _ref.read(achievementServiceProvider).evaluate();
    await _ref.read(statsProvider.notifier).refresh();
    await _ref.read(attributesProvider.notifier).refresh();
    _ref.invalidate(recentLogsProvider);
    _ref.invalidate(achievementsProvider);
    _ref.invalidate(goalProgressProvider);
    return unlocked;
  }
}
