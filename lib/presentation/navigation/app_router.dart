import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/add/add_habit_screen.dart';
import '../screens/ai/ai_chat_screen.dart';
import '../screens/ai/ai_history_screen.dart';
import '../screens/ai/ai_personas.dart';
import '../screens/ai/ai_settings_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Central route names for Overman application.
class AppRoutes {
  static const home = '/';
  static const add = '/add';
  static const history = '/history';
  static const insights = '/insights';
  static const settings = '/settings';
  static const aiSettings = '/ai-settings';
  static const aiChat = '/ai-chat';
  static const aiHistory = '/ai-history';
}

/// GoRouter configuration providing declarative navigation for all prototype screens.
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.add,
      builder: (context, state) => const AddHabitScreen(),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.insights,
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiSettings,
      builder: (context, state) => const AiSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiChat,
      builder: (context, state) {
        if (state.extra is Widget) {
          return state.extra as Widget;
        }
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          return AiChatScreen(
            conversationId: map['conversationId'] as String?,
            persona: map['persona'] as AiPersona?,
            personaId: map['personaId'] as PersonaId?,
          );
        }
        final qConvId = state.uri.queryParameters['conversationId'];
        if (qConvId != null) {
          return AiChatScreen(conversationId: qConvId);
        }
        return const AiChatScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.aiHistory,
      builder: (context, state) =>
          (state.extra is Widget) ? state.extra as Widget : const AiHistoryScreen(),
    ),
  ],
);

/// Safe navigation helper that uses GoRouter when available, or falls back to
/// standard Navigator push for isolated widget tests without a GoRouter ancestor.
void appNavigateTo(BuildContext context, String route, Widget fallbackScreen, {Object? extra}) {
  try {
    context.push(route, extra: extra ?? fallbackScreen);
  } catch (_) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => fallbackScreen),
    );
  }
}
