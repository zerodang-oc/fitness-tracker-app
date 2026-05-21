import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

export 'tables.dart';
import 'tables.dart';

/// 数据库管理器 - 使用 SQLite 直接操作
class AppDatabase {
  static AppDatabase? _instance;
  late Database _db;

  AppDatabase._();

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    final instance = AppDatabase._();
    await instance._init();
    _instance = instance;
    return instance;
  }

  Future<void> _init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'fitness_tracker.db');
    
    await Directory(p.dirname(dbPath)).create(recursive: true);
    
    _db = sqlite3.open(dbPath);
    
    _db.execute('PRAGMA journal_mode=WAL');
    _db.execute('PRAGMA foreign_keys=ON');
    
    _createTables();
    _seedFoodDatabase();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gender TEXT NOT NULL,
        age REAL NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        activity_level REAL NOT NULL DEFAULT 1.375,
        target_calorie_deficit REAL NOT NULL DEFAULT 300,
        unit TEXT NOT NULL DEFAULT 'metric',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS weight_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        body_fat REAL,
        recorded_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual'
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_type TEXT NOT NULL,
        duration_minutes REAL NOT NULL,
        calories_burned REAL NOT NULL,
        distance REAL,
        heart_rate_avg INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        notes TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS food_database (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        calories_per_100g REAL NOT NULL,
        carbs_per_100g REAL NOT NULL,
        fat_per_100g REAL NOT NULL,
        protein_per_100g REAL NOT NULL,
        fiber_per_100g REAL,
        unit TEXT NOT NULL DEFAULT 'g',
        image_url TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS meal_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_type TEXT NOT NULL,
        eaten_at TEXT NOT NULL,
        photo_path TEXT,
        total_calories REAL NOT NULL,
        total_carbs REAL NOT NULL,
        total_fat REAL NOT NULL,
        total_protein REAL NOT NULL,
        notes TEXT,
        ai_parsed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS meal_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        food_id INTEGER,
        food_name TEXT NOT NULL,
        amount REAL NOT NULL,
        calories REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        protein REAL NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meal_records(id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES food_database(id)
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS daily_summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        bmr REAL NOT NULL,
        exercise_calories REAL NOT NULL,
        total_calories_burned REAL NOT NULL,
        total_calories_intake REAL NOT NULL,
        calorie_deficit REAL NOT NULL,
        total_carbs REAL NOT NULL,
        total_fat REAL NOT NULL,
        total_protein REAL NOT NULL,
        carb_ratio REAL NOT NULL DEFAULT 0,
        fat_ratio REAL NOT NULL DEFAULT 0,
        protein_ratio REAL NOT NULL DEFAULT 0,
        suggestion TEXT,
        suggestion_generated INTEGER NOT NULL DEFAULT 0
      )
    ''');

    _db.execute('CREATE INDEX IF NOT EXISTS idx_meal_records_date ON meal_records(eaten_at)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_exercise_records_date ON exercise_records(start_time)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_meal_items_meal ON meal_items(meal_id)');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_daily_summaries_date ON daily_summaries(date)');
  }

  void _seedFoodDatabase() {
    final count = _db.select('SELECT COUNT(*) as cnt FROM food_database').first;
    if (count['cnt'] as int > 0) return;

    final stmt = _db.prepare('''
      INSERT INTO food_database (name, category, calories_per_100g, carbs_per_100g, fat_per_100g, protein_per_100g, fiber_per_100g)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''');

    for (final food in _defaultFoods) {
      stmt.execute([
        food['name'],
        food['category'],
        food['calories'],
        food['carbs'],
        food['fat'],
        food['protein'],
        food['fiber'],
      ]);
    }
    stmt.dispose();
  }

  // ========== 用户设置 ==========
  UserSetting? getUserSettings() {
    final results = _db.select('SELECT * FROM user_settings LIMIT 1');
    if (results.isEmpty) return null;
    return UserSetting.fromMap(results.first);
  }

  int saveUserSettings(UserSetting setting) {
    final existing = getUserSettings();
    if (existing != null) {
      _db.execute('''
        UPDATE user_settings SET 
          gender=?, age=?, height=?, weight=?, activity_level=?, target_calorie_deficit=?, updated_at=datetime('now')
        WHERE id=?
      ''', [
        setting.gender, setting.age, setting.height, setting.weight,
        setting.activityLevel, setting.targetCalorieDeficit, existing.id,
      ]);
      return existing.id;
    } else {
      _db.execute('''
        INSERT INTO user_settings (gender, age, height, weight, activity_level, target_calorie_deficit)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        setting.gender, setting.age, setting.height, setting.weight,
        setting.activityLevel, setting.targetCalorieDeficit,
      ]);
      return _db.lastInsertRowId;
    }
  }

  // ========== 体重 ==========
  List<WeightRecord> getWeightRecords({int? limit}) {
    final sql = 'SELECT * FROM weight_records ORDER BY recorded_at DESC${limit != null ? " LIMIT $limit" : ""}';
    return _db.select(sql).map((r) => WeightRecord.fromMap(r)).toList();
  }

  int addWeightRecord(WeightRecord record) {
    _db.execute('''
      INSERT INTO weight_records (weight, body_fat, recorded_at, source)
      VALUES (?, ?, ?, ?)
    ''', [record.weight, record.bodyFat, record.recordedAt, record.source]);
    return _db.lastInsertRowId;
  }

  // ========== 运动 ==========
  List<ExerciseRecord> getExerciseRecords(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db.select('''
      SELECT * FROM exercise_records 
      WHERE start_time >= ? AND start_time < ? 
      ORDER BY start_time DESC
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()])
        .map((r) => ExerciseRecord.fromMap(r)).toList();
  }

  List<ExerciseRecord> getExerciseRecordsRange(DateTime start, DateTime end) {
    return _db.select('''
      SELECT * FROM exercise_records 
      WHERE start_time >= ? AND start_time <= ? 
      ORDER BY start_time DESC
    ''', [start.toIso8601String(), end.toIso8601String()])
        .map((r) => ExerciseRecord.fromMap(r)).toList();
  }

  int addExerciseRecord(ExerciseRecord record) {
    _db.execute('''
      INSERT INTO exercise_records (exercise_type, duration_minutes, calories_burned, distance, heart_rate_avg, start_time, end_time, source, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      record.exerciseType, record.durationMinutes, record.caloriesBurned,
      record.distance, record.heartRateAvg,
      record.startTime.toIso8601String(), record.endTime?.toIso8601String(),
      record.source, record.notes,
    ]);
    return _db.lastInsertRowId;
  }

  double getTotalExerciseCalories(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final r = _db.select('''
      SELECT COALESCE(SUM(calories_burned), 0) as total FROM exercise_records 
      WHERE start_time >= ? AND start_time < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return (r.first['total'] as num).toDouble();
  }

  // ========== 餐食 ==========
  List<MealRecord> getMealRecords(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db.select('''
      SELECT * FROM meal_records 
      WHERE eaten_at >= ? AND eaten_at < ? 
      ORDER BY eaten_at DESC
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()])
        .map((r) => MealRecord.fromMap(r)).toList();
  }

  MealRecord? getMealRecord(int id) {
    final results = _db.select('SELECT * FROM meal_records WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return MealRecord.fromMap(results.first);
  }

  int addMealRecord(MealRecord record) {
    _db.execute('''
      INSERT INTO meal_records (meal_type, eaten_at, photo_path, total_calories, total_carbs, total_fat, total_protein, notes, ai_parsed)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      record.mealType, record.eatenAt.toIso8601String(), record.photoPath,
      record.totalCalories, record.totalCarbs, record.totalFat, record.totalProtein,
      record.notes, record.aiParsed,
    ]);
    return _db.lastInsertRowId;
  }

  void updateMealRecord(int id, MealRecord record) {
    _db.execute('''
      UPDATE meal_records SET 
        meal_type=?, total_calories=?, total_carbs=?, total_fat=?, total_protein=?, notes=?
      WHERE id=?
    ''', [
      record.mealType, record.totalCalories, record.totalCarbs,
      record.totalFat, record.totalProtein, record.notes, id,
    ]);
  }

  void deleteMealRecord(int id) {
    _db.execute('DELETE FROM meal_items WHERE meal_id = ?', [id]);
    _db.execute('DELETE FROM meal_records WHERE id = ?', [id]);
  }

  double getTotalCaloriesIntake(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final r = _db.select('''
      SELECT COALESCE(SUM(total_calories), 0) as total FROM meal_records 
      WHERE eaten_at >= ? AND eaten_at < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return (r.first['total'] as num).toDouble();
  }

  // ========== 餐食明细 ==========
  List<MealItem> getMealItems(int mealId) {
    return _db.select('SELECT * FROM meal_items WHERE meal_id = ?', [mealId])
        .map((r) => MealItem.fromMap(r)).toList();
  }

  void addMealItems(List<MealItem> items) {
    final stmt = _db.prepare('''
      INSERT INTO meal_items (meal_id, food_id, food_name, amount, calories, carbs, fat, protein)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    for (final item in items) {
      stmt.execute([item.mealId, item.foodId, item.foodName, item.amount, item.calories, item.carbs, item.fat, item.protein]);
    }
    stmt.dispose();
  }

  // ========== 食物数据库 ==========
  List<FoodItem> searchFood(String query) {
    return _db.select('SELECT * FROM food_database WHERE name LIKE ? LIMIT 20', ['%$query%'])
        .map((r) => FoodItem.fromMap(r)).toList();
  }

  List<FoodItem> getAllFoods() {
    return _db.select('SELECT * FROM food_database ORDER BY category, name')
        .map((r) => FoodItem.fromMap(r)).toList();
  }

  // ========== 每日总结 ==========
  DailySummary? getDailySummary(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final results = _db.select('SELECT * FROM daily_summaries WHERE date = ?', [dayStart.toIso8601String()]);
    if (results.isEmpty) return null;
    return DailySummary.fromMap(results.first);
  }

  void saveDailySummary(DailySummary summary) {
    final existing = getDailySummary(summary.date);
    if (existing != null) {
      _db.execute('''
        UPDATE daily_summaries SET 
          bmr=?, exercise_calories=?, total_calories_burned=?, total_calories_intake=?,
          calorie_deficit=?, total_carbs=?, total_fat=?, total_protein=?,
          carb_ratio=?, fat_ratio=?, protein_ratio=?,
          suggestion=?, suggestion_generated=?
        WHERE id=?
      ''', [
        summary.bmr, summary.exerciseCalories, summary.totalCaloriesBurned, summary.totalCaloriesIntake,
        summary.calorieDeficit, summary.totalCarbs, summary.totalFat, summary.totalProtein,
        summary.carbRatio, summary.fatRatio, summary.proteinRatio,
        summary.suggestion, summary.suggestionGenerated,
        existing.id,
      ]);
    } else {
      _db.execute('''
        INSERT INTO daily_summaries (date, bmr, exercise_calories, total_calories_burned, total_calories_intake,
          calorie_deficit, total_carbs, total_fat, total_protein, carb_ratio, fat_ratio, protein_ratio,
          suggestion, suggestion_generated)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        summary.date.toIso8601String(),
        summary.bmr, summary.exerciseCalories, summary.totalCaloriesBurned, summary.totalCaloriesIntake,
        summary.calorieDeficit, summary.totalCarbs, summary.totalFat, summary.totalProtein,
        summary.carbRatio, summary.fatRatio, summary.proteinRatio,
        summary.suggestion, summary.suggestionGenerated,
      ]);
    }
  }

  void clearAllData() {
    _db.execute('DELETE FROM meal_items');
    _db.execute('DELETE FROM meal_records');
    _db.execute('DELETE FROM exercise_records');
    _db.execute('DELETE FROM weight_records');
    _db.execute('DELETE FROM daily_summaries');
    _db.execute('DELETE FROM user_settings');
  }

  void dispose() {
    _db.dispose();
    _instance = null;
  }
}

// ========== 默认食物数据 ==========
final _defaultFoods = [
  {'name': '白米饭', 'category': '主食', 'calories': 116, 'carbs': 25.9, 'fat': 0.3, 'protein': 2.6, 'fiber': 0.3},
  {'name': '馒头', 'category': '主食', 'calories': 221, 'carbs': 44.2, 'fat': 1.1, 'protein': 7.0, 'fiber': 1.3},
  {'name': '面条(煮)', 'category': '主食', 'calories': 110, 'carbs': 24.3, 'fat': 0.2, 'protein': 3.4, 'fiber': 0.5},
  {'name': '全麦面包', 'category': '主食', 'calories': 246, 'carbs': 41.3, 'fat': 3.4, 'protein': 8.5, 'fiber': 7.4},
  {'name': '红薯', 'category': '主食', 'calories': 86, 'carbs': 20.1, 'fat': 0.1, 'protein': 1.6, 'fiber': 3.0},
  {'name': '玉米', 'category': '主食', 'calories': 112, 'carbs': 22.8, 'fat': 1.2, 'protein': 3.5, 'fiber': 2.7},
  {'name': '鸡蛋(煮)', 'category': '蛋类', 'calories': 155, 'carbs': 1.1, 'fat': 11.1, 'protein': 12.6, 'fiber': 0},
  {'name': '鸡蛋(炒)', 'category': '蛋类', 'calories': 196, 'carbs': 1.8, 'fat': 14.8, 'protein': 13.6, 'fiber': 0},
  {'name': '牛奶(全脂)', 'category': '乳制品', 'calories': 65, 'carbs': 5.0, 'fat': 3.5, 'protein': 3.0, 'fiber': 0},
  {'name': '酸奶(原味)', 'category': '乳制品', 'calories': 72, 'carbs': 10.0, 'fat': 2.0, 'protein': 3.5, 'fiber': 0},
  {'name': '鸡胸肉(煮)', 'category': '肉类', 'calories': 167, 'carbs': 0, 'fat': 3.6, 'protein': 32.0, 'fiber': 0},
  {'name': '鸡腿肉(去骨)', 'category': '肉类', 'calories': 181, 'carbs': 0, 'fat': 8.3, 'protein': 26.0, 'fiber': 0},
  {'name': '瘦猪肉', 'category': '肉类', 'calories': 143, 'carbs': 1.5, 'fat': 6.2, 'protein': 20.3, 'fiber': 0},
  {'name': '牛肉(瘦)', 'category': '肉类', 'calories': 125, 'carbs': 0, 'fat': 4.2, 'protein': 20.2, 'fiber': 0},
  {'name': '三文鱼', 'category': '海鲜', 'calories': 208, 'carbs': 0, 'fat': 13.4, 'protein': 20.5, 'fiber': 0},
  {'name': '虾仁', 'category': '海鲜', 'calories': 99, 'carbs': 0, 'fat': 1.8, 'protein': 20.1, 'fiber': 0},
  {'name': '豆腐(嫩)', 'category': '豆制品', 'calories': 62, 'carbs': 3.0, 'fat': 2.8, 'protein': 6.2, 'fiber': 0.4},
  {'name': '西兰花', 'category': '蔬菜', 'calories': 34, 'carbs': 4.4, 'fat': 0.4, 'protein': 2.9, 'fiber': 2.6},
  {'name': '胡萝卜', 'category': '蔬菜', 'calories': 41, 'carbs': 9.6, 'fat': 0.2, 'protein': 1.0, 'fiber': 2.8},
  {'name': '番茄', 'category': '蔬菜', 'calories': 18, 'carbs': 3.9, 'fat': 0.2, 'protein': 0.9, 'fiber': 1.2},
  {'name': '黄瓜', 'category': '蔬菜', 'calories': 15, 'carbs': 2.9, 'fat': 0.1, 'protein': 0.8, 'fiber': 0.5},
  {'name': '菠菜', 'category': '蔬菜', 'calories': 23, 'carbs': 3.6, 'fat': 0.4, 'protein': 2.9, 'fiber': 2.2},
  {'name': '苹果', 'category': '水果', 'calories': 52, 'carbs': 13.8, 'fat': 0.2, 'protein': 0.3, 'fiber': 2.4},
  {'name': '香蕉', 'category': '水果', 'calories': 89, 'carbs': 22.8, 'fat': 0.3, 'protein': 1.1, 'fiber': 2.6},
  {'name': '橙子', 'category': '水果', 'calories': 47, 'carbs': 11.8, 'fat': 0.1, 'protein': 0.9, 'fiber': 2.4},
];
