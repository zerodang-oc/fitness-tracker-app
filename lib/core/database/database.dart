import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

export 'tables.dart';
import 'tables.dart';

/// 数据库管理器 - 使用 sqflite
class AppDatabase {
  static Database? _db;

  AppDatabase._();

  static Future<Database> getInstance() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'fitness_tracker.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedFoodDatabase(db);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA foreign_keys=ON');
      },
    );
    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        body_fat REAL,
        recorded_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual'
      )
    ''');

    await db.execute('''
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

    await db.execute('''
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

    await db.execute('''
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

    await db.execute('''
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

    await db.execute('''
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

    await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_records_date ON meal_records(eaten_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exercise_records_date ON exercise_records(start_time)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_meal_items_meal ON meal_items(meal_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_summaries_date ON daily_summaries(date)');
  }

  static Future<void> _seedFoodDatabase(Database db) async {
    final count = await db.rawQuery('SELECT COUNT(*) as cnt FROM food_database');
    if ((count.first['cnt'] as int) > 0) return;

    final batch = db.batch();
    for (final food in _defaultFoods) {
      batch.rawInsert('''
        INSERT INTO food_database (name, category, calories_per_100g, carbs_per_100g, fat_per_100g, protein_per_100g, fiber_per_100g)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''', [
        food['name'],
        food['category'],
        food['calories'],
        food['carbs'],
        food['fat'],
        food['protein'],
        food['fiber'],
      ]);
    }
    await batch.commit(noResult: true);
  }

  // ========== 用户设置 ==========
  static Future<UserSetting?> getUserSettings() async {
    final db = _db!;
    final results = await db.rawQuery('SELECT * FROM user_settings LIMIT 1');
    if (results.isEmpty) return null;
    return UserSetting.fromSqliteMap(results.first);
  }

  static Future<int> saveUserSettings(UserSetting setting) async {
    final db = _db!;
    final existing = await getUserSettings();
    if (existing != null) {
      await db.rawUpdate('''
        UPDATE user_settings SET 
          gender=?, age=?, height=?, weight=?, activity_level=?, target_calorie_deficit=?, updated_at=datetime('now')
        WHERE id=?
      ''', [
        setting.gender, setting.age, setting.height, setting.weight,
        setting.activityLevel, setting.targetCalorieDeficit, existing.id,
      ]);
      return existing.id;
    } else {
      final id = await db.rawInsert('''
        INSERT INTO user_settings (gender, age, height, weight, activity_level, target_calorie_deficit)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        setting.gender, setting.age, setting.height, setting.weight,
        setting.activityLevel, setting.targetCalorieDeficit,
      ]);
      return id;
    }
  }

  // ========== 体重 ==========
  static Future<List<WeightRecord>> getWeightRecords({int? limit}) async {
    final db = _db!;
    final sql = 'SELECT * FROM weight_records ORDER BY recorded_at DESC${limit != null ? " LIMIT $limit" : ""}';
    final results = await db.rawQuery(sql);
    return results.map((r) => WeightRecord.fromSqliteMap(r)).toList();
  }

  static Future<int> addWeightRecord(WeightRecord record) async {
    final db = _db!;
    return await db.rawInsert('''
      INSERT INTO weight_records (weight, body_fat, recorded_at, source)
      VALUES (?, ?, ?, ?)
    ''', [record.weight, record.bodyFat, record.recordedAt.toIso8601String(), record.source]);
  }

  // ========== 运动 ==========
  static Future<List<ExerciseRecord>> getExerciseRecords(DateTime date) async {
    final db = _db!;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final results = await db.rawQuery('''
      SELECT * FROM exercise_records 
      WHERE start_time >= ? AND start_time < ? 
      ORDER BY start_time DESC
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return results.map((r) => ExerciseRecord.fromSqliteMap(r)).toList();
  }

  static Future<List<ExerciseRecord>> getExerciseRecordsRange(DateTime start, DateTime end) async {
    final db = _db!;
    final results = await db.rawQuery('''
      SELECT * FROM exercise_records 
      WHERE start_time >= ? AND start_time <= ? 
      ORDER BY start_time DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return results.map((r) => ExerciseRecord.fromSqliteMap(r)).toList();
  }

  static Future<int> addExerciseRecord(ExerciseRecord record) async {
    final db = _db!;
    return await db.rawInsert('''
      INSERT INTO exercise_records (exercise_type, duration_minutes, calories_burned, distance, heart_rate_avg, start_time, end_time, source, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      record.exerciseType, record.durationMinutes, record.caloriesBurned,
      record.distance, record.heartRateAvg,
      record.startTime.toIso8601String(), record.endTime?.toIso8601String(),
      record.source, record.notes,
    ]);
  }

  static Future<double> getTotalExerciseCalories(DateTime date) async {
    final db = _db!;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(calories_burned), 0) as total FROM exercise_records 
      WHERE start_time >= ? AND start_time < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return (r.first['total'] as num).toDouble();
  }

  // ========== 餐食 ==========
  static Future<List<MealRecord>> getMealRecords(DateTime date) async {
    final db = _db!;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final results = await db.rawQuery('''
      SELECT * FROM meal_records 
      WHERE eaten_at >= ? AND eaten_at < ? 
      ORDER BY eaten_at DESC
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return results.map((r) => MealRecord.fromSqliteMap(r)).toList();
  }

  static Future<MealRecord?> getMealRecord(int id) async {
    final db = _db!;
    final results = await db.rawQuery('SELECT * FROM meal_records WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return MealRecord.fromSqliteMap(results.first);
  }

  static Future<int> addMealRecord(MealRecord record) async {
    final db = _db!;
    return await db.rawInsert('''
      INSERT INTO meal_records (meal_type, eaten_at, photo_path, total_calories, total_carbs, total_fat, total_protein, notes, ai_parsed)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      record.mealType, record.eatenAt.toIso8601String(), record.photoPath,
      record.totalCalories, record.totalCarbs, record.totalFat, record.totalProtein,
      record.notes, record.aiParsed,
    ]);
  }

  static Future<void> updateMealRecord(int id, MealRecord record) async {
    final db = _db!;
    await db.rawUpdate('''
      UPDATE meal_records SET 
        meal_type=?, total_calories=?, total_carbs=?, total_fat=?, total_protein=?, notes=?
      WHERE id=?
    ''', [
      record.mealType, record.totalCalories, record.totalCarbs,
      record.totalFat, record.totalProtein, record.notes, id,
    ]);
  }

  static Future<void> deleteMealRecord(int id) async {
    final db = _db!;
    await db.rawDelete('DELETE FROM meal_items WHERE meal_id = ?', [id]);
    await db.rawDelete('DELETE FROM meal_records WHERE id = ?', [id]);
  }

  static Future<double> getTotalCaloriesIntake(DateTime date) async {
    final db = _db!;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(total_calories), 0) as total FROM meal_records 
      WHERE eaten_at >= ? AND eaten_at < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    return (r.first['total'] as num).toDouble();
  }

  // ========== 餐食明细 ==========
  static Future<List<MealItem>> getMealItems(int mealId) async {
    final db = _db!;
    final results = await db.rawQuery('SELECT * FROM meal_items WHERE meal_id = ?', [mealId]);
    return results.map((r) => MealItem.fromSqliteMap(r)).toList();
  }

  static Future<void> addMealItems(List<MealItem> items) async {
    final db = _db!;
    final batch = db.batch();
    for (final item in items) {
      batch.rawInsert('''
        INSERT INTO meal_items (meal_id, food_id, food_name, amount, calories, carbs, fat, protein)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [item.mealId, item.foodId, item.foodName, item.amount, item.calories, item.carbs, item.fat, item.protein]);
    }
    await batch.commit(noResult: true);
  }

  // ========== 食物数据库 ==========
  static Future<List<FoodItem>> searchFood(String query) async {
    final db = _db!;
    final results = await db.rawQuery('SELECT * FROM food_database WHERE name LIKE ? LIMIT 20', ['%$query%']);
    return results.map((r) => FoodItem.fromSqliteMap(r)).toList();
  }

  static Future<List<FoodItem>> getAllFoods() async {
    final db = _db!;
    final results = await db.rawQuery('SELECT * FROM food_database ORDER BY category, name');
    return results.map((r) => FoodItem.fromSqliteMap(r)).toList();
  }

  // ========== 每日总结 ==========
  static Future<DailySummary?> getDailySummary(DateTime date) async {
    final db = _db!;
    final dayStart = DateTime(date.year, date.month, date.day);
    final results = await db.rawQuery('SELECT * FROM daily_summaries WHERE date = ?', [dayStart.toIso8601String()]);
    if (results.isEmpty) return null;
    return DailySummary.fromSqliteMap(results.first);
  }

  static Future<void> saveDailySummary(DailySummary summary) async {
    final db = _db!;
    final existing = await getDailySummary(summary.date);
    if (existing != null) {
      await db.rawUpdate('''
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
      await db.rawInsert('''
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

  static Future<void> clearAllData() async {
    final db = _db!;
    await db.rawDelete('DELETE FROM meal_items');
    await db.rawDelete('DELETE FROM meal_records');
    await db.rawDelete('DELETE FROM exercise_records');
    await db.rawDelete('DELETE FROM weight_records');
    await db.rawDelete('DELETE FROM daily_summaries');
    await db.rawDelete('DELETE FROM user_settings');
  }

  static Future<void> dispose() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
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
