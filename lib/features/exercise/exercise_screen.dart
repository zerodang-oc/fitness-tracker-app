import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/meal_type.dart';
import '../../providers/database_provider.dart';
import '../../core/database/tables.dart';

/// 运动记录页面
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(todayExerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncFromHuawei(context, ref),
            tooltip: '从华为运动健康同步',
          ),
        ],
      ),
      body: exerciseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('暂无运动记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '点击右上角 + 手动添加\n或点击同步按钮从华为健康导入',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Text(
                      ExerciseType.getIcon(record.exerciseType),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    ExerciseType.getLabel(record.exerciseType),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${record.durationMinutes.toStringAsFixed(0)}分钟 · '
                    '${record.distance != null ? '${record.distance!.toStringAsFixed(1)}km · ' : ''}'
                    '${record.heartRateAvg != null ? '♥${record.heartRateAvg}bpm · ' : ''}'
                    '${record.source == 'huawei' ? '华为同步' : '手动'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${record.caloriesBurned.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddExerciseSheet(ref: ref),
    );
  }

  void _syncFromHuawei(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('华为运动健康同步'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将从华为运动健康同步今日的运动数据和体重数据。'),
            SizedBox(height: 12),
            Text('功能开发中，当前使用模拟数据...', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 模拟同步
              final db = await ref.read(databaseProvider.future);
              await _simulateHuaweiSync(ref);
              ref.invalidate(todayExerciseRecordsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已模拟同步运动数据')),
                );
              }
            },
            child: const Text('模拟同步'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateHuaweiSync(WidgetRef ref) async {
    final now = DateTime.now();
    await AppDatabase.addExerciseRecord(ExerciseRecord(
      exerciseType: ExerciseType.walking,
      durationMinutes: 30,
      caloriesBurned: 120,
      distance: 2.5,
      startTime: now,
      source: 'huawei',
    ));
  }
}

class _AddExerciseSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddExerciseSheet({required this.ref});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  String _selectedType = ExerciseType.running;
  final _durationController = TextEditingController(text: '30');
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _heartRateController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('添加运动', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),

          // 运动类型选择
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseType.allTypes.map((type) {
              final selected = _selectedType == type;
              return ChoiceChip(
                label: Text('${ExerciseType.getIcon(type)} ${ExerciseType.getLabel(type)}'),
                selected: selected,
                onSelected: (v) {
                  setState(() => _selectedType = type);
                  // 自动估算热量
                  if (_durationController.text.isNotEmpty) {
                    _estimateCalories();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 时长
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: '运动时长（分钟）',
              suffixText: '分钟',
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _estimateCalories(),
          ),
          const SizedBox(height: 12),

          // 距离
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(
              labelText: '距离（可选）',
              suffixText: 'km',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // 消耗
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: '消耗卡路里',
              suffixText: 'kcal',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // 心率
          TextField(
            controller: _heartRateController,
            decoration: const InputDecoration(
              labelText: '平均心率（可选）',
              suffixText: 'bpm',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  void _estimateCalories() {
    final duration = double.tryParse(_durationController.text);
    if (duration == null || duration <= 0) return;

    // 粗略估算: MET * 体重(估算70kg) * 时长(h)
    final met = ExerciseType.getMetValue(_selectedType);
    final estimatedCalories = met * 70 * (duration / 60);
    _caloriesController.text = estimatedCalories.toStringAsFixed(0);
  }

  Future<void> _save() async {
    final duration = double.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的运动时长')),
      );
      return;
    }

    final calories = double.tryParse(_caloriesController.text) ?? 0;
    if (calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入或等待自动估算卡路里')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await widget.ref.read(databaseProvider.future);
      await AppDatabase.addExerciseRecord(ExerciseRecord(
        exerciseType: _selectedType,
        durationMinutes: duration,
        caloriesBurned: calories,
        distance: double.tryParse(_distanceController.text),
        heartRateAvg: int.tryParse(_heartRateController.text),
        startTime: DateTime.now(),
        source: 'manual',
      ));

      widget.ref.invalidate(todayExerciseRecordsProvider);
      widget.ref.invalidate(todayExerciseCaloriesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('运动记录已保存')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }
}
