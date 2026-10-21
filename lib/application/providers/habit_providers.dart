import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import 'repository_providers.dart';

part 'habit_providers.g.dart';

// Build runner to create the respective .g.dart file
// 1
@riverpod
Stream<List<HabitDto>> habitList(HabitListRef ref) async* {
  final repo = await ref.watch(habitRepositoryProvider.future);
  yield* repo.watchAllHabits();
}

@riverpod
Stream<List<HabitDto>> archivedHabits(ArchivedHabitsRef ref) async* {
  final repo = await ref.watch(habitRepositoryProvider.future);
  yield* repo.watchArchivedHabits();
}

@riverpod
Future<HabitDto?> habitById(HabitByIdRef ref, String habitId) async {
  final repo = await ref.watch(habitRepositoryProvider.future);
  return repo.getHabitById(habitId);
}

@riverpod
Future<HabitScheduleDto?> activeSchedule(
  ActiveScheduleRef ref,
  String habitId,
) async {
  final repo = await ref.watch(habitScheduleRepositoryProvider.future);
  return repo.getActiveScheduleForHabit(habitId);
}

@riverpod
Future<HabitLimitDto?> activeLimit(ActiveLimitRef ref, String habitId) async {
  final repo = await ref.watch(habitLimitRepositoryProvider.future);
  return repo.getActiveLimitForHabit(habitId);
}
