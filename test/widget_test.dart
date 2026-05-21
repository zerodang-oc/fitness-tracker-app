import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/core/utils/calorie_calculator.dart';

void main() {
  test('BMR calculation for male', () {
    final bmr = CalorieCalculator.calculateBMR(
      weightKg: 70,
      heightCm: 175,
      age: 30,
      gender: 'male',
    );
    // 10*70 + 6.25*175 - 5*30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
    expect(bmr, closeTo(1648.75, 0.1));
  });

  test('BMR calculation for female', () {
    final bmr = CalorieCalculator.calculateBMR(
      weightKg: 60,
      heightCm: 165,
      age: 28,
      gender: 'female',
    );
    // 10*60 + 6.25*165 - 5*28 - 161 = 600 + 1031.25 - 140 - 161 = 1330.25
    expect(bmr, closeTo(1330.25, 0.1));
  });

  test('Calorie deficit calculation', () {
    final deficit = CalorieCalculator.calculateDeficit(
      totalCaloriesBurned: 2000,
      totalCaloriesIntake: 1500,
    );
    expect(deficit, 500);
  });

  test('Nutrition ratio calculation', () {
    final ratios = CalorieCalculator.calculateNutritionRatio(
      carbsGrams: 100,
      proteinGrams: 80,
      fatGrams: 30,
    );
    // total: 100*4 + 80*4 + 30*9 = 400 + 320 + 270 = 990
    expect(ratios['carbs']!, closeTo(400 / 990 * 100, 0.1));
    expect(ratios['protein']!, closeTo(320 / 990 * 100, 0.1));
    expect(ratios['fat']!, closeTo(270 / 990 * 100, 0.1));
  });
}
