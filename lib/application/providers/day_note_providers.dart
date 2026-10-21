import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import 'repository_providers.dart';

part 'day_note_providers.g.dart';

@riverpod
Stream<List<DayNoteDto>> habitDayNotes(
  HabitDayNotesRef ref,
  String habitId,
) async* {
  final repo = await ref.watch(dayNoteRepositoryProvider.future);
  yield* repo.watchNotesForHabit(habitId);
}
