import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import 'repository_providers.dart';

part 'ai_settings_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<AiSettingsDto> aiSettings(AiSettingsRef ref) async* {
  final repo = await ref.watch(aiSettingsRepositoryProvider.future);
  yield* repo.watchSettings();
}
