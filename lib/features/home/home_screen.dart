import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/meal_type.dart';
import '../../providers/database_provider.dart';
import '../../providers/today_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final deficitAsync = ref.watch(todayDeficitProvider);
    final totalBurnedAsync = ref.watch(todayTotalBurnedProvider);
    final intakeAsync = ref.watch(todayCaloriesIntakeProvider);
    final exerciseAsync = ref.watch(todayExerciseCaloriesProvider);
    final mealCalAsync = ref.watch(mealCaloriesProvider);
    final summaryAsync = ref.watch(todaySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日概览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(todaySummaryProvider);
              ref.invalidate(todayExerciseRecordsProvider);
              ref.invalidate(todayMealRecordsProvider);
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildEmptyState(context, ref, '加载失败: $e'),
        data: (settings) {
          if (settings == null) {
            return _buildEmptyState(context, ref, '请先完成初始设置');
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todaySummaryProvider);
              ref.invalidate(todayMealRecordsProvider);
              ref.invalidate(todayExerciseRecordsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeficitCard(context, deficitAsync, settings),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildBurnedCard(context, totalBurnedAsync, exerciseAsync)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildIntakeCard(context, intakeAsync, mealCalAsync)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMealSummary(context, mealCalAsync),
                  const SizedBox(height: 16),
                  _buildSummarySection(context, ref, settings, summaryAsync),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _switchToSettingsTab(ref),
            icon: const Icon(Icons.settings),
            label: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _switchToSettingsTab(WidgetRef ref) {
    // 底部导航 index 4 是设置页
  }

  Widget _buildDeficitCard(BuildContext context, AsyncValue<double> deficitAsync, UserSetting settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('每日热量缺口', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            deficitAsync.when(
              loading: () => const SizedBox(height: 32, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const Text('0', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              data: (deficit) {
                final isPositive = deficit >= 0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      deficit.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text('kcal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              '目标缺口: ${settings.targetCalorieDeficit.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnedCard(BuildContext context, AsyncValue<double> totalBurnedAsync, AsyncValue<double> exerciseAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: AppTheme.exerciseColor, size: 20),
                const SizedBox(width: 4),
                const Text('总消耗', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            totalBurnedAsync.when(
              loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              data: (val) => Text(
                val.toStringAsFixed(0),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            exerciseAsync.when(
              data: (val) => Text('运动: ${val.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakeCard(BuildContext context, AsyncValue<double> intakeAsync, AsyncValue<Map<String, double>> mealCalAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, color: AppTheme.dietColor, size: 20),
                const SizedBox(width: 4),
                const Text('总摄入', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            intakeAsync.when(
              loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              data: (val) => Text(
                val.toStringAsFixed(0),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            mealCalAsync.when(
              data: (meals) {
                final breakfast = meals['breakfast'] ?? 0;
                final lunch = meals['lunch'] ?? 0;
                final dinner = meals['dinner'] ?? 0;
                return Text(
                  '早${breakfast.toStringAsFixed(0)} 午${lunch.toStringAsFixed(0)} 晚${dinner.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSummary(BuildContext context, AsyncValue<Map<String, double>> mealCalAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('各餐热量', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            mealCalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Text('暂无数据'),
              data: (meals) => Column(
                children: MealType.allTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(MealType.getIcon(type), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(MealType.getLabel(type), style: const TextStyle(fontSize: 15)),
                      ),
                      Text(
                        '${(meals[type] ?? 0).toStringAsFixed(0)} kcal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: (meals[type] ?? 0) > 0 ? AppTheme.primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context, 
    WidgetRef ref, 
    UserSetting settings,
    AsyncValue<DailySummary?> summaryAsync,
  ) {
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildGenerateSummaryButton(context, ref, settings),
      data: (summary) {
        if (summary == null || summary.suggestionGenerated == 0) {
          return _buildGenerateSummaryButton(context, ref, settings);
        }
        return _buildSummaryCard(context, summary);
      },
    );
  }

  Widget _buildGenerateSummaryButton(BuildContext context, WidgetRef ref, UserSetting settings) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await saveDailySummary(ref, DateTime.now());
          ref.invalidate(todaySummaryProvider);
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('生成每日总结与建议'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, DailySummary summary) {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('今日总结', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (summary.suggestionGenerated == 1)
                  const Text('✅ 已生成', style: TextStyle(fontSize: 12, color: AppTheme.success)),
              ],
            ),
            const Divider(),
            if (summary.suggestion.isNotEmpty)
              Text(
                summary.suggestion,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
          ],
        ),
      ),
    );
  }
}
