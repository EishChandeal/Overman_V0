import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/repositories.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
Future<HabitScheduleRepository> habitScheduleRepository(
  HabitScheduleRepositoryRef ref,
) async {
  final store = await ref.watch(objectBoxStoreProvider.future);
  return HabitScheduleRepository(store);
}

// resp. .g.dart file
// 2.
@Riverpod(keepAlive: true)
Future<HabitRepository> habitRepository(HabitRepositoryRef ref) async {
  final store = await ref.watch(objectBoxStoreProvider.future);
  final scheduleRepo = await ref.watch(habitScheduleRepositoryProvider.future);
  return HabitRepository(store, scheduleRepo);
}

@Riverpod(keepAlive: true)
Future<HabitEntryRepository> habitEntryRepository(
  HabitEntryRepositoryRef ref,
) async {
  final store = await ref.watch(objectBoxStoreProvider.future);
  return HabitEntryRepository(store);
}

@Riverpod(keepAlive: true)
Future<HabitLimitRepository> habitLimitRepository(
  HabitLimitRepositoryRef ref,
) async {
  final store = await ref.watch(objectBoxStoreProvider.future);
  return HabitLimitRepository(store);
}

@Riverpod(keepAlive: true)
Future<DayNoteRepository> dayNoteRepository(
  DayNoteRepositoryRef ref,
) async {
  final store = await ref.watch(objectBoxStoreProvider.future);
  return DayNoteRepository(store);
}
