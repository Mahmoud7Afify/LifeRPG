import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite schema + connection owner.
///
/// Tables:
///   activities                  - user-defined trackable activities
///   activity_logs               - every check-in record
///   stats                       - singleton aggregate row (id = 1)
///   attributes                  - character attributes (Knowledge, Health, ...)
///   activity_attribute_mappings - activity -> attribute point contributions
///   achievements                - achievement definitions + unlock state
///   goals                       - user-defined daily goals (progress computed live)
///   missions                    - daily/weekly mission instances (legacy, unused by UI)
///   settings                    - key/value simple settings (backup of SharedPreferences)
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;
  static const int _schemaVersion = 2;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_rpg.db');
    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        score INTEGER NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL,
        activity_id TEXT,
        custom_name TEXT,
        score INTEGER NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_logs_timestamp ON activity_logs (timestamp)');
    await db.execute(
        'CREATE INDEX idx_logs_activity ON activity_logs (activity_id)');

    await db.execute('''
      CREATE TABLE stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        today_points INTEGER NOT NULL DEFAULT 0,
        overall_points INTEGER NOT NULL DEFAULT 0,
        today_good_points INTEGER NOT NULL DEFAULT 0,
        today_bad_points INTEGER NOT NULL DEFAULT 0,
        overall_good_points INTEGER NOT NULL DEFAULT 0,
        overall_bad_points INTEGER NOT NULL DEFAULT 0,
        total_check_ins INTEGER NOT NULL DEFAULT 0,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        today_xp INTEGER NOT NULL DEFAULT 0,
        today_level INTEGER NOT NULL DEFAULT 1,
        best_day_xp INTEGER NOT NULL DEFAULT 0,
        best_day_level INTEGER NOT NULL DEFAULT 1,
        best_day_points INTEGER NOT NULL DEFAULT 0,
        best_day_date INTEGER,
        current_streak_days INTEGER NOT NULL DEFAULT 0,
        longest_streak_days INTEGER NOT NULL DEFAULT 0,
        last_check_in_at INTEGER,
        last_reset_date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attributes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        total_points INTEGER NOT NULL DEFAULT 0,
        today_points INTEGER NOT NULL DEFAULT 0,
        max_value INTEGER NOT NULL DEFAULT 100
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_attribute_mappings (
        activity_id TEXT NOT NULL,
        attribute_id TEXT NOT NULL,
        points INTEGER NOT NULL,
        PRIMARY KEY (activity_id, attribute_id),
        FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE,
        FOREIGN KEY (attribute_id) REFERENCES attributes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        trigger_type TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        target_activity_name TEXT,
        unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        target_activity_id TEXT,
        target_value INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE missions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        period TEXT NOT NULL,
        trigger_type TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        target_name TEXT,
        progress INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        period_start INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Singleton stats row
    await db.insert('stats', {
      'id': 1,
      'today_points': 0,
      'overall_points': 0,
      'today_good_points': 0,
      'today_bad_points': 0,
      'overall_good_points': 0,
      'overall_bad_points': 0,
      'total_check_ins': 0,
      'total_xp': 0,
      'level': 1,
      'today_xp': 0,
      'today_level': 1,
      'best_day_xp': 0,
      'best_day_level': 1,
      'best_day_points': 0,
      'best_day_date': null,
      'current_streak_days': 0,
      'longest_streak_days': 0,
      'last_check_in_at': null,
      'last_reset_date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE attributes ADD COLUMN max_value INTEGER NOT NULL DEFAULT 100');
      await db.execute(
          'ALTER TABLE stats ADD COLUMN today_xp INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE stats ADD COLUMN today_level INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          'ALTER TABLE stats ADD COLUMN best_day_xp INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE stats ADD COLUMN best_day_level INTEGER NOT NULL DEFAULT 1');
      await db.execute(
          'ALTER TABLE stats ADD COLUMN best_day_points INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE stats ADD COLUMN best_day_date INTEGER');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          target_activity_id TEXT,
          target_value INTEGER NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }

  /// Wipes all user data but keeps schema (used by Settings > Reset Statistics).
  Future<void> resetAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('activity_logs');
      await txn.delete('missions');
      await txn.update('achievements', {'unlocked': 0, 'unlocked_at': null});
      await txn.update('attributes', {'total_points': 0, 'today_points': 0});
      await txn.update('stats', {
        'today_points': 0,
        'overall_points': 0,
        'today_good_points': 0,
        'today_bad_points': 0,
        'overall_good_points': 0,
        'overall_bad_points': 0,
        'total_check_ins': 0,
        'total_xp': 0,
        'level': 1,
        'today_xp': 0,
        'today_level': 1,
        'best_day_xp': 0,
        'best_day_level': 1,
        'best_day_points': 0,
        'best_day_date': null,
        'current_streak_days': 0,
        'longest_streak_days': 0,
        'last_check_in_at': null,
        'last_reset_date': DateTime.now().millisecondsSinceEpoch,
      }, where: 'id = 1');
    });
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
