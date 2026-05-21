import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/calorie_calculator.dart';
import '../core/utils/suggestion_generator.dart';
import 'database_provider.dart';

// ========== 计算型 Providers ==========

/// BMR 基础代谢率
final bmrProvider = FutureProvider<double>((ref) async {
  final settings = await ref.watch(userSettingsProvider.future);
  if (settings == null) return 0;
  return CalorieCalculator.calculateBMR(
    weightKg: settings.weight,
    heightCm: settings.height,
    age: settings.age,
    gender: settings.gender,
  );
});

/// 今日总消耗 (BMR + 运动)
final todayTotalBurnedProvider = FutureProvider<double>((ref) async {
  final bmr = await ref.watch(bmrProvider.future);
  final exerciseCal = await ref.watch(todayExerciseCaloriesProvider.future);
  return CalorieCalculator.calculateTotalBurned(
    bmr: bmr,
    exerciseCalories: exerciseCal,
  );
});

/// 今日热量缺口
final todayDeficitProvider = FutureProvider<double>((ref) async {
  final totalBurned = await ref.watch(todayTotalBurnedProvider.future);
  final totalIntake = await ref.watch(todayCaloriesIntakeProvider.future);
  return CalorieCalculator.calculateDeficit(
    totalCaloriesBurned: totalBurned,
    totalCaloriesIntake: totalIntake,
  );
});

/// 各餐卡路里汇总
final mealCaloriesProvider = FutureProvider<Map<String, double>>((ref) async {
  final meals = await ref.watch(todayMealRecordsProvider.future);
  final result = <String, double>{};
  for (final type in ['breakfast', 'lunch', 'dinner', 'snack']) {
    result[type] = 0;
  }
  for (final meal in meals) {
    result[meal.mealType] = (result[meal.mealType] ?? 0) + meal.totalCalories;
  }
  return result;
});

/// 各餐热量缺口分配
final mealDeficitsProvider = FutureProvider<Map<String, double>>((ref) async {
  final totalDeficit = await ref.watch(todayDeficitProvider.future);
  final mealCal = await ref.watch(mealCaloriesProvider.future);
  return CalorieCalculator.calculateMealDeficit(
    breakfastCalories: mealCal['breakfast'] ?? 0,
    lunchCalories: mealCal['lunch'] ?? 0,
    dinnerCalories: mealCal['dinner'] ?? 0,
    snackCalories: mealCal['snack'] ?? 0,
    totalDeficit: totalDeficit,
  );
});

/// 今日总结
final todaySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final date = ref.watch(selectedDateProvider);
  return db.getDailySummary(date);
});

/// 保存每日总结并生成建议
Future<void> saveDailySummary(dynamic ref, DateTime date) async {
  final db = await ref.read(databaseProvider.future);
  final settings = await ref.read(userSettingsProvider.future);
  if (settings == null) return;

  final bmr = await ref.read(bmrProvider.future);
  final exerciseCalories = await ref.read(todayExerciseCaloriesProvider.future);
  final totalCaloriesBurned = await ref.read(todayTotalBurnedProvider.future);
  final totalCaloriesIntake = await ref.read(todayCaloriesIntakeProvider.future);
  final deficit = await ref.read(todayDeficitProvider.future);
  final meals = await ref.read(todayMealRecordsProvider.future);

  final totalCarbs = meals.fold<double>(0, (s, m) => s + m.totalCarbs);
  final totalFat = meals.fold<double>(0, (s, m) => s + m.totalFat);
  final totalProtein = meals.fold<double>(0, (s, m) => s + m.totalProtein);

  final ratios = CalorieCalculator.calculateNutritionRatio(
    carbsGrams: totalCarbs,
    proteinGrams: totalProtein,
    fatGrams: totalFat,
  );

  final existingSummary = db.getDailySummary(date);

  final summary = DailySummary(
    id: existingSummary?.id ?? 0,
    date: DateTime(date.year, date.month, date.day),
    bmr: bmr,
    exerciseCalories: exerciseCalories,
    totalCaloriesBurned: totalCaloriesBurned,
    totalCaloriesIntake: totalCaloriesIntake,
    calorieDeficit: deficit,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    totalProtein: totalProtein,
    carbRatio: ratios['carbs']!,
    fatRatio: ratios['fat']!,
    proteinRatio: ratios['protein']!,
    suggestion: '',
    suggestionGenerated: 0,
  );

  final suggestion = SuggestionGenerator.generate(
    summary: summary,
    targetDeficit: settings.targetCalorieDeficit,
    userSettings: settings,
  );

  db.saveDailySummary(DailySummary(
    id: existingSummary?.id ?? 0,
    date: DateTime(date.year, date.month, date.day),
    bmr: bmr,
    exerciseCalories: exerciseCalories,
    totalCaloriesBurned: totalCaloriesBurned,
    totalCaloriesIntake: totalCaloriesIntake,
    calorieDeficit: deficit,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    totalProtein: totalProtein,
    carbRatio: ratios['carbs']!,
    fatRatio: ratios['fat']!,
    proteinRatio: ratios['protein']!,
    suggestion: suggestion,
    suggestionGenerated: 1,
  ));
}
