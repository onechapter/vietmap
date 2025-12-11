import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/logger.dart';
import 'camera_model.dart';

class CameraCache {
  static const _dbName = 'camera_cache.db';
  static const _table = 'camera_cache';
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id TEXT PRIMARY KEY,
            name TEXT,
            lat REAL,
            lng REAL,
            type TEXT,
            speedLimit INTEGER
          );
        ''');
      },
      onOpen: (db) async {
        final info = await db.rawQuery('PRAGMA table_info($_table);');
        final hasSpeed = info.any((c) => (c['name'] as String) == 'speedLimit');
        if (!hasSpeed) {
          await db.execute('ALTER TABLE $_table ADD COLUMN speedLimit INTEGER;');
          appLog('Camera cache ALTER TABLE add speedLimit');
        }
      },
    );
    appLog('Camera cache initialized at $_dbName');
  }

  Future<void> clear() async {
    final db = _db;
    if (db == null) return;
    await db.delete(_table);
    appLog('Camera cache cleared');
  }

  Future<void> saveAll(List<CameraModel> cams) async {
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    for (final cam in cams) {
      batch.insert(
        _table,
        cam.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    appLog('Camera cache saved ${cams.length} items');
  }

  Future<List<CameraModel>> getAll() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(_table);
    final result = rows
        .map(
          (e) => CameraModel(
            id: e['id'] as String,
            name: e['name'] as String,
            lat: (e['lat'] as num).toDouble(),
            lng: (e['lng'] as num).toDouble(),
            type: e['type'] as String? ?? '',
            speedLimit: e['speedLimit'] as int?,
          ),
        )
        .toList();
    appLog('Camera cache loaded ${result.length} items');
    return result;
  }
}

