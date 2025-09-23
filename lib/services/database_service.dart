import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/daily_plan.dart';
import '../models/review.dart';
import '../models/hierarchy.dart';
import '../models/settings.dart';
import '../models/pds_plan.dart';
import '../utils/helpers.dart';

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
    String path = join(await getDatabasesPath(), 'productivity_app.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Items table
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        type TEXT CHECK (type IN ('goal', 'project', 'task', 'note', 'area', 'resource')) NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        status TEXT CHECK (status IN ('inbox', 'clarified', 'active', 'completed', 'archived', 'someday', 'waiting')) DEFAULT 'inbox',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        due_date DATETIME,
        reminder_date DATETIME,
        estimated_duration INTEGER,
        actual_duration INTEGER,
        priority INTEGER CHECK (priority BETWEEN 1 AND 5) DEFAULT 3,
        energy_level TEXT CHECK (energy_level IN ('high', 'medium', 'low')),
        context TEXT CHECK (context IN ('home', 'office', 'computer', 'errands', 'calls', 'anywhere')),
        delegated_to TEXT,
        waiting_for TEXT,
        completion_date DATETIME
      )
    ''');

    // Hierarchy table
    await db.execute('''
      CREATE TABLE hierarchy (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        child_id TEXT NOT NULL,
        relationship_type TEXT CHECK (relationship_type IN ('areaGoal', 'goalProject', 'projectTask', 'areaNote', 'resourceNote')) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY (child_id) REFERENCES items(id) ON DELETE CASCADE
      )
    ''');

    // Daily plans table
    await db.execute('''
      CREATE TABLE daily_plans (
        id TEXT PRIMARY KEY,
        date DATE NOT NULL UNIQUE,
        plan_morning TEXT,
        plan_afternoon TEXT,
        plan_evening TEXT,
        actual_items TEXT,
        see_notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        review_date DATE NOT NULL,
        type TEXT CHECK (type IN ('daily', 'weekly', 'monthly')) NOT NULL,
        empty_inbox_completed BOOLEAN DEFAULT 0,
        clarify_completed BOOLEAN DEFAULT 0,
        mind_sweep_completed BOOLEAN DEFAULT 0,
        next_actions_reviewed BOOLEAN DEFAULT 0,
        projects_updated BOOLEAN DEFAULT 0,
        goals_checked BOOLEAN DEFAULT 0,
        calendar_planned BOOLEAN DEFAULT 0,
        someday_reviewed BOOLEAN DEFAULT 0,
        new_goals_added BOOLEAN DEFAULT 0,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // PDS Plans table
    await db.execute('''
      CREATE TABLE pds_plans (
        id TEXT PRIMARY KEY,
        date DATE NOT NULL UNIQUE,
        freeform_plans TEXT,
        actual_activities TEXT,
        see_notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert initial data
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Default areas
    final defaultAreas = [
      {'id': 'area-work', 'type': 'area', 'title': '직장', 'status': 'active'},
      {'id': 'area-health', 'type': 'area', 'title': '건강', 'status': 'active'},
      {'id': 'area-learning', 'type': 'area', 'title': '학습', 'status': 'active'},
      {'id': 'area-personal', 'type': 'area', 'title': '개인', 'status': 'active'},
    ];

    // Default resources
    final defaultResources = [
      {'id': 'resource-ideas', 'type': 'resource', 'title': '아이디어', 'status': 'active'},
      {'id': 'resource-reading', 'type': 'resource', 'title': '읽을거리', 'status': 'active'},
      {'id': 'resource-hobbies', 'type': 'resource', 'title': '취미', 'status': 'active'},
    ];

    final allDefaults = [...defaultAreas, ...defaultResources];

    for (final item in allDefaults) {
      await db.insert(
        'items',
        {
          ...item,
          'priority': 3,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Default settings
    final defaultSettings = [
      {'key': 'theme', 'value': 'light'},
      {'key': 'language', 'value': 'ko'},
      {'key': 'notification_enabled', 'value': 'true'},
      {'key': 'review_reminder', 'value': 'weekly'},
      {'key': 'energy_tracking', 'value': 'true'},
    ];

    for (final setting in defaultSettings) {
      await db.insert(
        'settings',
        {
          ...setting,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Items CRUD
  Future<List<Item>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<Item> createItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toMap());
    return item;
  }

  Future<Item> updateItem(String id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await db.update('items', updates, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Item.fromMap(maps.first);
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Daily Plans CRUD
  Future<List<DailyPlan>> getAllDailyPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_plans',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => DailyPlan.fromMap(maps[i]));
  }

  Future<DailyPlan> createDailyPlan(DailyPlan plan) async {
    final db = await database;
    await db.insert('daily_plans', plan.toMap());
    return plan;
  }

  Future<DailyPlan> updateDailyPlan(String id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await db.update('daily_plans', updates, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    return DailyPlan.fromMap(maps.first);
  }

  Future<DailyPlan?> getDailyPlanByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_plans',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return DailyPlan.fromMap(maps.first);
  }

  // Reviews CRUD
  Future<List<Review>> getAllReviews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      orderBy: 'review_date DESC',
    );
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }

  Future<Review> createReview(Review review) async {
    final db = await database;
    await db.insert('reviews', review.toMap());
    return review;
  }

  Future<Review> updateReview(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update('reviews', updates, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Review.fromMap(maps.first);
  }

  Future<Review?> getReviewByDate(DateTime date, ReviewType type) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'review_date = ? AND type = ?',
      whereArgs: [dateStr, type.name],
    );
    if (maps.isEmpty) return null;
    return Review.fromMap(maps.first);
  }

  // Settings CRUD
  Future<List<AppSettings>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    return List.generate(maps.length, (i) => AppSettings.fromMap(maps[i]));
  }

  Future<AppSettings> updateSetting(String key, String value) async {
    final db = await database;
    await db.update(
      'settings',
      {
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [key],
    );
    
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return AppSettings.fromMap(maps.first);
  }

  Future<String?> getSettingValue(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'];
  }

  // Hierarchy CRUD
  Future<List<Hierarchy>> getAllHierarchies() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('hierarchy');
    return List.generate(maps.length, (i) => Hierarchy.fromMap(maps[i]));
  }

  Future<Hierarchy> createHierarchy(Hierarchy hierarchy) async {
    final db = await database;
    await db.insert('hierarchy', hierarchy.toMap());
    return hierarchy;
  }

  Future<void> deleteHierarchy(String id) async {
    final db = await database;
    await db.delete('hierarchy', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Item>> getChildren(String parentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.* FROM items i
      JOIN hierarchy h ON i.id = h.child_id
      WHERE h.parent_id = ?
    ''', [parentId]);
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<List<Item>> getParents(String childId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT i.* FROM items i
      JOIN hierarchy h ON i.id = h.parent_id
      WHERE h.child_id = ?
    ''', [childId]);
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  // PDS Plans CRUD
  Future<List<PDSPlan>> getAllPDSPlans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pds_plans',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => PDSPlan.fromMap(maps[i]));
  }

  // 락 스크린용 최적화된 데이터 로딩 - 오늘 날짜만
  Future<List<PDSPlan>> getPDSPlansForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await db.query(
      'pds_plans',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
    
    print('Database: Loaded ${maps.length} PDS plans for date $dateStr');
    return List.generate(maps.length, (i) => PDSPlan.fromMap(maps[i]));
  }

  Future<PDSPlan> createPDSPlan(PDSPlan plan) async {
    final db = await database;
    await db.insert('pds_plans', plan.toMap());
    return plan;
  }

  Future<PDSPlan> updatePDSPlan(String id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await db.update('pds_plans', updates, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'pds_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    return PDSPlan.fromMap(maps.first);
  }

  Future<PDSPlan?> getPDSPlanByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'pds_plans',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return PDSPlan.fromMap(maps.first);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // PDS Plans table 추가
      await db.execute('''
        CREATE TABLE pds_plans (
          id TEXT PRIMARY KEY,
          date DATE NOT NULL UNIQUE,
          freeform_plans TEXT,
          actual_activities TEXT,
          see_notes TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
  }
}