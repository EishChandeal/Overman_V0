import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/dtos/dtos.dart';
import '../../domain/enums/enums.dart';
import '../theme/app_theme.dart';

/// Single cell in the yearly heatmap grid.
class HeatmapCell extends StatelessWidget {
  final DateTime date;
  final Color color;
  final String tooltip;

  const HeatmapCell({
    super.key,
    required this.date,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      verticalOffset: 12,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.3)),
      ),
      textStyle: const TextStyle(
        color: AppColors.primaryText,
        fontSize: 11,
        fontFamily: AppTheme.fontPrimary,
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Reusable horizontal yearly heatmap widget (GitHub-style).
class YearHeatmapWidget extends StatefulWidget {
  final int year;
  final List<HabitEntryDto> entries;
  final Color habitColor;
  final HabitType habitType;
  final double? target;
  final String? unit;

  const YearHeatmapWidget({
    super.key,
    required this.year,
    required this.entries,
    required this.habitColor,
    required this.habitType,
    this.target,
    this.unit,
  });

  @override
  State<YearHeatmapWidget> createState() => _YearHeatmapWidgetState();
}

class _YearHeatmapWidgetState extends State<YearHeatmapWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentWeek();
    });
  }

  @override
  void didUpdateWidget(covariant YearHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentWeek();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    if (widget.year == now.year) {
      final jan1 = DateTime.utc(widget.year, 1, 1);
      final firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final daysDiff = todayUtc.difference(firstMonday).inDays;
      final weekIndex = (daysDiff / 7).floor();

      // Each column is 10px + 2px margin = 12px
      final targetOffset = (weekIndex * 12.0) - 100.0;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(clampedOffset);
    } else {
      _scrollController.jumpTo(0.0);
    }
  }

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _calculateColor(HabitEntryDto? entry) {
    if (entry == null) {
      return AppColors.surface.withValues(alpha: 0.35);
    }

    if (widget.habitType == HabitType.boolean) {
      if (entry.value >= 1.0) {
        return widget.habitColor;
      } else {
        return widget.habitColor.withValues(alpha: 0.20);
      }
    } else {
      final target = (widget.target != null && widget.target! > 0)
          ? widget.target!
          : 1.0;
      final ratio = entry.value / target;

      if (ratio >= 1.0) {
        return widget.habitColor;
      } else if (ratio >= 0.50) {
        return widget.habitColor.withValues(alpha: 0.65);
      } else if (ratio >= 0.25) {
        return widget.habitColor.withValues(alpha: 0.40);
      } else {
        return widget.habitColor.withValues(alpha: 0.20);
      }
    }
  }

  String _buildTooltip(DateTime date, HabitEntryDto? entry) {
    final dateStr = DateFormat('E, d MMM').format(date);
    if (entry == null) {
      return '$dateStr — No entry';
    }

    if (widget.habitType == HabitType.boolean) {
      return entry.value >= 1.0 ? '$dateStr — ✅' : '$dateStr — ❌';
    } else {
      final unitStr = (widget.unit != null && widget.unit!.isNotEmpty)
          ? ' ${widget.unit}'
          : '';
      final valStr = entry.value == entry.value.roundToDouble()
          ? entry.value.toInt().toString()
          : entry.value.toString();
      final targetStr = widget.target != null
          ? ' (target: ${widget.target == widget.target!.roundToDouble() ? widget.target!.toInt() : widget.target}$unitStr)'
          : '';
      return '$dateStr — $valStr$unitStr$targetStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesByDate = <String, HabitEntryDto>{};
    for (final e in widget.entries) {
      entriesByDate[_dateKey(e.date)] = e;
    }

    final jan1 = DateTime.utc(widget.year, 1, 1);
    final firstMonday = jan1.subtract(Duration(days: jan1.weekday - 1));
    final dec31 = DateTime.utc(widget.year, 12, 31);
    final lastSunday = dec31.add(Duration(days: 7 - dec31.weekday));
    final totalWeeks = (lastSunday.difference(firstMonday).inDays + 1) ~/ 7;

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left day labels
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 18), // Space for month labels
                for (final label in dayLabels)
                  Container(
                    height: 10,
                    width: 14,
                    margin: const EdgeInsets.only(bottom: 2),
                    alignment: Alignment.centerRight,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            // Horizontal scrollable grid
            Expanded(
              child: SingleChildScrollView(
                key: const Key('year_heatmap_scroll_view'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels row
                    Row(
                      children: [
                        for (int w = 0; w < totalWeeks; w++) ...[
                          _buildMonthHeader(firstMonday, w),
                          if (w < totalWeeks - 1) const SizedBox(width: 2),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Week columns
                    Row(
                      children: [
                        for (int w = 0; w < totalWeeks; w++) ...[
                          Column(
                            children: [
                              for (int d = 0; d < 7; d++) ...[
                                _buildCell(
                                  firstMonday.add(Duration(days: w * 7 + d)),
                                  entriesByDate,
                                ),
                                if (d < 6) const SizedBox(height: 2),
                              ],
                            ],
                          ),
                          if (w < totalWeeks - 1) const SizedBox(width: 2),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildMonthHeader(DateTime firstMonday, int weekIndex) {
    String? monthLabel;
    for (int d = 0; d < 7; d++) {
      final dt = firstMonday.add(Duration(days: weekIndex * 7 + d));
      if (dt.year == widget.year && dt.day == 1) {
        monthLabel = DateFormat('MMM').format(dt);
        break;
      }
    }

    if (monthLabel != null) {
      return SizedBox(
        width: 10,
        height: 14,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: 32,
          child: Text(
            monthLabel,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox(width: 10, height: 14);
  }

  Widget _buildCell(DateTime date, Map<String, HabitEntryDto> entriesByDate) {
    if (date.year != widget.year) {
      return const SizedBox(width: 10, height: 10);
    }

    final entry = entriesByDate[_dateKey(date)];
    final color = _calculateColor(entry);
    final tooltip = _buildTooltip(date, entry);

    return HeatmapCell(
      key: Key('heatmap_cell_${_dateKey(date)}'),
      date: date,
      color: color,
      tooltip: tooltip,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Less',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        const SizedBox(width: 6),
        _buildLegendSquare(AppColors.surface.withValues(alpha: 0.35)),
        const SizedBox(width: 3),
        _buildLegendSquare(widget.habitColor.withValues(alpha: 0.20)),
        const SizedBox(width: 3),
        _buildLegendSquare(widget.habitColor.withValues(alpha: 0.40)),
        const SizedBox(width: 3),
        _buildLegendSquare(widget.habitColor.withValues(alpha: 0.65)),
        const SizedBox(width: 3),
        _buildLegendSquare(widget.habitColor),
        const SizedBox(width: 6),
        const Text(
          'More',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
