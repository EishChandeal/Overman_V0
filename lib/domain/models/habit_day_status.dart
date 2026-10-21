import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

/// Computed value object representing the status of a habit on a specific day.
class HabitDayStatus {
  final HabitDto habit;
  final HabitEntryDto? entry;
  final bool isScheduledToday;
  final DayStatus status;
  final HabitScheduleDto? activeSchedule;
  final HabitLimitDto? activeLimit;

  const HabitDayStatus({
    required this.habit,
    this.entry,
    required this.isScheduledToday,
    required this.status,
    this.activeSchedule,
    this.activeLimit,
  });

  HabitDayStatus copyWith({
    HabitDto? habit,
    Object? entry = const _Sentinel(),
    bool? isScheduledToday,
    DayStatus? status,
    Object? activeSchedule = const _Sentinel(),
    Object? activeLimit = const _Sentinel(),
  }) {
    return HabitDayStatus(
      habit: habit ?? this.habit,
      entry: entry is _Sentinel ? this.entry : entry as HabitEntryDto?,
      isScheduledToday: isScheduledToday ?? this.isScheduledToday,
      status: status ?? this.status,
      activeSchedule: activeSchedule is _Sentinel
          ? this.activeSchedule
          : activeSchedule as HabitScheduleDto?,
      activeLimit: activeLimit is _Sentinel
          ? this.activeLimit
          : activeLimit as HabitLimitDto?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitDayStatus &&
        other.habit == habit &&
        other.entry == entry &&
        other.isScheduledToday == isScheduledToday &&
        other.status == status &&
        other.activeSchedule == activeSchedule &&
        other.activeLimit == activeLimit;
  }

  @override
  int get hashCode => Object.hash(
        habit,
        entry,
        isScheduledToday,
        status,
        activeSchedule,
        activeLimit,
      );

  @override
  String toString() {
    return 'HabitDayStatus(habit: ${habit.name}, entry: $entry, isScheduledToday: $isScheduledToday, status: $status, activeSchedule: $activeSchedule, activeLimit: $activeLimit)';
  }
}

class _Sentinel {
  const _Sentinel();
}
