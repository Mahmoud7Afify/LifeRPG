import 'package:sqflite/sqflite.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/attribute.dart';
import '../database/db_helper.dart';

class ActivityRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<Activity>> getAll({bool includeArchived = false}) async {
    final db = await _db;
    final rows = await db.query(
      'activities',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(Activity.fromMap).toList();
  }

  Future<Activity?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('activities', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Activity.fromMap(rows.first);
  }

  Future<void> insert(Activity activity) async {
    final db = await _db;
    await db.insert('activities', activity.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Activity activity) async {
    final db = await _db;
    await db.update('activities', activity.toMap(),
        where: 'id = ?', whereArgs: [activity.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setArchived(String id, bool archived) async {
    final db = await _db;
    await db.update('activities', {'archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<String> orderedIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update('activities', {'sort_order': i},
            where: 'id = ?', whereArgs: [orderedIds[i]]);
      }
    });
  }

  // --- Attribute mappings ---

  Future<List<CharacterAttribute>> getAllAttributes() async {
    final db = await _db;
    final rows = await db.query('attributes', orderBy: 'name ASC');
    return rows.map(CharacterAttribute.fromMap).toList();
  }

  Future<void> upsertAttribute(CharacterAttribute attr) async {
    final db = await _db;
    await db.insert('attributes', attr.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ActivityAttributeMapping>> getMappingsForActivity(
      String activityId) async {
    final db = await _db;
    final rows = await db.query('activity_attribute_mappings',
        where: 'activity_id = ?', whereArgs: [activityId]);
    return rows.map(ActivityAttributeMapping.fromMap).toList();
  }

  Future<void> setMappingsForActivity(
      String activityId, List<ActivityAttributeMapping> mappings) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('activity_attribute_mappings',
          where: 'activity_id = ?', whereArgs: [activityId]);
      for (final m in mappings) {
        await txn.insert('activity_attribute_mappings', m.toMap());
      }
    });
  }

  Future<void> bumpAttributePoints(
      String attributeId, int deltaPoints) async {
    final db = await _db;
    await db.rawUpdate('''
      UPDATE attributes
      SET total_points = total_points + ?, today_points = today_points + ?
      WHERE id = ?
    ''', [deltaPoints, deltaPoints, attributeId]);
  }

  Future<void> resetTodayAttributePoints() async {
    final db = await _db;
    await db.update('attributes', {'today_points': 0});
  }
}
