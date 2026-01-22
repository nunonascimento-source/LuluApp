import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/measurement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  // In-memory storage for web
  static final List<Map<String, dynamic>> _webStorage = [];
  static int _webAutoId = 0;
  static bool _webLoaded = false;

  DatabaseHelper._init();

  Future<void> _loadFromLocalStorage() async {
    if (_webLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('measurements');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      _webStorage.clear();
      _webStorage.addAll(decoded.cast<Map<String, dynamic>>());
      // Find max ID
      for (final item in _webStorage) {
        final id = item['id'] as int?;
        if (id != null && id > _webAutoId) {
          _webAutoId = id;
        }
      }
    }
    _webLoaded = true;
  }

  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_webStorage);
    await prefs.setString('measurements', encoded);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (!kIsWeb) {
      _database = await _initDB('measurements.db');
    }
    return _database ?? _createVirtualDb();
  }

  Database _createVirtualDb() {
    // Return a stub for web; we'll handle CRUD with _webStorage
    return _database ?? _DummyDatabase();
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        glicemia INTEGER NOT NULL,
        insulina REAL NOT NULL,
        observations TEXT
      )
    ''');
  }

  Future<int> insertMeasurement(Measurement m) async {
    if (kIsWeb) {
      await _loadFromLocalStorage();
      // On web, store in memory and localStorage
      final map = m.toMap();
      map['id'] = ++_webAutoId;
      _webStorage.add(map);
      await _saveToLocalStorage();
      return map['id'] as int;
    }
    final db = await instance.database;
    return await db.insert('measurements', m.toMap());
  }

  Future<int> updateMeasurement(Measurement m) async {
    if (m.id == null) return 0;
    if (kIsWeb) {
      await _loadFromLocalStorage();
      final idx = _webStorage.indexWhere((e) => e['id'] == m.id);
      if (idx == -1) return 0;
      _webStorage[idx] = m.toMap()..['id'] = m.id;
      await _saveToLocalStorage();
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'measurements',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> deleteMeasurement(int id) async {
    if (kIsWeb) {
      await _loadFromLocalStorage();
      final before = _webStorage.length;
      _webStorage.removeWhere((e) => e['id'] == id);
      await _saveToLocalStorage();
      return before - _webStorage.length;
    }
    final db = await instance.database;
    return await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Measurement>> getAllMeasurements() async {
    if (kIsWeb) {
      await _loadFromLocalStorage();
      // On web, return from memory
      final list = _webStorage.map((map) => Measurement.fromMap(map)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    }
    final db = await instance.database;
    final result = await db.query(
      'measurements',
      orderBy: 'date ASC, time ASC',
    );
    return result.map((map) => Measurement.fromMap(map)).toList();
  }

  Future close() async {
    if (!kIsWeb) {
      final db = await instance.database;
      db.close();
    }
  }
}

class _DummyDatabase implements Database {
  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
