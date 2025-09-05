import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'plan_do.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        colorTag TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isFromExternal INTEGER NOT NULL DEFAULT 0,
        externalId TEXT,
        score INTEGER,
        doRecord TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // score와 doRecord 컬럼 추가
      await db.execute('ALTER TABLE tasks ADD COLUMN score INTEGER');
      await db.execute('ALTER TABLE tasks ADD COLUMN doRecord TEXT');
    }
  }

  // Task CRUD operations
  Future<int> insertTask(Task task) async {
    final db = await database;
    print('DatabaseService: Inserting task ${task.title}');
    final result = await db.insert('tasks', task.toJson());
    print('DatabaseService: Task inserted with ID: $result');
    return result;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    print('DatabaseService: Retrieved ${maps.length} tasks from database');
    return List.generate(maps.length, (i) => Task.fromJson(maps[i]));
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'startTime ASC',
    );
    
    return List.generate(maps.length, (i) => Task.fromJson(maps[i]));
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // 데이터베이스 연결 테스트
  Future<bool> testConnection() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // 데이터베이스 초기화 (개발/테스트용)
  Future<void> resetDatabase() async {
    try {
      final db = await database;
      await db.delete('tasks');
      await db.delete('settings');
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
    }
  }

  // 데이터베이스 상태 확인
  Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final db = await database;
      
      // 테이블 존재 확인
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('tasks', 'settings')"
      );
      
      // 작업 수 확인
      final taskCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks')) ?? 0;
      
      // 설정 수 확인
      final settingCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM settings')) ?? 0;
      
      return {
        'isConnected': true,
        'tablesExist': tables.length == 2,
        'taskCount': taskCount,
        'settingCount': settingCount,
        'tables': tables.map((table) => table['name']).toList(),
      };
    } catch (e) {
      return {
        'isConnected': false,
        'error': e.toString(),
        'tablesExist': false,
        'taskCount': 0,
        'settingCount': 0,
        'tables': <String>[],
      };
    }
  }
}

