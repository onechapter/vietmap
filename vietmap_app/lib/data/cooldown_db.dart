import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../core/logger.dart';

/// Database for storing cooldown state
class CooldownDb {
  static CooldownDb? _instance;
  Database? _db;

  CooldownDb._();

  static CooldownDb get instance {
    _instance ??= CooldownDb._();
    return _instance!;
  }

  Future<void> init() async {
    if (_db != null) return;

    try {
      final dbPath = await getDatabasesPath();
      final dbFile = path.join(dbPath, 'cooldowns.db');
      _db = await openDatabase(
        dbFile,
        version: 1,
        onCreate: (db, version) {
          db.execute('''
            CREATE TABLE cooldowns (
              id TEXT,
              type TEXT,
              last_fired INTEGER,
              PRIMARY KEY (id, type)
            )
          ''');
        },
      );
      appLog('CooldownDb initialized');
    } catch (e) {
      appLog('CooldownDb init failed: $e');
    }
  }

  Future<bool> isInCooldown(String id, String type, Duration cooldown) async {
    if (_db == null) await init();
    if (_db == null) return false;

    try {
      final result = await _db!.query(
        'cooldowns',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );

      if (result.isEmpty) return false;

      final lastFired = result[0]['last_fired'] as int?;
      if (lastFired == null) return false;

      final lastFiredTime = DateTime.fromMillisecondsSinceEpoch(lastFired);
      final now = DateTime.now();
      return now.difference(lastFiredTime) < cooldown;
    } catch (e) {
      appLog('CooldownDb query failed: $e');
      return false;
    }
  }

  Future<void> setCooldown(String id, String type) async {
    if (_db == null) await init();
    if (_db == null) return;

    try {
      await _db!.insert(
        'cooldowns',
        {
          'id': id,
          'type': type,
          'last_fired': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      appLog('CooldownDb insert failed: $e');
    }
  }

  Future<void> clear() async {
    if (_db == null) await init();
    if (_db == null) return;

    try {
      await _db!.delete('cooldowns');
    } catch (e) {
      appLog('CooldownDb clear failed: $e');
    }
  }
}

