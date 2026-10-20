import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Screen for creating or editing a habit or one-time task (Boolean or Numeric).
class AddHabitScreen extends ConsumerStatefulWidget {
  final HabitDto? habitToEdit;
  final HabitScheduleDto? scheduleToEdit;

  const AddHabitScreen({
    super.key,
    this.habitToEdit,
    this.scheduleToEdit,
  });

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _targetValueController = TextEditingController();

  bool _isOneTime = false;
  HabitType _habitType = HabitType.boolean;
  ScheduleType _scheduleType = ScheduleType.daily;
  final Set<Weekday> _selectedWeekdays = {
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
  };
  int _targetCount = 3;

  String _selectedColorHex = '#216CCF';
  String _selectedIconName = 'check';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      final h = widget.habitToEdit!;
      _nameController.text = h.name;
      _isOneTime = h.isOneTime;
      _habitType = h.type;
      _unitController.text = h.unit ?? '';
      if (h.targetValue != null) {
        final tv = h.targetValue!;
        _targetValueController.text =
            tv == tv.roundToDouble() ? tv.toInt().toString() : tv.toString();
      }
      _selectedColorHex = h.colorHex;
      _selectedIconName = h.iconName;

      if (widget.scheduleToEdit != null) {
        final s = widget.scheduleToEdit!;
        _scheduleType = s.scheduleType;
        if (s.scheduledWeekdays != null) {
          _selectedWeekdays
            ..clear()
            ..addAll(s.scheduledWeekdays!);
        }
        if (s.targetCount != null) {
          _targetCount = s.targetCount!;
        }
      }
    }
  }

  final List<String> _palette = const [
    '#216CCF', // Blue (brand)
    '#FF7A45', // Orange (brand)
    '#34D399', // Emerald
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#38BDF8', // Sky Blue
  ];

  final List<Map<String, dynamic>> _icons = const [
    {'name': 'check', 'icon': Icons.check_circle_outline},
    {'name': 'fitness', 'icon': Icons.fitness_center},
    {'name': 'run', 'icon': Icons.directions_run},
    {'name': 'water', 'icon': Icons.water_drop_outlined},
    {'name': 'book', 'icon': Icons.menu_book_outlined},
    {'name': 'meditation', 'icon': Icons.self_improvement},
    {'name': 'sleep', 'icon': Icons.bedtime_outlined},
    {'name': 'code', 'icon': Icons.code},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = await ref.read(habitRepositoryProvider.future);

      final double? targetVal = _habitType == HabitType.numeric
          ? double.tryParse(_targetValueController.text.trim())
          : null;
      final String? unitVal = _habitType == HabitType.numeric
          ? _unitController.text.trim()
          : null;

      if (widget.habitToEdit != null) {
        final updatedHabit = widget.habitToEdit!.copyWith(
          name: _nameController.text.trim(),
          type: _habitType,
          unit: unitVal,
          targetValue: targetVal,
          colorHex: _selectedColorHex,
          iconName: _selectedIconName,
          isOneTime: _isOneTime,
        );
        await repo.updateHabit(updatedHabit);

        if (!_isOneTime) {
          final scheduleRepo = await ref.read(habitScheduleRepositoryProvider.future);
          await scheduleRepo.setSchedule(
            habitId: widget.habitToEdit!.id,
            scheduleType: _scheduleType,
            scheduledWeekdays: _scheduleType == ScheduleType.specificWeekdays
                ? _selectedWeekdays.toList()
                : null,
            targetCount: _scheduleType == ScheduleType.timesPerWeek ||
                    _scheduleType == ScheduleType.timesPerMonth
                ? _targetCount
                : null,
            effectiveFrom: DateTime.now().toUtc(),
          );
        }

        // Invalidate dashboard and streak providers so Home and panels update
        ref.invalidate(todayDashboardProvider);
        ref.invalidate(habitListProvider);
        ref.invalidate(habitStreakProvider(widget.habitToEdit!.id));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Updated ${_isOneTime ? "task" : "habit"} "${_nameController.text.trim()}"',
              ),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        await repo.createHabit(
          name: _nameController.text.trim(),
          type: _habitType,
          unit: unitVal,
          targetValue: targetVal,
          colorHex: _selectedColorHex,
          iconName: _selectedIconName,
          scheduleType: _isOneTime ? ScheduleType.daily : _scheduleType,
          scheduledWeekdays: !_isOneTime && _scheduleType == ScheduleType.specificWeekdays
              ? _selectedWeekdays.toList()
              : null,
          targetCount: !_isOneTime && (_scheduleType == ScheduleType.timesPerWeek ||
                  _scheduleType == ScheduleType.timesPerMonth)
              ? _targetCount
              : null,
          isOneTime: _isOneTime,
        );

        // Invalidate dashboard provider so Home updates immediately
        ref.invalidate(todayDashboardProvider);
        ref.invalidate(habitListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Created ${_isOneTime ? "task" : "habit"} "${_nameController.text.trim()}"',
              ),
              backgroundColor: AppColors.surface,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = HabitVisuals.parseColor(_selectedColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.habitToEdit != null
              ? (_isOneTime ? 'Edit Task' : 'Edit Habit')
              : (_isOneTime ? 'New One-time Task' : 'New Habit'),
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 0. Segmented Toggle (Habit vs One-time Task)
              _buildTypeToggle(habitColor),

              const SizedBox(height: 12),

              // 1. Habit/Task Name
              _buildSectionLabel(_isOneTime ? 'TASK NAME' : 'HABIT NAME'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontFamily: AppTheme.fontPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _isOneTime
                      ? 'e.g. Finish Tax Forms, Pick up parcel'
                      : 'e.g. Read 20 pages, Morning Jog',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return _isOneTime
                        ? 'Please enter a task name'
                        : 'Please enter a habit name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 2. Tracking Type (Checkmark vs Numeric)
              _buildSectionLabel('TRACKING TYPE'),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      title: 'Checkmark',
                      subtitle: 'Yes / No completion',
                      icon: Icons.check_circle_outline,
                      isSelected: _habitType == HabitType.boolean,
                      onTap: () => setState(() => _habitType = HabitType.boolean),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      title: 'Numeric',
                      subtitle: 'Target count or unit',
                      icon: Icons.numbers_outlined,
                      isSelected: _habitType == HabitType.numeric,
                      onTap: () => setState(() => _habitType = HabitType.numeric),
                    ),
                  ),
                ],
              ),

              // 3. Numeric Fields (if numeric)
              if (_habitType == HabitType.numeric) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('TARGET VALUE'),
                          TextFormField(
                            controller: _targetValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. 10000',
                            ),
                            validator: (val) {
                              if (_habitType == HabitType.numeric) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter target';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Invalid number';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('UNIT'),
                          TextFormField(
                            controller: _unitController,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. steps, ml, pages',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // 4. Schedule Type (Animated collapse for one-time task)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isOneTime
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildSectionLabel('SCHEDULE'),
                          _buildScheduleSelector(),
                          if (_scheduleType == ScheduleType.specificWeekdays) ...[
                            const SizedBox(height: 12),
                            _buildWeekdaySelector(),
                          ],
                          if (_scheduleType == ScheduleType.timesPerWeek) ...[
                            const SizedBox(height: 12),
                            _buildTimesPerWeekSelector(),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // 5. Color Accent Selection
              _buildSectionLabel('COLOR ACCENT'),
              _buildColorSelector(),

              const SizedBox(height: 24),

              // 6. Icon Selection
              _buildSectionLabel('ICON'),
              _buildIconSelector(),

              const SizedBox(height: 36),

              // 7. Save / Create Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.controlText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.controlText,
                          ),
                        )
                      : Text(
                          widget.habitToEdit != null
                              ? 'Save Changes'
                              : (_isOneTime ? 'Create Task' : 'Create Habit'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontPrimary,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(Color accentColor) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOneTime = false),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isOneTime ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Habit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_isOneTime
                        ? HabitVisuals.getOnColor(accentColor)
                        : AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOneTime = true),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isOneTime ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'One-time Task',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isOneTime
                        ? HabitVisuals.getOnColor(accentColor)
                        : AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedGrey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontFamily: AppTheme.fontPrimary,
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.blue : AppColors.mutedGrey,
                size: 26,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryText : AppColors.mutedGrey,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSelector() {
    final options = [
      {'type': ScheduleType.daily, 'label': 'Daily'},
      {'type': ScheduleType.specificWeekdays, 'label': 'Specific days'},
      {'type': ScheduleType.timesPerWeek, 'label': 'Times / week'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final type = opt['type'] as ScheduleType;
        final label = opt['label'] as String;
        final isSelected = _scheduleType == type;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _scheduleType = type),
          selectedColor: AppColors.blue,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.controlText : AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: AppTheme.fontPrimary,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.blue : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekdaySelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: Weekday.values.map((day) {
          final isSelected = _selectedWeekdays.contains(day);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  if (_selectedWeekdays.length > 1) {
                    _selectedWeekdays.remove(day);
                  }
                } else {
                  _selectedWeekdays.add(day);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  day.shortName[0],
                  style: TextStyle(
                    color: isSelected ? AppColors.controlText : AppColors.primaryText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimesPerWeekSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_targetCount times per week',
            style: const TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.mutedGrey),
                onPressed: _targetCount > 1
                    ? () => setState(() => _targetCount--)
                    : null,
              ),
              Text(
                '$_targetCount',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.orange),
                onPressed: _targetCount < 7
                    ? () => setState(() => _targetCount++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _palette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final hex = _palette[index];
          final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
          final isSelected = _selectedColorHex == hex;

          return GestureDetector(
            onTap: () => setState(() => _selectedColorHex = hex),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconSelector() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _icons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _icons[index];
          final name = item['name'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = _selectedIconName == name;

          return GestureDetector(
            onTap: () => setState(() => _selectedIconName = name),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.blue : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.controlText : AppColors.primaryText,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
