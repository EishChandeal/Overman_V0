import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/domain/enums/enums.dart';
import 'package:habit_tracker/presentation/navigation/app_router.dart';
import 'package:habit_tracker/presentation/screens/habit_detail/habit_detail_screen.dart';

void main() {
  final testHabit = HabitDto(
    id: 'test-habit-123',
    name: 'Morning Meditation',
    type: HabitType.boolean,
    colorHex: '#FF7A45',
    iconName: 'self_improvement',
    createdAt: DateTime.now(),
    isArchived: false,
  );

  group('HabitDetailScreen Widget Tests (STRAT-01-A)', () {
    testWidgets('renders habit details scaffold with habit name and placeholder content',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) => Stream.value([testHabit])),
          ],
          child: const MaterialApp(
            home: HabitDetailScreen(habitId: 'test-habit-123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byKey(const Key('habit_detail_content')), findsOneWidget);
      expect(find.text('Content coming soon'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders initialHabit immediately when supplied directly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HabitDetailScreen(
              habitId: testHabit.id,
              initialHabit: testHabit,
            ),
          ),
        ),
      );

      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byKey(const Key('habit_detail_content')), findsOneWidget);
    });

    testWidgets('renders 404 state when habit is not found and loading is complete',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) => Stream.value([])),
            habitByIdProvider('non-existent-id')
                .overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: HabitDetailScreen(habitId: 'non-existent-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('habit_detail_not_found')), findsOneWidget);
      expect(find.text('Habit not found'), findsOneWidget);
      expect(find.text('Habit Details'), findsOneWidget);
    });

    testWidgets('back button triggers navigation pop', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Navigator(
              onPopPage: (route, result) {
                popped = true;
                return route.didPop(result);
              },
              pages: [
                const MaterialPage(child: Scaffold(body: Text('Home Page'))),
                MaterialPage(
                  child: HabitDetailScreen(
                    habitId: testHabit.id,
                    initialHabit: testHabit,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Morning Meditation'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('GoRouter navigates to /habit-detail/:id and renders HabitDetailScreen',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => context.push('/habit-detail/test-habit-123'),
                child: const Text('Go to Detail'),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.habitDetail,
            builder: (context, state) {
              final habitId = state.pathParameters['id'] ?? '';
              return HabitDetailScreen(
                habitId: habitId,
                initialHabit: testHabit,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Go to Detail'), findsOneWidget);

      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Morning Meditation'), findsOneWidget);
      expect(find.byKey(const Key('habit_detail_content')), findsOneWidget);
    });
  });
}
