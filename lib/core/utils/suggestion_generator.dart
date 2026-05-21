import '../database/tables.dart';
import 'calorie_calculator.dart';

/// 每日建议生成器
///
/// 根据当天数据生成饮食和运动建议
/// 前期使用规则引擎，后期可接入豆包 API
class SuggestionGenerator {
  /// 生成每日总结和建议
  static String generate({
    required DailySummary summary,
    required double targetDeficit,
    required UserSetting userSettings,
  }) {
    final buffer = StringBuffer();
    
    // 1. 热量缺口分析
    buffer.writeln(_generateDeficitAnalysis(summary, targetDeficit));
    buffer.writeln();
    
    // 2. 营养分析
    buffer.writeln(_generateNutritionAnalysis(summary));
    buffer.writeln();
    
    // 3. 饮食建议
    buffer.writeln(_generateDietAdvice(summary, userSettings));
    buffer.writeln();
    
    // 4. 运动建议
    buffer.writeln(_generateExerciseAdvice(summary));
    buffer.writeln();
    
    // 5. 第二天计划
    buffer.writeln(_generateTomorrowSuggestion(summary, targetDeficit, userSettings));

    return buffer.toString().trim();
  }

  static String _generateDeficitAnalysis(DailySummary summary, double targetDeficit) {
    final deficit = summary.calorieDeficit;
    final status = deficit >= targetDeficit * 0.9 
        ? '✅ 达标！' 
        : (deficit > 0 
            ? '⚠️ 缺口不足' 
            : '❌ 热量超标');
    
    return '📊 **热量总结**\n'
        '总消耗: ${summary.totalCaloriesBurned.toStringAsFixed(0)} kcal\n'
        '总摄入: ${summary.totalCaloriesIntake.toStringAsFixed(0)} kcal\n'
        '运动消耗: ${summary.exerciseCalories.toStringAsFixed(0)} kcal\n'
        '${deficit > 0 ? '🔥' : '⚠️'} 热量${deficit > 0 ? '缺口' : '盈余'}: ${deficit.abs().toStringAsFixed(0)} kcal\n'
        '目标缺口: ${targetDeficit.toStringAsFixed(0)} kcal\n'
        '状态: $status';
  }

  static String _generateNutritionAnalysis(DailySummary summary) {
    final ratios = CalorieCalculator.calculateNutritionRatio(
      carbsGrams: summary.totalCarbs,
      proteinGrams: summary.totalProtein,
      fatGrams: summary.totalFat,
    );
    
    final recommended = CalorieCalculator.getRecommendedRatios();
    
    return '🥗 **营养分析**\n'
        '碳水: ${summary.totalCarbs.toStringAsFixed(1)}g (${ratios['carbs']!.toStringAsFixed(0)}%)\n'
        '蛋白质: ${summary.totalProtein.toStringAsFixed(1)}g (${ratios['protein']!.toStringAsFixed(0)}%)\n'
        '脂肪: ${summary.totalFat.toStringAsFixed(1)}g (${ratios['fat']!.toStringAsFixed(0)}%)\n'
        '推荐比例: 碳水${recommended['carbs']!.toStringAsFixed(0)}% / 蛋白质${recommended['protein']!.toStringAsFixed(0)}% / 脂肪${recommended['fat']!.toStringAsFixed(0)}%';
  }

  static String _generateDietAdvice(DailySummary summary, UserSetting userSettings) {
    final advices = <String>[];
    
    final proteinPerKg = userSettings.weight > 0 
        ? summary.totalProtein / userSettings.weight 
        : 0.0;
    
    if (proteinPerKg < 1.0 && summary.totalCaloriesIntake > 0) {
      advices.add('⚠️ 蛋白质摄入不足(${proteinPerKg.toStringAsFixed(1)}g/kg)，建议增加鸡胸肉、鸡蛋、鱼虾');
    } else if (proteinPerKg >= 1.6 && summary.totalCaloriesIntake > 0) {
      advices.add('✅ 蛋白质摄入充足');
    }
    
    if (summary.totalCaloriesIntake < 800 && summary.totalCaloriesIntake > 0) {
      advices.add('⚠️ 摄入过低(<800kcal)，过度节食影响代谢和健康');
    } else if (summary.totalCaloriesIntake > 2500) {
      advices.add('⚠️ 摄入偏高，注意控制份量');
    }
    
    final ratios = CalorieCalculator.calculateNutritionRatio(
      carbsGrams: summary.totalCarbs,
      proteinGrams: summary.totalProtein,
      fatGrams: summary.totalFat,
    );
    
    if (ratios['carbs']! > 55 && summary.totalCaloriesIntake > 0) {
      advices.add('⚠️ 碳水比例偏高，建议减少主食或选粗粮');
    }
    if (ratios['fat']! > 40 && summary.totalCaloriesIntake > 0) {
      advices.add('⚠️ 脂肪比例偏高，注意控油');
    }
    
    if (advices.isEmpty) {
      advices.add('✅ 今日饮食结构良好，继续保持！');
    }
    
    return '🍽️ **饮食建议**\n' + advices.join('\n');
  }

  static String _generateExerciseAdvice(DailySummary summary) {
    if (summary.exerciseCalories < 100) {
      return '🏋️ **运动建议**\n'
          '🏃 今日运动量较少，建议30分钟有氧运动（快走/慢跑/骑行）\n'
          '💪 下午运动效果最佳，提高代谢率';
    } else if (summary.exerciseCalories < 300) {
      return '🏋️ **运动建议**\n'
          '🚶 运动量适中，可尝试增加10-15分钟HIIT加强燃脂';
    } else {
      return '🏋️ **运动建议**\n✅ 运动量充足，注意补水和拉伸';
    }
  }

  static String _generateTomorrowSuggestion(
    DailySummary summary, 
    double targetDeficit,
    UserSetting userSettings,
  ) {
    final bmr = CalorieCalculator.calculateBMR(
      weightKg: userSettings.weight,
      heightCm: userSettings.height,
      age: userSettings.age,
      gender: userSettings.gender,
    );
    
    final targetIntake = CalorieCalculator.calculateTargetCalories(
      bmr: bmr,
      targetDeficitPerDay: targetDeficit,
    );
    
    final suggestedCarbs = (targetIntake * 0.35 / 4).toStringAsFixed(0);
    final suggestedProtein = (targetIntake * 0.40 / 4).toStringAsFixed(0);
    final suggestedFat = (targetIntake * 0.25 / 9).toStringAsFixed(0);
    
    return '📋 **明日计划建议**\n'
        '目标摄入: ${targetIntake.toStringAsFixed(0)} kcal\n'
        '建议碳水: ${suggestedCarbs}g | 蛋白质: ${suggestedProtein}g | 脂肪: ${suggestedFat}g\n'
        '推荐运动: ${summary.exerciseCalories < 100 ? '30分钟有氧 + 15分钟力量' : '维持今日水平或增加强度'}\n'
        '💡 坚持记录7天，建议会更精准！';
  }
}
