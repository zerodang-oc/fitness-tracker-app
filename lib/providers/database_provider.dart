import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/tables.dart';

/// 数据库接口
abstract class AppDatabase {
  Future<UserSetting?> getUserSettings();
  Future<int> saveUserSettings(UserSetting setting);
  Future<List<ExerciseRecord>> getExerciseRecords(DateTime date);
  Future<int> addExerciseRecord(ExerciseRecord record);
  Future<double> getTotalExerciseCalories(DateTime date);
  Future<List<MealRecord>> getMealRecords(DateTime date);
  Future<int> addMealRecord(MealRecord record);
  Future<void> addMealItems(List<MealItem> items);
  Future<double> getTotalCaloriesIntake(DateTime date);
  Future<DailySummary?> getDailySummary(DateTime date);
  Future<void> saveDailySummary(DailySummary summary);
  Future<void> clearAllData();
}

/// 数据库实例 Provider
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return WebMockDatabase();
});

/// 当前选中日期
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 用户设置
final userSettingsProvider = FutureProvider<UserSetting?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getUserSettings();
});

/// 当日运动记录
final todayExerciseRecordsProvider = FutureProvider<List<ExerciseRecord>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return db.getExerciseRecords(date);
});

/// 当日运动总消耗
final todayExerciseCaloriesProvider = FutureProvider<double>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return db.getTotalExerciseCalories(date);
});

/// 当日餐食记录
final todayMealRecordsProvider = FutureProvider<List<MealRecord>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return db.getMealRecords(date);
});

/// 当日总摄入
final todayCaloriesIntakeProvider = FutureProvider<double>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return db.getTotalCaloriesIntake(date);
});

// ========== Web 内存数据库实现 ==========

class WebMockDatabase implements AppDatabase {
  UserSetting? _userSetting;
  final _exercises = <ExerciseRecord>[];
  final _meals = <MealRecord>[];
  DailySummary? _summary;

  @override
  Future<UserSetting?> getUserSettings() async => _userSetting;

  @override
  Future<int> saveUserSettings(UserSetting s) async {
    _userSetting = UserSetting(
      id: 1, gender: s.gender, age: s.age, height: s.height, weight: s.weight,
      activityLevel: s.activityLevel, targetCalorieDeficit: s.targetCalorieDeficit,
    );
    return 1;
  }

  @override
  Future<List<ExerciseRecord>> getExerciseRecords(DateTime d) async => _exercises;

  @override
  Future<int> addExerciseRecord(ExerciseRecord r) async {
    _exercises.add(ExerciseRecord(
      id: _exercises.length + 1, exerciseType: r.exerciseType,
      durationMinutes: r.durationMinutes, caloriesBurned: r.caloriesBurned,
      distance: r.distance, heartRateAvg: r.heartRateAvg,
      startTime: r.startTime, endTime: r.endTime,
      source: r.source, notes: r.notes,
    ));
    return _exercises.length;
  }

  @override
  Future<double> getTotalExerciseCalories(DateTime d) async {
    return _exercises.fold<double>(0, (s, e) => s + e.caloriesBurned);
  }

  @override
  Future<List<MealRecord>> getMealRecords(DateTime d) async => _meals;

  @override
  Future<int> addMealRecord(MealRecord m) async {
    _meals.add(MealRecord(
      id: _meals.length + 1, mealType: m.mealType, eatenAt: m.eatenAt,
      totalCalories: m.totalCalories, totalCarbs: m.totalCarbs,
      totalFat: m.totalFat, totalProtein: m.totalProtein,
      photoPath: m.photoPath, notes: m.notes, aiParsed: m.aiParsed,
    ));
    return _meals.length;
  }

  @override
  Future<void> addMealItems(List<MealItem> items) async {}

  @override
  Future<double> getTotalCaloriesIntake(DateTime d) async {
    return _meals.fold<double>(0, (s, m) => s + m.totalCalories);
  }

  @override
  Future<DailySummary?> getDailySummary(DateTime d) async => _summary;

  @override
  Future<void> saveDailySummary(DailySummary s) async { _summary = s; }

  @override
  Future<void> clearAllData() async {
    _exercises.clear(); _meals.clear(); _summary = null;
  }
}
