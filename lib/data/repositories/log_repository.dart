import 'package:sqflite/sqflite.dart';
import '../../domain/models/activity_log.dart';
import '../database/db_helper.dart';

class LogRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<void> insert(ActivityLog log) async {
    final db = await _db;
    await db.insert('activity_logs', log.toMap());
  }

  Future<void> update(ActivityLog log) async {
    final db = await _db;
    await db.update('activity_logs', log.toMap(),
        where: 'id = ?', whereArgs: [log.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('activity_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivityLog>> getAll({int? limit, int? offset}) async {
    final db = await _db;
    final rows = await db.query(
      'activity_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<List<ActivityLog>> getInRange(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.query(
      'activity_logs',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<List<ActivityLog>> search({
    String? query,
    String? activityId,
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(custom_name LIKE ? OR notes LIKE ?)');
      args.add('%$query%');
      args.add('%$query%');
    }
    if (activityId != null) {
      where.add('activity_id = ?');
      args.add(activityId);
    }
    if (start != null) {
      where.add('timestamp >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      where.add('timestamp <= ?');
      args.add(end.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'activity_logs',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'timestamp DESC',
    );
    return rows.map(ActivityLog.fromMap).toList();
  }

  /// Count of check-ins for a given activityId within [start, end].
  Future<int> countForActivity(String activityId,
      {DateTime? start, DateTime? end}) async {
    final db = await _db;
    final where = <String>['activity_id = ?'];
    final args = <Object?>[activityId];
    if (start != null) {
      where.add('timestamp >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      where.add('timestamp <= ?');
      args.add(end.millisecondsSinceEpoch);
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM activity_logs WHERE ${where.join(' AND ')}',
      args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Per-activity point totals within a range, keyed by activityId (or custom_name for ad-hoc).
  Future<Map<String, int>> pointsByActivity(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT COALESCE(activity_id, custom_name) as key_id, SUM(score) as total
      FROM activity_logs
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY key_id
    ''', [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    final map = <String, int>{};
    for (final r in rows) {
      final key = r['key_id'] as String?;
      if (key != null) map[key] = (r['total'] as int?) ?? 0;
    }
    return map;
  }
}
