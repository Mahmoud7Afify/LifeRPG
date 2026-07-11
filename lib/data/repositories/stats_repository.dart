import 'package:sqflite/sqflite.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/user_stats.dart';
import '../database/db_helper.dart';

class StatsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<UserStats> getStats() async {
    final db = await _db;
    final rows = await db.query('stats', where: 'id = 1');
    return UserStats.fromMap(rows.first);
  }

  Future<void> saveStats(UserStats stats) async {
    final db = await _db;
    await db.update('stats', stats.toMap(), where: 'id = 1');
  }

  // --- Achievements ---

  Future<List<Achievement>> getAllAchievements() async {
    final db = await _db;
    final rows = await db.query('achievements', orderBy: 'title ASC');
    return rows.map(Achievement.fromMap).toList();
  }

  Future<void> upsertAchievement(Achievement a) async {
    final db = await _db;
    await db.insert('achievements', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unlockAchievement(String id) async {
    final db = await _db;
    await db.update(
      'achievements',
      {'unlocked': 1, 'unlocked_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAchievement(String id) async {
    final db = await _db;
    await db.delete('achievements', where: 'id = ?', whereArgs: [id]);
  }

  // --- Missions ---

  Future<List<Mission>> getMissionsForPeriod(
      MissionPeriod period, DateTime periodStart) async {
    final db = await _db;
    final rows = await db.query(
      'missions',
      where: 'period = ? AND period_start = ?',
      whereArgs: [period.name, periodStart.millisecondsSinceEpoch],
    );
    return rows.map(Mission.fromMap).toList();
  }

  Future<void> upsertMission(Mission m) async {
    final db = await _db;
    await db.insert('missions', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
