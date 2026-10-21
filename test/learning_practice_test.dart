import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/database/habit_entity.dart';
import 'package:habit_tracker/application/providers/habit_providers.dart';
import 'package:habit_tracker/application/providers/repository_providers.dart';
import 'package:habit_tracker/application/providers/database_provider.dart';
import 'package:habit_tracker/domain/enums/enums.dart';

void main() {
  setUp(() async {
    // 1. Initialize a clean, temporary ObjectBox database for this test run
    await AppDatabase.openStore();
  });

  tearDown(() {
    // 2. Shut down and clean up the database
    AppDatabase.closeStore();
  });

  test('Trace Habit Data Flow to Console', () async {
    print('\n=============================================');
    print('[Practice] Starting Trace Experiment!');
    print('=============================================\n');

    final store = AppDatabase.instance;
    final habitBox = store.box<HabitEntity>();

    // 3. Insert mock raw Entities directly into the database
    print('[DB] Seeding mock raw data into ObjectBox...');
    final mockHabits = [
      HabitEntity(
        id: 'mock-1',
        name: 'Drink Water (Mock)',
        type: 'numeric',
        unit: 'ml',
        targetValue: 2000,
        colorHex: '#33B3FF',
        iconName: 'water_drop',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isArchived: false,
      ),
      HabitEntity(
        id: 'mock-2',
        name: 'Read Book (Mock)',
        type: 'boolean',
        colorHex: '#57FF33',
        iconName: 'book',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        isArchived: false,
      ),
    ];
    habitBox.putMany(mockHabits);
    print('[DB] Successfully saved ${mockHabits.length} habits to the DB.\n');

    // 4. Create a Riverpod ProviderContainer (simulates the UI's ProviderScope)
    // We override objectBoxStoreProvider so it uses the temporary test database we opened in setUp()
    final container = ProviderContainer(
      overrides: [
        objectBoxStoreProvider.overrideWith((ref) async => store),
      ],
    );

    // 5. Subscribe to habitListProvider stream
    print('[UI Mock] Subscribing to habitListProvider...');
    final subscription = container.listen(
      habitListProvider,
      (previous, next) {
        // This callback fires every time the provider's stream emits new data
        print('\n---------------------------------------------');
        print('[UI Listener Triggered] Received updated stream emission!');
        
        next.when(
          data: (habitDtos) {
            print('[UI Listener] Successfully parsed DTOs from stream:');
            for (var habit in habitDtos) {
              print('  - DTO ID: ${habit.id} | Name: "${habit.name}" | Hex: ${habit.colorHex}');
            }
          },
          loading: () => print('[UI Listener] Stream is loading...'),
          error: (err, stack) => print('[UI Listener] Stream encountered error: $err'),
        );
        print('---------------------------------------------\n');
      },
      fireImmediately: true, // Trigger immediately with current state
    );

    // Give the stream a brief moment to finish its initial emission
    await Future.delayed(const Duration(milliseconds: 100));

    // 6. Test reactive update: Add a new habit via the repository
    print('[Repository] Simulating user adding a new habit...');
    final repo = await container.read(habitRepositoryProvider.future);
    
    await repo.createHabit(
      name: 'Pushups (Mock Repo Log)',
      type: HabitType.boolean,
      colorHex: '#FF5733',
      iconName: 'fitness',
      scheduleType: ScheduleType.daily,
    );

    // Wait a brief moment to let the stream emit the updated list
    await Future.delayed(const Duration(milliseconds: 100));

    // Clean up subscription
    subscription.close();
    container.dispose();
    
    print('\n=============================================');
    print('[Practice] Trace Experiment Finished!');
    print('=============================================\n');
  });
}
