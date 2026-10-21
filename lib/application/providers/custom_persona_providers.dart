import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/models/dtos/custom_persona_dto.dart';
import '../../data/repositories/custom_persona_repository.dart';
import '../../presentation/screens/ai/ai_personas.dart';
import 'database_provider.dart';

/// Provider for CustomPersonaRepository accessing the ObjectBox store.
final customPersonaRepositoryProvider =
    FutureProvider<CustomPersonaRepository>((ref) async {
  if (AppDatabase.isOpen) {
    return CustomPersonaRepository(AppDatabase.instance);
  }
  final store = await ref.watch(objectBoxStoreProvider.future);
  return CustomPersonaRepository(store);
});

/// Synchronous provider for CustomPersonaRepository when store is already open.
final currentCustomPersonaRepositoryProvider =
    Provider<CustomPersonaRepository>((ref) {
  return CustomPersonaRepository(AppDatabase.instance);
});

/// Stream provider that yields live updates of all custom personas.
final customPersonasProvider =
    StreamProvider<List<CustomPersonaDto>>((ref) async* {
  final repo = await ref.watch(customPersonaRepositoryProvider.future);
  yield* repo.watchAllPersonas();
});

/// Provider combining default static personas with user-defined custom personas.
final allPersonasProvider = Provider<List<AiPersona>>((ref) {
  final customDtos = ref.watch(customPersonasProvider).value ?? [];
  final customPersonas = customDtos.map((dto) => dto.toAiPersona()).toList();
  return [
    ...kPersonas,
    ...customPersonas,
  ];
});
