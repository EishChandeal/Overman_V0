import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../application/providers/providers.dart';
import '../../../application/services/data_export_service.dart';
import '../../../data/database/app_database.dart';
import '../../navigation/app_router.dart';
import '../../screens/add/add_habit_screen.dart';
import '../../screens/ai/ai_settings_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/theme_selector_sheet.dart';

/// Screen presenting settings, real data exports (CSV, JSON, XLSX), and data import.
class SettingsScreen extends ConsumerWidget {
  final DataExportService? exportService;
  final Future<FilePickerResult?> Function()? onPickImportFile;
  final Future<FilePickerResult?> Function()? onPickWallpaperFile;

  const SettingsScreen({
    super.key,
    this.exportService,
    this.onPickImportFile,
    this.onPickWallpaperFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;
    final themeMode = settings?.themeMode ?? 'dark';
    final currentThemeName = switch (themeMode) {
      'warm' => 'Warm (Blanchedalmond)',
      'custom' => 'Custom Wallpaper',
      _ => 'Dark',
    };
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Navigation Section
            _buildSectionHeader('NAVIGATION SHORTCUTS'),
            _buildSettingTile(
              icon: Icons.insights_outlined,
              iconColor: AppColors.blue,
              title: 'Insights & Analytics',
              subtitle: 'Weekly consistency, metrics, and completion trends',
              onTap: () {
                appNavigateTo(
                  context,
                  AppRoutes.insights,
                  const InsightsScreen(),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.history_outlined,
              iconColor: AppColors.orange,
              title: 'History Log',
              subtitle: 'Inspect and edit entries from earlier dates',
              onTap: () {
                appNavigateTo(
                  context,
                  AppRoutes.history,
                  const HistoryScreen(),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.add_circle_outline,
              iconColor: AppColors.blue,
              title: 'Create New Habit',
              subtitle: 'Configure boolean or numeric tracking habits',
              onTap: () {
                appNavigateTo(context, AppRoutes.add, const AddHabitScreen());
              },
            ),

            const SizedBox(height: 24),

            // Appearance Section (STRAT-03-D)
            _buildSectionHeader('APPEARANCE'),
            _buildSettingTile(
              key: const Key('settings_theme_tile'),
              icon: Icons.palette_outlined,
              iconColor: AppColors.blue,
              title: 'Theme',
              subtitle: currentThemeName,
              onTap: () => _openThemeSelector(context, ref),
            ),

            const SizedBox(height: 24),

            // AI Assistant Section
            _buildSectionHeader('AI ASSISTANT'),
            _buildSettingTile(
              icon: Icons.auto_awesome_outlined,
              iconColor: AppColors.orange,
              title: 'AI Assistant',
              subtitle: 'Chat with your habit data',
              onTap: () {
                appNavigateTo(
                  context,
                  AppRoutes.aiSettings,
                  const AiSettingsScreen(),
                );
              },
            ),

            const SizedBox(height: 24),

            // 2. Data Export & Import Section
            _buildSectionHeader('DATA EXPORT'),
            _buildSettingTile(
              icon: Icons.table_chart_outlined,
              iconColor: AppColors.primaryText,
              title: 'Export to CSV',
              subtitle: 'Comma-separated values for spreadsheet analysis',
              onTap: () => _handleExport(context, 'CSV'),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.data_object_outlined,
              iconColor: AppColors.primaryText,
              title: 'Export to JSON',
              subtitle: 'Raw structured JSON schema backup',
              onTap: () => _handleExport(context, 'JSON'),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.description_outlined,
              iconColor: AppColors.primaryText,
              title: 'Export to Excel (XLSX)',
              subtitle: 'Multi-sheet workbook with formatting',
              onTap: () => _handleExport(context, 'XLSX'),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.file_upload_outlined,
              iconColor: AppColors.blue,
              title: 'Import Data',
              subtitle: 'Restore habits and entries from CSV or JSON backup',
              onTap: () => _handleImport(context),
            ),

            const SizedBox(height: 24),

            // 3. Application Preferences
            _buildSectionHeader('PREFERENCES'),
            _buildInfoTile(
              icon: Icons.calendar_today_outlined,
              title: 'First Day of Week',
              value: 'Monday',
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              icon: Icons.access_time_outlined,
              title: 'Day-Change Reset',
              value: 'Midnight (00:00 UTC)',
            ),

            const SizedBox(height: 24),

            // 4. About Section
            _buildSectionHeader('ABOUT OVERMAN'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overman_V0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This is a Working Multi-Screen Prototype\n'
                    'Architecture: Clean Architecture + ObjectBox Offline-First + Riverpod 2.0\n'
                    'Target Device Frame: 412 × 917 (Android Compact Frame)',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openThemeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ThemeSelectorSheet(
          onPickWallpaperFile: onPickWallpaperFile,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.mutedGrey,
          fontFamily: AppTheme.fontPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.mutedGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mutedGrey),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, String format) async {
    try {
      final service = exportService ??
          (AppDatabase.isOpen ? DataExportService(AppDatabase.instance) : null);

      if (service == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database store is not open.'),
              backgroundColor: AppColors.surface,
            ),
          );
        }
        return;
      }

      File exportedFile;
      switch (format.toUpperCase()) {
        case 'CSV':
          exportedFile = await service.exportCsv();
          break;
        case 'JSON':
          exportedFile = await service.exportJson();
          break;
        case 'XLSX':
          exportedFile = await service.exportXlsx();
          break;
        default:
          throw ArgumentError('Unsupported format: $format');
      }

      if (context.mounted) {
        final fileName = p.basename(exportedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to $format: $fileName'),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export to $format failed: $e'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      FilePickerResult? result;
      if (onPickImportFile != null) {
        result = await onPickImportFile!();
      } else {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'json', 'zip'],
        );
      }

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Import Data',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          content: const Text(
            'Import will merge data. Continue?',
            style: TextStyle(
              color: AppColors.mutedGrey,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.mutedGrey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import coming soon.'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }
}
