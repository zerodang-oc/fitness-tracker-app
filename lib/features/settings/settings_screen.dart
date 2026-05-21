import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';

/// 初始设置 / 个人设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _gender = 'male';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  double _activityLevel = 1.375;
  double _targetDeficit = 300;
  bool _isSaving = false;
  bool _isInitialSetup = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = await ref.read(databaseProvider.future);
    final settings = db.getUserSettings();
    if (settings != null) {
      _gender = settings.gender;
      _ageController.text = settings.age.toStringAsFixed(0);
      _heightController.text = settings.height.toStringAsFixed(1);
      _weightController.text = settings.weight.toStringAsFixed(1);
      _activityLevel = settings.activityLevel;
      _targetDeficit = settings.targetCalorieDeficit;
    } else {
      _isInitialSetup = true;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInitialSetup ? '初始设置' : '个人设置'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 性别
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('性别', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _genderChip('male', '♂ 男性'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _genderChip('female', '♀ 女性'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 基本信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: '年龄'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 10 || n > 120) return '请输入有效年龄(10-120)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: '身高', suffixText: 'cm'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 100 || n > 250) return '请输入有效身高(100-250cm)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: '体重', suffixText: 'kg'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 30 || n > 250) return '请输入有效体重(30-250kg)';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 活动水平
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('活动水平', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      _activityLevelLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _activityLevel,
                      min: 1.2,
                      max: 1.9,
                      divisions: 7,
                      label: _activityLevelLabel,
                      onChanged: (v) => setState(() => _activityLevel = v),
                    ),
                    _activityLevelRow(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 目标热量缺口
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('目标热量缺口', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '每天${_targetDeficit.toStringAsFixed(0)} kcal缺口',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _targetDeficit,
                      min: 100,
                      max: 800,
                      divisions: 14,
                      label: '${_targetDeficit.toStringAsFixed(0)} kcal',
                      onChanged: (v) => setState(() => _targetDeficit = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('温和 100', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text('推荐 300-500', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                        Text('激进 800', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isInitialSetup ? '开始使用' : '保存设置'),
              ),
            ),
            const SizedBox(height: 12),

            // 数据管理
            if (!_isInitialSetup) ...[
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
                onTap: () => _confirmClearData(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.blue : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  String get _activityLevelLabel {
    switch (_activityLevel.roundToDouble()) {
      case 1.2: return '久坐（很少运动）';
      case 1.375: return '轻度运动（每周1-3天）';
      case 1.55: return '中度运动（每周3-5天）';
      case 1.725: return '高度运动（每周6-7天）';
      case 1.9: return '极大运动量（体力劳动者）';
      default: return '当前: $_activityLevel';
    }
  }

  Widget _activityLevelRow() {
    final levels = [1.2, 1.375, 1.55, 1.725, 1.9];
    final labels = ['久坐', '轻度', '中度', '高度', '极高'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(levels.length, (i) {
        final selected = _activityLevel == levels[i];
        return GestureDetector(
          onTap: () => setState(() => _activityLevel = levels[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? Colors.blue.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.blue : Colors.transparent,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(databaseProvider.future);
      db.saveUserSettings(UserSetting(
        gender: _gender,
        age: double.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        activityLevel: _activityLevel,
        targetCalorieDeficit: _targetDeficit,
      ));

      ref.invalidate(userSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
        if (_isInitialSetup) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除所有数据？'),
        content: const Text('此操作不可恢复，将清除所有运动、饮食记录和个人设置。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await ref.read(databaseProvider.future);
              db.clearAllData();
              ref.invalidate(userSettingsProvider);
              ref.invalidate(todayExerciseRecordsProvider);
              ref.invalidate(todayMealRecordsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清除')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
