/// 餐食类型定义
class MealType {
  static const breakfast = 'breakfast';
  static const lunch = 'lunch';
  static const dinner = 'dinner';
  static const snack = 'snack';

  static List<String> get allTypes => [breakfast, lunch, dinner, snack];

  static String getLabel(String type) {
    switch (type) {
      case breakfast: return '早餐';
      case lunch: return '午餐';
      case dinner: return '晚餐';
      case snack: return '加餐';
      default: return type;
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case breakfast: return '🌅';
      case lunch: return '☀️';
      case dinner: return '🌙';
      case snack: return '🍪';
      default: return '🍽️';
    }
  }
}

/// 运动类型定义
class ExerciseType {
  static const running = 'running';
  static const walking = 'walking';
  static const cycling = 'cycling';
  static const swimming = 'swimming';
  static const gym = 'gym';
  static const yoga = 'yoga';
  static const hiit = 'hiit';
  static const basketball = 'basketball';
  static const badminton = 'badminton';
  static const other = 'other';

  static List<String> get allTypes => [
    running, walking, cycling, swimming, gym, 
    yoga, hiit, basketball, badminton, other
  ];

  static String getLabel(String type) {
    switch (type) {
      case running: return '跑步';
      case walking: return '步行';
      case cycling: return '骑行';
      case swimming: return '游泳';
      case gym: return '健身';
      case yoga: return '瑜伽';
      case hiit: return 'HIIT';
      case basketball: return '篮球';
      case badminton: return '羽毛球';
      case other: return '其他';
      default: return type;
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case running: return '🏃';
      case walking: return '🚶';
      case cycling: return '🚴';
      case swimming: return '🏊';
      case gym: return '🏋️';
      case yoga: return '🧘';
      case hiit: return '💪';
      case basketball: return '🏀';
      case badminton: return '🏸';
      case other: return '🎯';
      default: return '🏃';
    }
  }

  static double getMetValue(String type) {
    switch (type) {
      case running: return 8.0;
      case walking: return 3.5;
      case cycling: return 6.0;
      case swimming: return 6.0;
      case gym: return 5.0;
      case yoga: return 2.5;
      case hiit: return 8.5;
      case basketball: return 6.5;
      case badminton: return 5.5;
      default: return 4.0;
    }
  }
}
