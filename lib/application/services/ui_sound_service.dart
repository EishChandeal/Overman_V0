import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_providers.dart';

/// Service responsible for playing satisfying tactile audio feedback on habit completion/uncompletion.
class UiSoundService {
  final bool enabled;
  AudioPlayer? _completePlayer;
  AudioPlayer? _uncompletePlayer;

  UiSoundService({this.enabled = true});

  static const String completeSoundPath =
      'sounds/ui-digital-selector-brukowskij-spark-selector-4-0m01s.mp3';
  static const String uncompleteSoundPath =
      'sounds/futuristic-ui-negative-selection-davies-aguirre-1-00-00.mp3';

  AudioPlayer? _getCompletePlayer() {
    try {
      return _completePlayer ??= AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  AudioPlayer? _getUncompletePlayer() {
    try {
      return _uncompletePlayer ??= AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  /// Plays the futuristic digital completion spark sound (first touch).
  Future<void> playCompletionSound() async {
    if (!enabled) return;
    try {
      final player = _getCompletePlayer();
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource(completeSoundPath));
    } catch (_) {
      // Gracefully silent if platform audio hardware is unavailable (e.g. headless tests)
    }
  }

  /// Plays the futuristic negative selection sound (second touch / reversal).
  Future<void> playUncompletionSound() async {
    if (!enabled) return;
    try {
      final player = _getUncompletePlayer();
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource(uncompleteSoundPath));
    } catch (_) {
      // Gracefully silent if platform audio hardware is unavailable
    }
  }

  void dispose() {
    _completePlayer?.dispose();
    _uncompletePlayer?.dispose();
  }
}

/// Global provider for [UiSoundService].
final uiSoundServiceProvider = Provider<UiSoundService>((ref) {
  final enabled =
      ref.watch(appSettingsProvider).value?.enableCompletionEffects ?? false;
  final service = UiSoundService(enabled: enabled);
  ref.onDispose(service.dispose);
  return service;
});
