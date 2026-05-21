import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/meal_type.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../providers/database_provider.dart';
import '../../providers/today_providers.dart';
import '../../core/database/tables.dart';

/// 分析与报告页面
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(todaySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${date.month}月${date.day}日 分析'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 热量缺口可视化
            _buildDeficitChart(context, ref),
            const SizedBox(height: 16),

            // 营养分析
            _buildNutritionAnalysis(context, ref),
            const SizedBox(height: 16),

            // 各餐热量分布
            _buildMealDistribution(context, ref),
            const SizedBox(height: 16),

            // 建议
            summaryAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (DailySummary? summary) {
                if (summary == null || summary.suggestion.isEmpty) return const SizedBox();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text('详细建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          summary.suggestion,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeficitChart(BuildContext context, WidgetRef ref) {
    final deficitAsync = ref.watch(todayDeficitProvider);
    final totalBurnedAsync = ref.watch(todayTotalBurnedProvider);
    final intakeAsync = ref.watch(todayCaloriesIntakeProvider);
    final settingsAsync = ref.watch(userSettingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('热量平衡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: deficitAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('暂无数据')),
                data: (deficit) {
                  return Row(
                    children: [
                      // 条形图
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBar('消耗', totalBurnedAsync, AppTheme.exerciseColor),
                              const SizedBox(height: 12),
                              _buildBar('摄入', intakeAsync, AppTheme.dietColor),
                              const SizedBox(height: 12),
                              _buildBar(
                                '缺口',
                                AsyncValue.data(deficit),
                                deficit >= 0 ? AppTheme.success : AppTheme.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 饼图
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: totalBurnedAsync.when(
                          data: (burned) => intakeAsync.when(
                            data: (intake) {
                              final total = burned + intake;
                              if (total <= 0) return const Center(child: Text('无数据'));
                              return PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: burned.clamp(0, total),
                                      title: '消耗\n${((burned / total) * 100).toStringAsFixed(0)}%',
                                      color: AppTheme.exerciseColor,
                                      radius: 50,
                                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: intake.clamp(0, total),
                                      title: '摄入\n${((intake / total) * 100).toStringAsFixed(0)}%',
                                      color: AppTheme.dietColor,
                                      radius: 50,
                                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 20,
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (settingsAsync.valueOrNull != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '目标缺口: ${settingsAsync.valueOrNull!.targetCalorieDeficit.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, AsyncValue<double> valueAsync, Color color) {
    return valueAsync.when(
      loading: () => const SizedBox(height: 36),
      error: (_, __) => SizedBox(
        height: 36,
        child: Row(
          children: [
            SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12))),
            Expanded(child: Container()),
            const Text('-', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      data: (value) {
        return SizedBox(
          height: 36,
          child: Row(
            children: [
              SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (value / 3000).clamp(0, 1),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(
                  '${value.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionAnalysis(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealRecordsProvider);
    final settingsAsync = ref.watch(userSettingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('营养素分析', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            mealsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('暂无数据')),
              data: (List<MealRecord> meals) {
                final totalCarbs = meals.fold<double>(0, (s, m) => s + m.totalCarbs);
                final totalProtein = meals.fold<double>(0, (s, m) => s + m.totalProtein);
                final totalFat = meals.fold<double>(0, (s, m) => s + m.totalFat);
                final total = totalCarbs + totalProtein + totalFat;
                if (total <= 0) return const Center(child: Text('暂无营养数据'));

                final ratios = CalorieCalculator.calculateNutritionRatio(
                  carbsGrams: totalCarbs,
                  proteinGrams: totalProtein,
                  fatGrams: totalFat,
                );

                return Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: totalCarbs.clamp(0, total),
                              title: '碳水\n${ratios['carbs']!.toStringAsFixed(0)}%',
                              color: Colors.brown,
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              value: totalProtein.clamp(0, total),
                              title: '蛋白\n${ratios['protein']!.toStringAsFixed(0)}%',
                              color: Colors.red.shade300,
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            PieChartSectionData(
                              value: totalFat.clamp(0, total),
                              title: '脂肪\n${ratios['fat']!.toStringAsFixed(0)}%',
                              color: Colors.orange.shade400,
                              radius: 60,
                              titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _nutrientLegend(Colors.brown, '碳水', '${totalCarbs.toStringAsFixed(1)}g', '${ratios['carbs']!.toStringAsFixed(0)}%'),
                        _nutrientLegend(Colors.red.shade300, '蛋白', '${totalProtein.toStringAsFixed(1)}g', '${ratios['protein']!.toStringAsFixed(0)}%'),
                        _nutrientLegend(Colors.orange.shade400, '脂肪', '${totalFat.toStringAsFixed(1)}g', '${ratios['fat']!.toStringAsFixed(0)}%'),
                      ],
                    ),
                    if (settingsAsync.valueOrNull != null) ...[
                      const Divider(height: 24),
                      Text(
                        '推荐: 碳水35% / 蛋白40% / 脂肪25% (减脂模式)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientLegend(Color color, String label, String grams, String percent) {
    return Column(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(grams, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(percent, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMealDistribution(BuildContext context, WidgetRef ref) {
    final mealCalAsync = ref.watch(mealCaloriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('各餐热量分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            mealCalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('暂无数据')),
              data: (meals) {
                final total = meals.values.fold<double>(0, (s, v) => s + v);
                if (total <= 0) return const Center(child: Text('暂无餐食记录'));

                return Column(
                  children: [
                    // 水平条形图
                    ...['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                      final cal = meals[type] ?? 0;
                      final pct = total > 0 ? (cal / total * 100) : 0.0;
                      final color = _mealColor(type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${MealType.getIcon(type)} ${MealType.getLabel(type)}', style: const TextStyle(fontSize: 13)),
                                const Spacer(),
                                Text('${cal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Text('(${pct.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('合计', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${total.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _mealColor(String type) {
    switch (type) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return Colors.green;
      case 'dinner': return Colors.indigo;
      case 'snack': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
