import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/meal_type.dart';
import '../../providers/database_provider.dart';
import '../../core/database/tables.dart';

/// 添加餐食页面 - 支持拍照识别和手动录入
class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  String _mealType = MealType.breakfast;
  final _foodItems = <_FoodItemEntry>[];
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加餐食'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMeal,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 餐食类型选择
            _buildMealTypeSelector(),
            const SizedBox(height: 16),

            // 拍照识别
            _buildPhotoSection(),
            const SizedBox(height: 16),

            // 食物列表
            ..._buildFoodItems(),
            const SizedBox(height: 12),

            // 添加食物按钮
            OutlinedButton.icon(
              onPressed: _addFoodItem,
              icon: const Icon(Icons.add),
              label: const Text('添加食物'),
            ),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '如：食堂、外卖品牌等',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // 营养汇总
            _buildNutritionSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Row(
      children: [
        ...MealType.allTypes.map((type) {
          final selected = _mealType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${MealType.getIcon(type)} ${MealType.getLabel(type)}'),
              selected: selected,
              onSelected: (v) => setState(() => _mealType = type),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade50,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  '拍照识别食物',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '拍照后AI自动识别食物和营养',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _isLoading = true);
      try {
        // TODO: 调用火山引擎豆包视觉识别API
        // 模拟识别结果
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _foodItems.addAll([
            _FoodItemEntry(
              name: '模拟识别 - 白米饭',
              amount: 200,
              calories: 232,
              carbs: 51.8,
              fat: 0.6,
              protein: 5.2,
            ),
            _FoodItemEntry(
              name: '模拟识别 - 鸡胸肉',
              amount: 150,
              calories: 250,
              carbs: 0,
              fat: 5.4,
              protein: 48,
            ),
          ]);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('识别完成，请核对并调整份量')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('识别失败: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Widget> _buildFoodItems() {
    if (_foodItems.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('还没有食物', style: TextStyle(color: Colors.grey.shade500)),
                  Text('点击上方"拍照识别"或"添加食物"', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return _foodItems.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.amount}g · ${item.calories}kcal · 碳水${item.carbs}g · 蛋白${item.protein}g · 脂肪${item.fat}g',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editFoodItem(idx),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                onPressed: () => setState(() => _foodItems.removeAt(idx)),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addFoodItem() {
    setState(() {
      _foodItems.add(_FoodItemEntry(
        name: '',
        amount: 100,
        calories: 0,
        carbs: 0,
        fat: 0,
        protein: 0,
      ));
    });
    _editFoodItem(_foodItems.length - 1);
  }

  void _editFoodItem(int index) {
    // TODO: 弹出编辑食物对话框
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑食物'),
        content: const Text('食物编辑功能开发中'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final totalCal = _foodItems.fold<double>(0, (s, i) => s + i.calories);
    final totalCarbs = _foodItems.fold<double>(0, (s, i) => s + i.carbs);
    final totalProtein = _foodItems.fold<double>(0, (s, i) => s + i.protein);
    final totalFat = _foodItems.fold<double>(0, (s, i) => s + i.fat);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('营养汇总', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _nutrientChip('🔥 热量', '${totalCal.toStringAsFixed(0)} kcal', Colors.orange),
                const SizedBox(width: 8),
                _nutrientChip('🌾 碳水', '${totalCarbs.toStringAsFixed(1)}g', Colors.brown),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _nutrientChip('🥩 蛋白', '${totalProtein.toStringAsFixed(1)}g', Colors.red.shade300),
                const SizedBox(width: 8),
                _nutrientChip('🧈 脂肪', '${totalFat.toStringAsFixed(1)}g', Colors.yellow.shade700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (_foodItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一种食物')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(databaseProvider.future);
      final totalCal = _foodItems.fold<double>(0, (s, i) => s + i.calories);
      final totalCarbs = _foodItems.fold<double>(0, (s, i) => s + i.carbs);
      final totalProtein = _foodItems.fold<double>(0, (s, i) => s + i.protein);
      final totalFat = _foodItems.fold<double>(0, (s, i) => s + i.fat);

      // 保存餐食主记录
      final mealId = await AppDatabase.addMealRecord(MealRecord(
        mealType: _mealType,
        eatenAt: DateTime.now(),
        totalCalories: totalCal,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        totalProtein: totalProtein,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      ));

      // 保存餐食明细
      AppDatabase.addMealItems(
        _foodItems.map((item) => MealItem(
          mealId: mealId,
          foodName: item.name,
          amount: item.amount,
          calories: item.calories,
          carbs: item.carbs,
          fat: item.fat,
          protein: item.protein,
        )).toList(),
      );

      // 刷新数据
      ref.invalidate(todayMealRecordsProvider);
      ref.invalidate(todayCaloriesIntakeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${MealType.getLabel(_mealType)}已保存')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _FoodItemEntry {
  final String name;
  final double amount;
  final double calories;
  final double carbs;
  final double fat;
  final double protein;

  _FoodItemEntry({
    required this.name,
    required this.amount,
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.protein,
  });
}


