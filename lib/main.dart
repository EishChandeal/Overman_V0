import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';
import 'package:habit_tracker/data/seeders/quote_seeder.dart';
import 'package:habit_tracker/application/providers/providers.dart';

import 'package:habit_tracker/presentation/theme/app_theme.dart';
import 'package:habit_tracker/presentation/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final store = await AppDatabase.openStore(directory: dir.path);

  // Seed initial quotes on first launch if empty
  await QuoteSeeder.seedIfEmpty(store);

  // Record today's app open session
  await AppSessionRepository(store).recordTodayIfAbsent();

  runApp(
    ProviderScope(
      overrides: [
        objectBoxStoreProvider.overrideWith((ref) {
          ref.onDispose(() => AppDatabase.closeStore());
          return Future.value(store);
        }),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends ConsumerWidget {
  final String? initialRoute;
  final GoRouter? router;

  const HabitTrackerApp({
    super.key,
    this.initialRoute,
    this.router,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize DayChangeController so midnight & resume day-change events
    // are observed for the lifetime of the application.
    ref.watch(dayChangeControllerProvider);

    final appSettings = ref.watch(appSettingsProvider).value;
    final themeMode = appSettings?.themeMode ?? 'dark';
    final effectiveTheme = AppTheme.themeForMode(
      themeMode,
      wallpaperPath: appSettings?.wallpaperPath,
    );

    final effectiveRouter = router ??
        (initialRoute != null ? createAppRouter(initialLocation: initialRoute!) : appRouter);

    return MaterialApp.router(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      routerConfig: effectiveRouter,
      builder: (context, child) {
        if (themeMode == 'custom' && appSettings?.wallpaperPath != null) {
          final file = File(appSettings!.wallpaperPath!);
          return Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.background,
                  ),
                ),
              ),
              if (child != null) child,
            ],
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
