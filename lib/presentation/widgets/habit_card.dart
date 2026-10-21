import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/domain/models/habit_day_status.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/widgets/details_panel.dart';
import 'package:habit_tracker/presentation/widgets/heatmap_panel.dart';
import 'package:habit_tracker/presentation/widgets/numeric_graph_panel.dart';
import 'package:habit_tracker/presentation/widgets/statistics_panel.dart';
import 'package:habit_tracker/presentation/widgets/notes_panel.dart';
import 'package:habit_tracker/presentation/widgets/day_note_bottom_sheet.dart';

/// Card component representing a habit on the Home screen.
/// Supports in-place expansion with circular panel sequence:
/// - Boolean habits: Heatmap → Statistics → Details → Heatmap
/// - Numeric habits: Heatmap → Statistics → Graph → Details → Heatmap
/// - One-off tasks: Details (Heatmap skipped)
class HabitCard extends ConsumerStatefulWidget {
  final HabitDayStatus item;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCompletionTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.onCompletionTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  bool _isExpanded = false;
  int _activePanelIndex = 0;

  bool get _isCompleted =>
      (widget.item.habit.isOneTime && widget.item.habit.completedAt != null) ||
      widget.item.status == DayStatus.met ||
      widget.item.status == DayStatus.exceeded;

  List<String> get _panelTitles {
    // One-time tasks do not show the Heatmap panel
    if (widget.item.habit.isOneTime) {
      return ['Details', 'Notes'];
    }
    if (widget.item.habit.type == HabitType.numeric) {
      return ['Heatmap', 'Statistics', 'Trend Graph', 'Notes', 'Details'];
    }
    return ['Heatmap', 'Statistics', 'Notes', 'Details'];
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        // Design requirement: Reopening a collapsed card always resets to the first panel
        _activePanelIndex = 0;
      }
    });
    widget.onTap?.call();
  }

  void _openDayNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DayNoteBottomSheet(
        habitId: widget.item.habit.id,
        habitColor: HabitVisuals.parseColor(widget.item.habit.colorHex),
      ),
    );
  }

  void _previousPanel() {
    final count = _panelTitles.length;
    if (count <= 1) return;
    setState(() {
      _activePanelIndex = (_activePanelIndex - 1 + count) % count;
    });
  }

  void _nextPanel() {
    final count = _panelTitles.length;
    if (count <= 1) return;
    setState(() {
      _activePanelIndex = (_activePanelIndex + 1) % count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.item.habit;
    final entry = widget.item.entry;
    final streakAsync = ref.watch(habitStreakProvider(habit.id));
    final habitColor = HabitVisuals.parseColor(habit.colorHex);

    final isCheckedOneTime = habit.isOneTime && _isCompleted;

    // Accent color on the left edge: habit color if completed, subtle tint otherwise
    final accentColor = _isCompleted ? habitColor : habitColor.withValues(alpha: 0.35);

    final wallpaperExt = Theme.of(context).extension<WallpaperThemeExtension>();
    final cardOpacity = wallpaperExt?.cardOpacity ?? 1.0;
    final themeSurface = Theme.of(context).colorScheme.surface;
    final cardSurface = themeSurface.withValues(alpha: cardOpacity);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Opacity(
      opacity: isCheckedOneTime ? 0.5 : 1.0,
      child: Material(
        color: Color.alphaBlend(habitColor.withValues(alpha: 0.05), cardSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: widget.isSelected
              ? BorderSide(color: habitColor, width: 2)
              : BorderSide(color: habitColor.withValues(alpha: 0.22), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleExpansion,
          onLongPress: widget.onLongPress,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(minHeight: 96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Main Card Row
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Narrow left-edge status accent bar
                        Container(
                          width: 5,
                          color: accentColor,
                        ),
                        const SizedBox(width: 12),

                        // Habit Icon Badge in selected habit color
                        Center(
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: habitColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: habitColor.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              HabitVisuals.getIcon(habit.iconName),
                              color: habitColor,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Habit details (Title, badge, schedule/streak, target)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    if (widget.isSelected) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.note_alt_outlined,
                                          color: AppColors.orange,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Day note',
                                        onPressed: () => _openDayNoteSheet(context),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Text(
                                        habit.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: isCheckedOneTime
                                              ? onSurface.withValues(alpha: 0.7)
                                              : onSurface,
                                          decoration: isCheckedOneTime
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: onSurface.withValues(alpha: 0.7),
                                          fontFamily: AppTheme.fontPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (habit.isOneTime) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.mutedGrey.withValues(alpha: 0.25),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'One-time',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.mutedGrey,
                                            fontFamily: AppTheme.fontPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildSubtitle(context, streakAsync.valueOrNull),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Completion / Value logging control
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: _buildCompletionControl(context, habit, entry, habitColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded Panel Section
                  if (_isExpanded) ...[
                    const Divider(color: AppColors.background, height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: _buildExpandedSection(context, habitColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context, Color habitColor) {
    final titles = _panelTitles;
    final safeIndex = _activePanelIndex.clamp(0, titles.length - 1);
    final currentTitle = titles[safeIndex];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            _nextPanel(); // Swipe left -> Next panel
          } else if (details.primaryVelocity! > 100) {
            _previousPanel(); // Swipe right -> Previous panel
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circular navigation bar (< Title [Dots] >)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button (<)
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
                onPressed: titles.length > 1 ? _previousPanel : null,
                splashRadius: 20,
                tooltip: 'Previous panel',
              ),

              // Title and dots indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(titles.length, (index) {
                      final isActive = index == safeIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isActive ? 12 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive ? habitColor : AppColors.mutedGrey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // Next button (>)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primaryText),
                onPressed: titles.length > 1 ? _nextPanel : null,
                splashRadius: 20,
                tooltip: 'Next panel',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Active Panel Content (scrollable container)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey<int>(safeIndex),
                  child: _buildPanelContent(habitColor, currentTitle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent(Color habitColor, String panelTitle) {
    final habit = widget.item.habit;

    switch (panelTitle) {
      case 'Heatmap':
        return HeatmapPanel(
          habitId: habit.id,
          habitColor: habitColor,
        );
      case 'Statistics':
        return StatisticsPanel(habit: habit);
      case 'Trend Graph':
        return NumericGraphPanel(habit: habit);
      case 'Notes':
        return NotesPanel(
          habitId: habit.id,
          habitColor: habitColor,
        );
      case 'Details':
      default:
        return DetailsPanel(
          habit: habit,
          habitColor: habitColor,
          activeSchedule: widget.item.activeSchedule,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        );
    }
  }

  Widget _buildSubtitle(BuildContext context, dynamic streakResult) {
    final habit = widget.item.habit;
    final habitColor = HabitVisuals.parseColor(habit.colorHex);
    final List<Widget> metaItems = [];

    if (habit.isOneTime) {
      if (_isCompleted) {
        metaItems.add(
          const Text(
            'Completed',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        );
      } else {
        metaItems.add(
          const Text(
            'One-time task',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        );
      }
    } else {
      // Streak count if meaningful (> 0)
      final streakCount = streakResult?.currentStreak ?? 0;
      if (streakCount > 0) {
        metaItems.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 15,
                color: habitColor,
              ),
              const SizedBox(width: 3),
              Text(
                '$streakCount ${streakCount == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: habitColor,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],
          ),
        );
      } else {
        // Schedule or target information
        final scheduleName =
            widget.item.activeSchedule?.scheduleType.displayName ?? 'Daily';
        metaItems.add(
          Text(
            scheduleName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        );
      }
    }

    if (habit.type == HabitType.numeric && habit.targetValue != null) {
      metaItems.add(
        Text(
          ' • Target: ${_formatNumber(habit.targetValue!)} ${habit.unit ?? ''}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: metaItems,
    );
  }

  Widget _buildCompletionControl(
    BuildContext context,
    dynamic habit,
    dynamic entry,
    Color habitColor,
  ) {
    const double controlSize = 72;
    final onHabitColor = HabitVisuals.getOnColor(habitColor);

    if (habit.type == HabitType.boolean) {
      final isDone = _isCompleted;
      return Semantics(
        button: true,
        label: isDone ? 'Mark habit as incomplete' : 'Mark habit as complete',
        child: Material(
          color: isDone ? habitColor : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onCompletionTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: controlSize,
              height: controlSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: isDone
                    ? null
                    : Border.all(
                        color: habitColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
              ),
              child: Center(
                child: isDone
                    ? Icon(
                        Icons.check,
                        size: 32,
                        color: onHabitColor,
                      )
                    : Text(
                        '—',
                        style: TextStyle(
                          color: habitColor.withValues(alpha: 0.7),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Numeric entry control
      final isDone = _isCompleted;
      final hasValue = entry != null && entry.value > 0;

      return Semantics(
        button: true,
        label: hasValue ? 'Logged ${entry.value}' : 'Log numeric value',
        child: Material(
          color: isDone
              ? habitColor
              : (hasValue ? AppColors.surface : AppColors.background),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onCompletionTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: controlSize,
              height: controlSize,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDone
                      ? habitColor
                      : (hasValue
                          ? habitColor.withValues(alpha: 0.7)
                          : habitColor.withValues(alpha: 0.35)),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasValue) ...[
                    Text(
                      _formatNumber(entry.value),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDone ? onHabitColor : habitColor,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (habit.unit != null && habit.unit!.isNotEmpty)
                      Text(
                        habit.unit!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDone
                              ? onHabitColor.withValues(alpha: 0.85)
                              : AppColors.mutedGrey,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ] else ...[
                    Text(
                      '—',
                      style: TextStyle(
                        color: habitColor.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (habit.unit != null && habit.unit!.isNotEmpty)
                      Text(
                        habit.unit!,
                        style: const TextStyle(
                          color: AppColors.mutedGrey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
