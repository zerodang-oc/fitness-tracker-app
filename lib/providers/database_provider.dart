import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';

export '../core/database/database.dart' show 
  AppDatabase, UserSetting, ExerciseRecord, MealRecord, MealItem, 
  FoodItem, WeightRecord, DailySummary;

/// 数据库实例 Provider
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.getInstance();
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
