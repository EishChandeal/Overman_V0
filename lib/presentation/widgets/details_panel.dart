import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/navigation/app_router.dart';
import 'package:habit_tracker/presentation/screens/habit_detail/habit_detail_screen.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

/// Panel displaying configuration details and start date for a habit.
class DetailsPanel extends StatelessWidget {
  final HabitDto habit;
  final Color? habitColor;
  final HabitScheduleDto? activeSchedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewMore;

  const DetailsPanel({
    super.key,
    required this.habit,
    this.habitColor,
    this.activeSchedule,
    this.onEdit,
    this.onDelete,
    this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final createdFormatted = DateFormat('d MMMM yyyy').format(habit.createdAt.toLocal());
    final scheduleLabel = activeSchedule?.scheduleType.displayName ?? 'Daily';
    final accentColor = habitColor ?? HabitVisuals.parseColor(habit.colorHex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.innerTileBackground,
        borderRadius: BorderRadius.circular(12),
        border: palette.isDark ? null : Border.all(color: palette.innerTileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habit.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: palette.primaryText,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          if (habit.description != null && habit.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              habit.description!.trim(),
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: palette.accessibleSecondaryText,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          ],
          Divider(
            color: palette.isDark ? AppColors.surface : palette.cardBorder,
            height: 18,
          ),
          _buildDetailRow(
            context: context,
            icon: Icons.calendar_today_outlined,
            title: 'Start Date',
            value: createdFormatted,
            iconColor: accentColor,
          ),
          Divider(
            color: palette.isDark ? AppColors.surface : palette.cardBorder,
            height: 18,
          ),
          _buildDetailRow(
            context: context,
            icon: habit.isOneTime ? Icons.task_alt : Icons.repeat,
            title: habit.isOneTime ? 'Task Type' : 'Schedule',
            value: habit.isOneTime ? 'One-time Task' : scheduleLabel,
            iconColor: accentColor,
          ),
          if (habit.isOneTime && habit.completedAt != null) ...[
            Divider(
              color: palette.isDark ? AppColors.surface : palette.cardBorder,
              height: 18,
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.check_circle_outline,
              title: 'Completed',
              value: DateFormat('d MMMM yyyy, HH:mm').format(habit.completedAt!.toLocal()),
              iconColor: accentColor,
            ),
          ],
          Divider(
            color: palette.isDark ? AppColors.surface : palette.cardBorder,
            height: 18,
          ),
          _buildDetailRow(
            context: context,
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
            Divider(
              color: palette.isDark ? AppColors.surface : palette.cardBorder,
              height: 20,
            ),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.primaryText,
                        side: BorderSide(
                          color: palette.isDark
                              ? AppColors.mutedGrey.withValues(alpha: 0.5)
                              : palette.cardBorder,
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
                if (onEdit != null) const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('details_panel_view_more_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.isDark ? AppColors.orange : palette.interactiveAccent,
                      side: BorderSide(
                        color: (palette.isDark ? AppColors.orange : palette.interactiveAccent)
                            .withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (onViewMore != null) {
                        onViewMore!();
                      } else {
                        appNavigateTo(
                          context,
                          AppRoutes.habitDetailPath(habit.id),
                          HabitDetailScreen(
                            habitId: habit.id,
                            initialHabit: habit,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View More', style: TextStyle(fontSize: 13)),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: palette.accessibleSecondaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.primaryText,
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
