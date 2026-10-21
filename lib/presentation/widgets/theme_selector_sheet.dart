import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/providers.dart';
import '../../data/models/dtos/dtos.dart';
import '../theme/app_theme.dart';

/// Bottom sheet enabling user to switch between Dark, Warm, and Custom Wallpaper themes.
class ThemeSelectorSheet extends ConsumerWidget {
  final Future<FilePickerResult?> Function()? onPickWallpaperFile;

  const ThemeSelectorSheet({
    super.key,
    this.onPickWallpaperFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;
    final currentTheme = settings?.themeMode ?? 'dark';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mutedGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Choose Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Dark Theme Tile
            _buildThemeOptionTile(
              context: context,
              title: 'Dark',
              description: 'Default dark theme',
              icon: Icons.dark_mode,
              isSelected: currentTheme == 'dark',
              swatchColor: AppColors.background,
              onTap: () async {
                final repo =
                    await ref.read(appSettingsRepositoryProvider.future);
                await repo.saveSettings(
                  AppSettingsDto(
                    themeMode: 'dark',
                    wallpaperPath: settings?.wallpaperPath,
                    updatedAt: DateTime.now().toUtc(),
                  ),
                );
                ref.invalidate(appSettingsProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 10),

            // 2. Warm Theme Tile
            _buildThemeOptionTile(
              context: context,
              title: 'Warm',
              description: 'Blanchedalmond warm palette',
              icon: Icons.wb_sunny_outlined,
              isSelected: currentTheme == 'warm',
              swatchColor: const Color(0xFFFFEBCD),
              onTap: () async {
                final repo =
                    await ref.read(appSettingsRepositoryProvider.future);
                await repo.saveSettings(
                  AppSettingsDto(
                    themeMode: 'warm',
                    wallpaperPath: settings?.wallpaperPath,
                    updatedAt: DateTime.now().toUtc(),
                  ),
                );
                ref.invalidate(appSettingsProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),

            const SizedBox(height: 10),

            // 3. Custom Wallpaper Tile
            _buildThemeOptionTile(
              context: context,
              title: 'Custom',
              description: 'Choose a wallpaper from your device',
              icon: Icons.wallpaper,
              isSelected: currentTheme == 'custom',
              swatchColor: Colors.deepPurple.shade900,
              onTap: () async {
                final result = onPickWallpaperFile != null
                    ? await onPickWallpaperFile!()
                    : await FilePicker.pickFiles(type: FileType.image);

                if (!context.mounted) return;

                if (result != null &&
                    result.files.isNotEmpty &&
                    result.files.single.path != null) {
                  final pickedPath = result.files.single.path!;
                  final repo =
                      await ref.read(appSettingsRepositoryProvider.future);
                  await repo.saveSettings(
                    AppSettingsDto(
                      themeMode: 'custom',
                      wallpaperPath: pickedPath,
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  );
                  ref.invalidate(appSettingsProvider);
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  // User cancelled
                  if (settings?.wallpaperPath == null &&
                      currentTheme != 'custom') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'No wallpaper chosen — staying on current theme.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color swatchColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Material(
      color: isSelected
          ? primaryColor.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: primaryColor, width: 1.5)
            : BorderSide(
                color: AppColors.mutedGrey.withValues(alpha: 0.15), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: swatchColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.mutedGrey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color:
                        title == 'Warm' ? WarmColors.primaryText : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
