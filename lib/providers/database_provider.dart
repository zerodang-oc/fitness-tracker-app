import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/tables.dart';
import '../core/database/database.dart';

export '../core/database/database.dart' show AppDatabase;

/// 数据库实例 Provider
final databaseProvider = FutureProvider<Database>((ref) async {
  return AppDatabase.getInstance();
});

/// 当前选中日期
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 用户设置
final userSettingsProvider = FutureProvider<UserSetting?>((ref) async {
  await ref.watch(databaseProvider.future);
  return AppDatabase.getUserSettings();
});

/// 当日运动记录
final todayExerciseRecordsProvider = FutureProvider<List<ExerciseRecord>>((ref) async {
  await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return AppDatabase.getExerciseRecords(date);
});

/// 当日运动总消耗
final todayExerciseCaloriesProvider = FutureProvider<double>((ref) async {
  await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return AppDatabase.getTotalExerciseCalories(date);
});

/// 当日餐食记录
final todayMealRecordsProvider = FutureProvider<List<MealRecord>>((ref) async {
  await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return AppDatabase.getMealRecords(date);
});

/// 当日总摄入
final todayCaloriesIntakeProvider = FutureProvider<double>((ref) async {
  await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return AppDatabase.getTotalCaloriesIntake(date);
});
