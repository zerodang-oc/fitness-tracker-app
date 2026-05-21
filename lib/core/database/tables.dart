// ========== 用户设置 ==========
class UserSetting {
  final int id;
  final String gender;
  final double age;
  final double height;
  final double weight;
  final double activityLevel;
  final double targetCalorieDeficit;
  final String unit;
  final String createdAt;
  final String updatedAt;

  UserSetting({
    this.id = 0,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    this.activityLevel = 1.375,
    this.targetCalorieDeficit = 300,
    this.unit = 'metric',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory UserSetting.fromMap(Map<String, dynamic> map) {
    return UserSetting(
      id: map['id'] as int,
      gender: map['gender'] as String,
      age: (map['age'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      activityLevel: (map['activity_level'] as num).toDouble(),
      targetCalorieDeficit: (map['target_calorie_deficit'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? 'metric',
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: (map['updated_at'] as String?) ?? '',
    );
  }
}

// ========== 体重记录 ==========
class WeightRecord {
  final int id;
  final double weight;
  final double? bodyFat;
  final DateTime recordedAt;
  final String source;

  WeightRecord({
    this.id = 0,
    required this.weight,
    this.bodyFat,
    required this.recordedAt,
    this.source = 'manual',
  });

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int,
      weight: (map['weight'] as num).toDouble(),
      bodyFat: (map['body_fat'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      source: map['source'] as String? ?? 'manual',
    );
  }
}

// ========== 运动记录 ==========
class ExerciseRecord {
  final int id;
  final String exerciseType;
  final double durationMinutes;
  final double caloriesBurned;
  final double? distance;
  final int? heartRateAvg;
  final DateTime startTime;
  final DateTime? endTime;
  final String source;
  final String? notes;

  ExerciseRecord({
    this.id = 0,
    required this.exerciseType,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.distance,
    this.heartRateAvg,
    required this.startTime,
    this.endTime,
    this.source = 'manual',
    this.notes,
  });

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      id: map['id'] as int,
      exerciseType: map['exercise_type'] as String,
      durationMinutes: (map['duration_minutes'] as num).toDouble(),
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      heartRateAvg: map['heart_rate_avg'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      source: map['source'] as String? ?? 'manual',
      notes: map['notes'] as String?,
    );
  }
}

// ========== 食物数据库条目 ==========
class FoodItem {
  final int id;
  final String name;
  final String category;
  final double caloriesPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double proteinPer100g;
  final double? fiberPer100g;

  FoodItem({
    this.id = 0,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.proteinPer100g,
    this.fiberPer100g,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      fiberPer100g: (map['fiber_per_100g'] as num?)?.toDouble(),
    );
  }
}

// ========== 餐食记录 ==========
class MealRecord {
  final int id;
  final String mealType;
  final DateTime eatenAt;
  final String? photoPath;
  final double totalCalories;
  final double totalCarbs;
  final double totalFat;
  final double totalProtein;
  final String? notes;
  final int aiParsed;

  MealRecord({
    this.id = 0,
    required this.mealType,
    required this.eatenAt,
    this.photoPath,
    this.totalCalories = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
    this.notes,
    this.aiParsed = 0,
  });

  factory MealRecord.fromMap(Map<String, dynamic> map) {
    return MealRecord(
      id: map['id'] as int,
      mealType: map['meal_type'] as String,
      eatenAt: DateTime.parse(map['eaten_at'] as String),
      photoPath: map['photo_path'] as String?,
      totalCalories: (map['total_calories'] as num).toDouble(),
      totalCarbs: (map['total_carbs'] as num).toDouble(),
      totalFat: (map['total_fat'] as num).toDouble(),
      totalProtein: (map['total_protein'] as num).toDouble(),
      notes: map['notes'] as String?,
      aiParsed: map['ai_parsed'] as int? ?? 0,
    );
  }
}

// ========== 餐食明细 ==========
class MealItem {
  final int id;
  final int mealId;
  final int? foodId;
  final String foodName;
  final double amount;
  final double calories;
  final double carbs;
  final double fat;
  final double protein;

  MealItem({
    this.id = 0,
    required this.mealId,
    this.foodId,
    required this.foodName,
    required this.amount,
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.protein,
  });

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'] as int,
      mealId: map['meal_id'] as int,
      foodId: map['food_id'] as int?,
      foodName: map['food_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
    );
  }
}

// ========== 每日总结 ==========
class DailySummary {
  final int id;
  final DateTime date;
  final double bmr;
  final double exerciseCalories;
  final double totalCaloriesBurned;
  final double totalCaloriesIntake;
  final double calorieDeficit;
  final double totalCarbs;
  final double totalFat;
  final double totalProtein;
  final double carbRatio;
  final double fatRatio;
  final double proteinRatio;
  final String suggestion;
  final int suggestionGenerated;

  DailySummary({
    this.id = 0,
    required this.date,
    this.bmr = 0,
    this.exerciseCalories = 0,
    this.totalCaloriesBurned = 0,
    this.totalCaloriesIntake = 0,
    this.calorieDeficit = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalProtein = 0,
    this.carbRatio = 0,
    this.fatRatio = 0,
    this.proteinRatio = 0,
    this.suggestion = '',
    this.suggestionGenerated = 0,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      id: map['id'] as int,
      date: DateTime.parse(map['date'] as String),
      bmr: (map['bmr'] as num).toDouble(),
      exerciseCalories: (map['exercise_calories'] as num).toDouble(),
      totalCaloriesBurned: (map['total_calories_burned'] as num).toDouble(),
      totalCaloriesIntake: (map['total_calories_intake'] as num).toDouble(),
      calorieDeficit: (map['calorie_deficit'] as num).toDouble(),
      totalCarbs: (map['total_carbs'] as num).toDouble(),
      totalFat: (map['total_fat'] as num).toDouble(),
      totalProtein: (map['total_protein'] as num).toDouble(),
      carbRatio: (map['carb_ratio'] as num).toDouble(),
      fatRatio: (map['fat_ratio'] as num).toDouble(),
      proteinRatio: (map['protein_ratio'] as num).toDouble(),
      suggestion: map['suggestion'] as String? ?? '',
      suggestionGenerated: map['suggestion_generated'] as int? ?? 0,
    );
  }
}
