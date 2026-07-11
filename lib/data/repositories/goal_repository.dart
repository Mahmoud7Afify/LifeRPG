import 'package:sqflite/sqflite.dart';
import '../../domain/models/goal.dart';
import '../database/db_helper.dart';

class GoalRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<Goal>> getAll({bool includeDisabled = true}) async {
    final db = await _db;
    final rows = await db.query(
      'goals',
      where: includeDisabled ? null : 'enabled = 1',
      orderBy: 'created_at DESC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<void> insert(Goal goal) async {
    final db = await _db;
    await db.insert('goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Goal goal) async {
    final db = await _db;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final db = await _db;
    await db.update('goals', {'enabled': enabled ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }
}
