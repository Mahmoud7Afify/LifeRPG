import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../domain/models/achievement.dart';
import '../domain/models/activity.dart';
import '../domain/models/attribute.dart';

/// Populates first-run default data: attributes, example activities with
/// attribute mappings, and a starter set of achievements.
/// Idempotent-ish: only seeds if the activities table is empty.
class SeedDataService {
  SeedDataService({
    ActivityRepository? activityRepo,
    StatsRepository? statsRepo,
  })  : _activityRepo = activityRepo ?? ActivityRepository(),
        _statsRepo = statsRepo ?? StatsRepository();

  final ActivityRepository _activityRepo;
  final StatsRepository _statsRepo;
  static const _uuid = Uuid();

  Future<void> seedIfEmpty() async {
    final existing = await _activityRepo.getAll(includeArchived: true);
    if (existing.isNotEmpty) return;

    // 1. Attributes
    final attrIds = <String, String>{};
    for (final name in AppConstants.defaultAttributes) {
      final id = _uuid.v4();
      attrIds[name] = id;
      await _activityRepo.upsertAttribute(CharacterAttribute(id: id, name: name));
    }

    // 2. Activities + attribute mappings
    final specs = <_ActivitySpec>[
      _ActivitySpec('Study', 6, 'Learning', ActivityType.good, 0xFF3F51B5,
          'school', {'Knowledge': 4, 'Discipline': 2}),
      _ActivitySpec('Programming', 7, 'Work', ActivityType.good, 0xFF00897B,
          'code', {'Career': 4, 'Knowledge': 2, 'Discipline': 1}),
      _ActivitySpec('Workout', 6, 'Health', ActivityType.good, 0xFFE53935,
          'fitness_center', {'Health': 5, 'Discipline': 2}),
      _ActivitySpec('Quran', 6, 'Spirituality', ActivityType.good, 0xFF43A047,
          'menu_book', {'Spirituality': 5, 'Discipline': 2}),
      _ActivitySpec('Reading', 5, 'Learning', ActivityType.good, 0xFF6D4C41,
          'auto_stories', {'Knowledge': 3, 'Creativity': 1}),
      _ActivitySpec('Family Time', 4, 'Social', ActivityType.good, 0xFFFB8C00,
          'family_restroom', {'Social': 4}),
      _ActivitySpec('Social Media', -3, 'Leisure', ActivityType.bad,
          0xFF9E9E9E, 'smartphone', {'Discipline': -2, 'Knowledge': -1}),
      _ActivitySpec('Gaming', -1, 'Leisure', ActivityType.neutral, 0xFF8E24AA,
          'sports_esports', {'Creativity': 1, 'Discipline': -1}),
      _ActivitySpec('Sleeping', 2, 'Rest', ActivityType.neutral, 0xFF3949AB,
          'bedtime', {'Health': 2}),
    ];

    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final id = _uuid.v4();
      await _activityRepo.insert(Activity(
        id: id,
        name: s.name,
        score: s.score,
        category: s.category,
        type: s.type,
        color: s.color,
        icon: s.icon,
        sortOrder: i,
      ));
      final mappings = s.attrPoints.entries
          .map((e) => ActivityAttributeMapping(
                activityId: id,
                attributeId: attrIds[e.key]!,
                points: e.value,
              ))
          .toList();
      await _activityRepo.setMappingsForActivity(id, mappings);
    }

    // 3. Achievements
    final achievements = <Achievement>[
      Achievement(
        id: _uuid.v4(),
        title: 'First Check-In',
        description: 'Log your very first activity.',
        icon: 'flag',
        triggerType: AchievementTriggerType.totalCheckIns,
        targetValue: 1,
      ),
      Achievement(
        id: _uuid.v4(),
        title: '100 XP',
        description: 'Earn a total of 100 XP.',
        icon: 'bolt',
        triggerType: AchievementTriggerType.totalXp,
        targetValue: 100,
      ),
      Achievement(
        id: _uuid.v4(),
        title: '1000 XP',
        description: 'Earn a total of 1000 XP.',
        icon: 'bolt',
        triggerType: AchievementTriggerType.totalXp,
        targetValue: 1000,
      ),
      Achievement(
        id: _uuid.v4(),
        title: '100 Study Sessions',
        description: 'Log 100 Study check-ins.',
        icon: 'school',
        triggerType: AchievementTriggerType.activityCount,
        targetValue: 100,
        targetActivityName: 'Study',
      ),
      Achievement(
        id: _uuid.v4(),
        title: '7-Day Streak',
        description: 'Check in every day for 7 days straight.',
        icon: 'local_fire_department',
        triggerType: AchievementTriggerType.dailyStreak,
        targetValue: 7,
      ),
      Achievement(
        id: _uuid.v4(),
        title: '30-Day Streak',
        description: 'Check in every day for 30 days straight.',
        icon: 'local_fire_department',
        triggerType: AchievementTriggerType.dailyStreak,
        targetValue: 30,
      ),
      Achievement(
        id: _uuid.v4(),
        title: '1000 Productive Points',
        description: 'Accumulate 1000 total good-activity points.',
        icon: 'trending_up',
        triggerType: AchievementTriggerType.productivePoints,
        targetValue: 1000,
      ),
      Achievement(
        id: _uuid.v4(),
        title: 'No Social Media for 7 Days',
        description: 'Avoid logging Social Media for a full week.',
        icon: 'phonelink_erase',
        triggerType: AchievementTriggerType.abstinenceStreak,
        targetValue: 7,
        targetActivityName: 'Social Media',
      ),
    ];
    for (final a in achievements) {
      await _statsRepo.upsertAchievement(a);
    }
  }
}

class _ActivitySpec {
  final String name;
  final int score;
  final String category;
  final ActivityType type;
  final int color;
  final String icon;
  final Map<String, int> attrPoints;

  _ActivitySpec(this.name, this.score, this.category, this.type, this.color,
      this.icon, this.attrPoints);
}
