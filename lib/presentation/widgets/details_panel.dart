import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Panel displaying configuration details and start date for a habit.
class DetailsPanel extends StatelessWidget {
  final HabitDto habit;
  final Color? habitColor;
  final HabitScheduleDto? activeSchedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DetailsPanel({
    super.key,
    required this.habit,
    this.habitColor,
    this.activeSchedule,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdFormatted = DateFormat('d MMMM yyyy').format(habit.createdAt.toLocal());
    final scheduleLabel = activeSchedule?.scheduleType.displayName ?? 'Daily';
    final accentColor = habitColor ?? HabitVisuals.parseColor(habit.colorHex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            title: 'Start Date',
            value: createdFormatted,
            iconColor: accentColor,
          ),
          const Divider(color: AppColors.surface, height: 18),
          _buildDetailRow(
            icon: habit.isOneTime ? Icons.task_alt : Icons.repeat,
            title: habit.isOneTime ? 'Task Type' : 'Schedule',
            value: habit.isOneTime ? 'One-time Task' : scheduleLabel,
            iconColor: accentColor,
          ),
          if (habit.isOneTime && habit.completedAt != null) ...[
            const Divider(color: AppColors.surface, height: 18),
            _buildDetailRow(
              icon: Icons.check_circle_outline,
              title: 'Completed',
              value: DateFormat('d MMMM yyyy, HH:mm').format(habit.completedAt!.toLocal()),
              iconColor: accentColor,
            ),
          ],
          const Divider(color: AppColors.surface, height: 18),
          _buildDetailRow(
            icon: habit.type == HabitType.boolean
                ? Icons.check_circle_outline
                : Icons.numbers_outlined,
            title: 'Tracking Type',
            value: habit.type == HabitType.boolean
                ? 'Checkmark (Yes / No)'
                : 'Numeric (${_formatVal(habit.targetValue ?? 0)} ${habit.unit ?? ''})',
            iconColor: accentColor,
          ),
          if (onEdit != null || onDelete != null) ...[
            const Divider(color: AppColors.surface, height: 20),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        side: BorderSide(
                          color: AppColors.mutedGrey.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (onEdit != null && onDelete != null) const SizedBox(width: 10),
                if (onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              fontFamily: AppTheme.fontPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}
