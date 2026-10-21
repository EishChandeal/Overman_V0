import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/models/dtos/app_session_dto.dart';
import '../../data/repositories/app_session_repository.dart';
import 'database_provider.dart';

/// Provider for AppSessionRepository.
final appSessionRepositoryProvider =
    FutureProvider<AppSessionRepository>((ref) async {
  if (AppDatabase.isOpen) {
    return AppSessionRepository(AppDatabase.instance);
  }
  final store = await ref.watch(objectBoxStoreProvider.future);
  return AppSessionRepository(store);
});

/// Synchronous provider for AppSessionRepository when store is open.
final currentAppSessionRepositoryProvider =
    Provider<AppSessionRepository>((ref) {
  return AppSessionRepository(AppDatabase.instance);
});

/// Stream of all app sessions.
final appSessionsProvider =
    StreamProvider<List<AppSessionDto>>((ref) async* {
  final repo = await ref.watch(appSessionRepositoryProvider.future);
  yield* repo.watchAll();
});

/// Total unique calendar days the user has opened the app.
final totalDaysOpenedProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(appSessionRepositoryProvider.future);
  ref.watch(appSessionsProvider);
  return repo.totalDaysOpened();
});

/// Current streak of consecutive days opening the app.
final currentOpenStreakProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(appSessionRepositoryProvider.future);
  ref.watch(appSessionsProvider);
  return repo.currentOpenStreak();
});
