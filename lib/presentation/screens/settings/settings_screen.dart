import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import '../../screens/add/add_habit_screen.dart';
import '../../screens/ai/ai_settings_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../theme/app_theme.dart';

/// Screen presenting prototype settings, export stubs, and navigation shortcuts.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
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

            // 2. Data Export Section (Prototype)
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

            const SizedBox(height: 24),

            // 3. Application Preferences
            _buildSectionHeader('PREFERENCES'),
            _buildInfoTile(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              value: 'Quiet Dark (Active)',
            ),
            const SizedBox(height: 8),
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
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
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

  void _handleExport(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting habit records to $format format... (Prototype stub)',
        ),
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
