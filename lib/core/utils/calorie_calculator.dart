/// 每日热量与营养计算引擎
///
/// 负责：
/// 1. 计算基础代谢率 (BMR) - Mifflin-St Jeor 公式
/// 2. 计算总消耗 (BMR + 运动)
/// 3. 计算热量缺口
/// 4. 营养比例分析
class CalorieCalculator {
  /// 计算基础代谢率 (BMR)
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required double age,
    required String gender,
  }) {
    if (gender == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
  }

  /// 计算总消耗（BMR + 运动消耗）
  static double calculateTotalBurned({
    required double bmr,
    required double exerciseCalories,
  }) {
    return bmr + exerciseCalories;
  }

  /// 计算热量缺口（正值=减脂，负值=增重）
  static double calculateDeficit({
    required double totalCaloriesBurned,
    required double totalCaloriesIntake,
  }) {
    return totalCaloriesBurned - totalCaloriesIntake;
  }

  /// 按餐分配热量缺口
  static Map<String, double> calculateMealDeficit({
    required double breakfastCalories,
    required double lunchCalories,
    required double dinnerCalories,
    required double snackCalories,
    required double totalDeficit,
  }) {
    final totalIntake = breakfastCalories + lunchCalories + dinnerCalories + snackCalories;
    if (totalIntake <= 0) return {'breakfast': 0, 'lunch': 0, 'dinner': 0, 'snack': 0};

    return {
      'breakfast': totalDeficit * (breakfastCalories / totalIntake),
      'lunch': totalDeficit * (lunchCalories / totalIntake),
      'dinner': totalDeficit * (dinnerCalories / totalIntake),
      'snack': totalDeficit * (snackCalories / totalIntake),
    };
  }

  /// 计算营养素比例（占卡路里百分比）
  static Map<String, double> calculateNutritionRatio({
    required double carbsGrams,
    required double proteinGrams,
    required double fatGrams,
  }) {
    final totalCaloriesFromNutrients = carbsGrams * 4 + proteinGrams * 4 + fatGrams * 9;
    if (totalCaloriesFromNutrients <= 0) {
      return {'carbs': 0, 'protein': 0, 'fat': 0};
    }

    return {
      'carbs': (carbsGrams * 4 / totalCaloriesFromNutrients * 100),
      'protein': (proteinGrams * 4 / totalCaloriesFromNutrients * 100),
      'fat': (fatGrams * 9 / totalCaloriesFromNutrients * 100),
    };
  }

  /// 推荐营养比例（减脂模式）
  static Map<String, double> getRecommendedRatios() {
    return {'carbs': 35, 'protein': 40, 'fat': 25};
  }

  /// 根据目标计算每日目标摄入
  static double calculateTargetCalories({
    required double bmr,
    required double targetDeficitPerDay,
  }) {
    return bmr - targetDeficitPerDay;
  }

  /// 估算减脂重量 (7700 kcal ≈ 1kg 脂肪)
  static double estimateFatLossKg(double totalDeficit) {
    return totalDeficit / 7700;
  }
}
