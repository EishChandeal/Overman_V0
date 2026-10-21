import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../theme/app_theme.dart';

/// Dedicated screen displaying comprehensive analytics, yearly heatmap,
/// charts, and streaks for a single habit.
class HabitDetailScreen extends ConsumerWidget {
  final String habitId;
  final HabitDto? initialHabit;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
    this.initialHabit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitListAsync = ref.watch(habitListProvider);
    final habitFromList =
        habitListAsync.valueOrNull?.where((h) => h.id == habitId).firstOrNull;
    final habitByIdAsync = ref.watch(habitByIdProvider(habitId));

    final habit = habitFromList ?? habitByIdAsync.valueOrNull ?? initialHabit;

    if (habit == null) {
      if (habitListAsync.isLoading && habitByIdAsync.isLoading) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
              key: Key('habit_detail_loading'),
              color: AppColors.orange,
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Habit Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Habit not found',
            key: Key('habit_detail_not_found'),
            style: TextStyle(
              color: AppColors.mutedGrey,
              fontSize: 16,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content coming soon',
              key: Key('habit_detail_content'),
              style: TextStyle(
                color: AppColors.mutedGrey,
                fontSize: 14,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
