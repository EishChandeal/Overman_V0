import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/models/dtos/app_settings_dto.dart';
import '../../data/repositories/app_settings_repository.dart';
import 'database_provider.dart';

/// Provider for AppSettingsRepository.
final appSettingsRepositoryProvider =
    FutureProvider<AppSettingsRepository>((ref) async {
  if (AppDatabase.isOpen) {
    return AppSettingsRepository(AppDatabase.instance);
  }
  final store = await ref.watch(objectBoxStoreProvider.future);
  return AppSettingsRepository(store);
});

/// Synchronous provider for AppSettingsRepository when store is open.
final currentAppSettingsRepositoryProvider =
    Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(AppDatabase.instance);
});

/// Stream provider for reactive application settings (theme, wallpaper).
final appSettingsProvider =
    StreamProvider<AppSettingsDto>((ref) async* {
  final repo = await ref.watch(appSettingsRepositoryProvider.future);
  yield* repo.watchSettings();
});
