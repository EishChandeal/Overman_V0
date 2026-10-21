import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import 'dashboard_providers.dart';
import 'repository_providers.dart';
import 'streak_providers.dart';

part 'entry_providers.g.dart';

@riverpod
Stream<List<HabitEntryDto>> habitEntries(
  HabitEntriesRef ref,
  String habitId,
) async* {
  final repo = await ref.watch(habitEntryRepositoryProvider.future);
  yield* repo.watchEntriesForHabit(habitId);
}

@riverpod
Future<List<HabitEntryDto>> entriesForDate(
  EntriesForDateRef ref,
  DateTime date,
) async {
  final repo = await ref.watch(habitEntryRepositoryProvider.future);
  return repo.getEntriesForDate(date);
}

@riverpod
class EntryActions extends _$EntryActions {
  @override
  FutureOr<void> build() {}

  Future<HabitEntryDto> logEntry({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final repo = await ref.read(habitEntryRepositoryProvider.future);
    final entry = await repo.upsertEntry(
      habitId: habitId,
      date: date,
      value: value,
      note: note,
    );
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(entriesForDateProvider);
    ref.invalidate(habitEntriesProvider(habitId));
    ref.invalidate(habitStreakProvider(habitId));
    return entry;
  }

  Future<void> deleteEntry({
    required String entryId,
    required String habitId,
  }) async {
    final repo = await ref.read(habitEntryRepositoryProvider.future);
    await repo.deleteEntry(entryId);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(entriesForDateProvider);
    ref.invalidate(habitEntriesProvider(habitId));
    ref.invalidate(habitStreakProvider(habitId));
  }
}
