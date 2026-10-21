# Habit Tracker — Backend Build & Verification Guide

---

## Phase 1 — Project scaffold and dependencies

### Plan

```
Create a new Flutter project called habit_tracker.
Set up the following folder structure inside lib/:

  lib/
  ├── data/
  │   ├── models/
  │   │   └── dtos/
  │   ├── database/
  │   └── repositories/
  ├── domain/
  │   ├── services/
  │   └── enums/
  ├── application/
  │   └── providers/
  └── presentation/

Also create a top-level tool/ folder for dev utilities.

Place a .gitkeep file in every folder so they are tracked by git.

In pubspec.yaml, add these dependencies exactly:

dependencies:
  flutter:
    sdk: flutter
  objectbox: ^4.0.0
  objectbox_flutter_libs: ^4.0.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0
  uuid: ^4.4.0
  intl: ^0.19.0
  path_provider: ^2.1.3
  path: ^1.9.0
  logger: ^2.3.0
  flutter_secure_storage: ^9.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  objectbox_generator: ^4.0.0
  riverpod_generator: ^2.4.0
  riverpod_lint: ^2.3.10
  mocktail: ^1.0.4
  flutter_lints: ^4.0.0

Do not write any Dart code yet other than the default main.dart.
Do not run build_runner yet.
After making these changes, show me the final pubspec.yaml
in full so I can verify it.
```

### What to verify

**Check pubspec.yaml**

- Open pubspec.yaml and read every dependency line yourself.
  Confirm no package was added that you didn't ask for.
- Confirm dev_dependencies are in the right section —
  objectbox_generator must be under dev_dependencies,
  not dependencies. Putting generators in the wrong section
  bloats your release build.

**Check folder structure**

- Run `find lib/ -type f` in your terminal.
  You should see one .gitkeep per folder and nothing else.
- Confirm tool/ exists at the project root.

**Run flutter pub get**

- Run `flutter pub get` in terminal.
  It must complete with no errors.
  If you see version conflict errors, note the conflicting
  packages and ask the agent to resolve them specifically.

**Understand before moving on**

- Read the pubspec.yaml and know what each package does.
  If any package is unclear to you, ask the agent:
  "explain what [package name] does and why we need it
  in one paragraph." Do this for every package you don't
  recognize. This list is the foundation of everything.

---

## Phase 2 — Enums

### Plan

```
In lib/domain/enums/, create three separate files.
Pure Dart only — no Flutter imports, no ObjectBox imports.

File 1: habit_type.dart
Enum: HabitType with values: boolean, numeric
Each value needs:
- a displayName getter returning a human-readable String
  (e.g. 'Yes / No', 'Number')
- a static fromString(String value) factory that returns
  the matching enum value or throws ArgumentError if not found

File 2: frequency_type.dart
Enum: FrequencyType with values: daily, weekly, monthly
Same requirements: displayName getter and fromString() factory.
Display names: 'Daily', 'Weekly', 'Monthly'

File 3: day_status.dart
Enum: DayStatus with values:
  notTracked, missed, partiallyMet, met, exceeded
Same requirements: displayName getter and fromString() factory.
Display names: 'Not tracked', 'Missed', 'Partially met',
'Met', 'Exceeded'

After writing all three files, also create
lib/domain/enums/enums.dart as a barrel export file
that exports all three enum files with a single export
statement per file.

Do not create any other files. Do not run build_runner.
```

### What to verify

**Read every file yourself**

- Open each enum file. Confirm the fromString() method
  throws ArgumentError (not just returns null) for
  an unrecognized value. This matters later when
  deserializing corrupt or old data from ObjectBox.

**Manually trace the logic**

- For each enum, mentally call fromString() with:
  - A valid value (e.g. 'boolean') — should return the enum
  - An invalid value (e.g. 'xyz') — should throw
  - An uppercase valid value (e.g. 'Boolean') — what happens?
    If it doesn't handle case, ask the agent to add
    .toLowerCase() before comparison. Case issues will
    bite you during JSON import later.

**Check the barrel file**

- Open enums.dart. It should have exactly three export lines.
  Nothing else.

**Write this yourself after**

- This is a good first exercise. Close all the files,
  create a new file called practice_enums.dart in a scratch
  folder, and write FrequencyType from memory without
  looking. Compare with the agent's version.
  Note every difference. Delete your scratch file when done.

---

## Phase 3 — Plain DTOs (pure Dart data classes)

### Plan

```
In lib/data/models/dtos/, create three plain Dart DTO classes.
No ObjectBox annotations. No Flutter imports.
Import only dart:core and the enums from
lib/domain/enums/enums.dart.

These are immutable value objects that flow through
your service and provider layers. ObjectBox entities
will reference these but these classes know nothing
about ObjectBox.

File 1: habit_dto.dart — class HabitDto
Fields (all final):
  String id
  String name
  HabitType type
  String? unit          (nullable)
  double? targetValue   (nullable)
  FrequencyType frequency
  String colorHex
  String iconName
  DateTime createdAt
  bool isArchived

File 2: habit_entry_dto.dart — class HabitEntryDto
Fields (all final):
  String id
  String habitId
  DateTime date         (will always be midnight UTC — enforced in repository)
  double value
  String? note          (nullable)
  DateTime createdAt

File 3: habit_limit_dto.dart — class HabitLimitDto
Fields (all final):
  String id
  String habitId
  double? minValue      (nullable — a limit may only have a max)
  double? maxValue      (nullable — a limit may only have a min)
  DateTime effectiveFrom
  DateTime? effectiveTo (nullable — null means currently active)

Each class requires ALL of the following — write them manually,
no code generation:
1. A const constructor with all named parameters required
   unless nullable, in which case default to null.
2. copyWith() method that returns a new instance with
   only the specified fields changed. Every field
   must be represented in copyWith.
3. toJson() returning Map<String, dynamic>.
   Store enum values as their .name string.
   Store DateTime as ISO 8601 string via .toIso8601String().
4. fromJson(Map<String, dynamic> json) factory constructor.
   Use the fromString() factories on enums.
   Parse DateTime with DateTime.parse().
5. == operator and hashCode overriding all fields.
6. toString() for debug output showing all field values.

Create lib/data/models/dtos/dtos.dart as a barrel export.

In lib/data/models/dtos/, create a new file habit_schedule_dto.dart
with class HabitScheduleDto. This follows the exact same pattern
as HabitLimitDto — a versioned history record, not a flat field.

Fields (all final):
  String id
  String habitId
  ScheduleType scheduleType
  List<Weekday>? scheduledWeekdays   (only used when scheduleType is specificWeekdays)
  int? targetCount                   (only used when timesPerWeek or timesPerMonth)
  DateTime effectiveFrom
  DateTime? effectiveTo              (null means this is the currently active schedule)

Include the same required methods as the other DTOs:
const constructor, copyWith() (sentinel pattern for nullable
fields), toJson(), fromJson(), == operator, hashCode, toString().

Remove scheduleType, scheduledWeekdays, and targetCount from
HabitDto entirely — Habit no longer carries a current schedule
directly. Instead HabitDto keeps only its identity fields
(name, type, unit, targetValue, colorHex, iconName, createdAt,
isArchived). The schedule lives entirely in HabitScheduleDto
history, exactly the way limits already work.

Update lib/data/models/dtos/dtos.dart to export the new file.

Show me the full updated HabitDto and the new HabitScheduleDto file.

No other files. No build_runner.
```

### What to verify

**Check every field for nullability consistency**

- Open each DTO. For every nullable field, confirm
  the copyWith() parameter is also nullable and uses
  a sentinel pattern correctly. The common mistake is:
  `String? unit` in copyWith where you can't distinguish
  between "caller passed null" and "caller didn't pass it".
  The correct pattern for nullable fields in copyWith is:
  ```dart
  // Wrap in an Object? sentinel
  final _sentinel = Object();
  HabitDto copyWith({Object? unit = _sentinel, ...}) {
    return HabitDto(
      unit: unit == _sentinel ? this.unit : unit as String?,
      ...
    );
  }
  ```
  If the agent didn't do this, ask it to fix copyWith()
  for all nullable fields using this sentinel pattern.

**Trace toJson/fromJson manually**

- Pick HabitDto. On paper, write what toJson() would
  produce for a sample instance. Then trace fromJson()
  reading that map back in. Confirm you get the same
  values. Do this for one DTO — it trains your eye
  for serialization bugs.

**Check == and hashCode**

- Confirm == checks every field, not just id.
  hashCode should use Object.hash() or Object.hashAll()
  covering every field. If it only hashes id, that is
  technically a bug — two DTOs with the same id but
  different values would be "equal".

**Check barrel file**

- dtos.dart should export exactly three files.

---

## Phase 4 — ObjectBox entities

### Plan

```
In lib/data/database/, create three ObjectBox entity files
and a database initializer file.

Import objectbox and the DTO classes from
lib/data/models/dtos/dtos.dart.

IMPORTANT RULES:
- Every entity class is annotated with @Entity()
- Every entity has an int field named obId annotated
  with @Id() — this is ObjectBox's internal key.
  Always initialize it to 0 for new objects.
- Every entity has a String field named id for the UUID
  business key, annotated with @Unique() and @Index()
- Store all DateTime fields as int (millisecondsSinceEpoch)
  because ObjectBox handles DateTime natively but storing
  as int gives you explicit control
- Store all enum fields as String using the enum's .name
- Do not put business logic in entity classes

File 1: habit_entity.dart — class HabitEntity
Mirror every field from HabitDto plus obId.
Add: final ToMany<HabitEntryEntity> entries
and: final ToMany<HabitLimitEntity> limits
(import the other entity classes for these)

Required methods:
- factory HabitEntity.fromDto(HabitDto dto) — maps all fields
- HabitDto toDto() — maps all fields back, parsing
  enums with fromString(), converting int timestamps
  back to DateTime

File 2: habit_entry_entity.dart — class HabitEntryEntity
Mirror every field from HabitEntryDto plus obId.
Add: final ToOne<HabitEntity> habit
The date field must be stored as int (millisecondsSinceEpoch).

Required methods:
- factory HabitEntryEntity.fromDto(HabitEntryDto dto)
- HabitEntryDto toDto()

File 3: habit_limit_entity.dart — class HabitLimitEntity
Mirror every field from HabitLimitDto plus obId.
Add: final ToOne<HabitEntity> habit
effectiveTo stored as int? (nullable int for nullable DateTime).

Required methods:
- factory HabitLimitEntity.fromDto(HabitLimitDto dto)
- HabitLimitDto toDto()

File 4: app_database.dart
Create a class AppDatabase with:
- A static Store? _store private field
- A static Future<Store> openStore({String? directory})
  method that opens the ObjectBox store using the
  given directory, or a temp directory if null
  (for testing). Use getObjectBoxModel() which will
  be generated by build_runner.
- A static Store get instance getter that throws
  if openStore() was not called first.
- A static void closeStore() method.

After writing all four files, run:
  flutter pub run build_runner build --delete-conflicting-outputs

Confirm that objectbox.g.dart is generated in lib/ and
objectbox-model.json exists at the project root.
Report any build errors exactly as they appear.

In lib/data/database/, create habit_schedule_entity.dart
with class HabitScheduleEntity, following the exact same
pattern as HabitLimitEntity.

Fields: obId (@Id int), id (String, @Unique @Index),
habitId (String, @Index), scheduleType (String, store .name),
scheduledWeekdays (List<String>?, store each Weekday's .name),
targetCount (int?), effectiveFrom (int, millisecondsSinceEpoch),
effectiveTo (int?, nullable).
Add: final ToOne<HabitEntity> habit

Required methods: factory HabitScheduleEntity.fromDto(HabitScheduleDto dto)
and HabitScheduleDto toDto().

Remove the scheduleType/scheduledWeekdays/targetCount fields
from HabitEntity to match the updated HabitDto.

After updating all files, run:
  flutter pub run build_runner build --delete-conflicting-outputs
Report the full output.
```

### What to verify

**Confirm generated files exist**

- Check that `lib/objectbox.g.dart` exists.
- Check that `objectbox-model.json` exists at project root.
- If either is missing, build_runner failed silently.
  Run `flutter pub run build_runner build --verbose`
  and share the full output with the agent.

**Read fromDto/toDto for each entity**

- For each entity, trace fromDto() and toDto() on paper
  with a sample object. The round trip must be lossless:
  `entity.toDto()` called on `HabitEntity.fromDto(dto)`
  must give back a DTO equal to the original.
  Pay special attention to DateTime — converting to int
  and back must preserve the exact millisecond.

**Check nullable int for effectiveTo**

- Open HabitLimitEntity. The effectiveTo field
  must be `int?` not `int`. A non-nullable int cannot
  represent "null means currently active".

**Check ToOne/ToMany imports**

- Confirm the entity files import objectbox correctly
  and that ToOne<T>/ToMany<T> reference the right types.

**Try to understand build_runner**

- Open objectbox.g.dart. Don't read the whole thing —
  just look at the first 50 lines. Understand that this
  file is auto-generated and you should never edit it.
  Add it to .gitignore? Actually no — commit it so
  CI doesn't need to regenerate. Add it to your
  .gitignore only if your team always runs build_runner.
  For a solo project, commit the generated file.

---

## Phase 5 — Repositories

### Plan

```
In lib/data/repositories/, create four repository classes.
Each takes a Store (from ObjectBox) as a constructor parameter.
Each opens its own Box<T> internally.
All public methods return plain DTO objects or Streams of DTOs —
never raw ObjectBox entity classes.

Import the entity classes and DTO classes as needed.
Import the uuid package and create UUIDs with
const Uuid().v4() for new objects.

---

FILE 1: habit_repository.dart — class HabitRepository

Constructor: HabitRepository(this._store, this._scheduleRepository)
Private: final Store _store, final HabitScheduleRepository _scheduleRepository,
and late final Box<HabitEntity> _box
Initialize _box in the constructor body: _box = _store.box<HabitEntity>()

Methods:

Future<HabitDto> createHabit({
  required String name,
  required HabitType type,
  String? unit,
  double? targetValue,
  required String colorHex,
  required String iconName,
  required ScheduleType scheduleType,
  List<Weekday>? scheduledWeekdays,
  int? targetCount,
})
— generates a UUID for id, sets createdAt to DateTime.now().toUtc(),
  isArchived to false, creates entity, puts it.
  Then calls _scheduleRepository.setSchedule() with the habit's id,
  the schedule parameters, and effectiveFrom set to createdAt.
  This ensures every habit always has at least one schedule
  covering its entire lifetime from creation.
  Returns the habit dto.

Future<HabitDto> updateHabit(HabitDto updated)
— queries by updated.id, throws StateError if not found,
  updates all mutable fields (not id, not createdAt),
  puts back, returns updated dto.

Future<void> archiveHabit(String id)
— queries by id, sets isArchived to true, puts back.

Stream<List<HabitDto>> watchAllHabits()
— use _box.query(HabitEntity_.isArchived.equals(false))
  .watch(triggerImmediately: true)
  .map((query) => query.find().map((e) => e.toDto()).toList())

Future<HabitDto?> getHabitById(String id)
— queries HabitEntity_.id.equals(id), returns first result
  as dto or null if not found.

---

FILE 2: habit_entry_repository.dart — class HabitEntryRepository

Constructor and box setup same pattern as above (no schedule dependency).

IMPORTANT: the date field must always be normalized
to midnight UTC before saving. Create a private helper:
DateTime _normalizeDate(DateTime date) =>
  DateTime.utc(date.year, date.month, date.day)

Methods:

Future<HabitEntryDto> upsertEntry({
  required String habitId,
  required DateTime date,
  required double value,
  String? note,
})
— normalize the date first.
  Query for an existing entry where habitId matches AND
  date (as int) matches the normalized date's millisecondsSinceEpoch.
  If found: update value and note, put, return dto.
  If not found: create new with UUID, put, return dto.
  ObjectBox has no native upsert on non-@Id fields
  so implement this check manually.

- Validation: reject dates in the future (throw ArgumentError
  if normalized date is after today's midnight UTC).
  Allow any past date — this is how users backfill missed days.
  Add a comment explaining this is intentional for backfilling.
- Why: Without this, the user (or a bug) could create entries for future dates,
  which would  corrupt streak calculations. The StreakEngine iterates "from first entry to today" — a future entry would extend that range incorrectly.

Future<List<HabitEntryDto>> getEntriesForHabit(
  String habitId, DateTime from, DateTime to)
— normalize from and to dates.
  Query HabitEntryEntity_.habitId.equals(habitId)
  AND HabitEntryEntity_.date.between(
    from.millisecondsSinceEpoch, to.millisecondsSinceEpoch)
  Return as sorted list (ascending by date).

Stream<List<HabitEntryDto>> watchEntriesForHabit(String habitId)
— same query as above but use .watch(triggerImmediately: true)
  for a full history stream.

Future<List<HabitEntryDto>> getEntriesForDate(DateTime date)
— normalize the date, query all entries where date matches.

Future<Map<String, HabitEntryDto?>> getEntryStatusForDate(
  DateTime date,
  List<String> habitIds,
)

— normalize the date.
  Query all entries for that date.
  Return a Map where every habitId in the input list is a key,
  and the value is either the matching HabitEntryDto or null
  (null = no entry = not completed).
  This gives the UI a single call to render today's dashboard.

Future<DateTime?> getLastEntryDateForHabit(String habitId)
— Query all entries for habitId, order by date descending,
  return the date of the first result, or null if no entries.
  This is used by the UI to show "last logged: 3 days ago"
  and to highlight habits that haven't been updated recently.
---

FILE 3: habit_limit_repository.dart — class HabitLimitRepository

Constructor and box setup same pattern.

Methods:

Future<HabitLimitDto> setLimit({
  required String habitId,
  double? minValue,
  double? maxValue,
  required DateTime effectiveFrom,
})
— First, find any existing limit where habitId matches
  and effectiveTo (as int?) is null. If found, set its
  effectiveTo to DateTime.now().toUtc().millisecondsSinceEpoch
  and put it back. Then create a new limit entity with
  a UUID, effectiveTo null, and put it. Return the new dto.
  Both operations must complete before returning.

Future<HabitLimitDto?> getActiveLimitForHabit(String habitId)
— Query where habitId equals the given id.
  From the results, find the one where effectiveTo is null.
  Return as dto or null.
  Note: ObjectBox cannot query for null int directly —
  fetch all limits for the habitId and filter in Dart.

Future<List<HabitLimitDto>> getLimitHistoryForHabit(String habitId)
— Query all limits for the habitId.
  Sort by effectiveFrom descending in Dart.
  Return as list of dtos.

---

FILE 4: habit_schedule_repository.dart — class HabitScheduleRepository

Constructor and box setup same pattern as HabitLimitRepository.

Methods:

Future<HabitScheduleDto> setSchedule({
  required String habitId,
  required ScheduleType scheduleType,
  List<Weekday>? scheduledWeekdays,
  int? targetCount,
  required DateTime effectiveFrom,
})
— Find any existing schedule for habitId where effectiveTo is null.
  If found, set its effectiveTo to effectiveFrom (the moment the
  new schedule starts is the moment the old one ends — no gap,
  no overlap). Put it back. Then create and insert the new
  schedule with effectiveTo null. Return the new dto.

Future<HabitScheduleDto?> getActiveScheduleForHabit(String habitId)
— Same null-filtering approach as getActiveLimitForHabit:
  fetch all schedules for habitId, filter for effectiveTo == null
  in Dart, return as dto or null.

Future<List<HabitScheduleDto>> getScheduleHistoryForHabit(String habitId)
— All schedules for habitId, sorted by effectiveFrom ascending
  (ascending, not descending — StreakEngine will need to walk
  forward through history to find which schedule applied on
  any given day).

---

Create lib/data/repositories/repositories.dart as a barrel export
exporting all four repository files.
Do not run build_runner. Do not add any UI code.
```

### What to verify

**Read upsertEntry carefully**

- This is the trickiest method. Trace through both branches:
  when an entry already exists for that date, and when
  it doesn't. Confirm the date normalization happens
  before the query, not after. A bug here means duplicate
  entries per day, which silently corrupts streak data.

**Check the null query workaround in getActiveLimitForHabit**

- Confirm the agent did NOT try to query ObjectBox for
  null int (it won't work). It must fetch all limits for
  the habit and filter `.where((l) => l.effectiveTo == null)`
  in Dart. This is correct and the only safe approach.

**Check that no entity types leak out of repositories**

- Every public method return type should be a DTO or Stream
  of DTOs. If you see HabitEntity in any public signature,
  ask the agent to fix it.

**Check the stream mapping**

- In watchAllHabits() and watchEntriesForHabit(), confirm
  the stream maps entity lists to DTO lists using .toDto().
  A stream that emits raw entities will cause type errors
  the moment a provider tries to use it.

**Check the barrel file**

- repositories.dart exports exactly three files.

---

## Phase 6 — StreakEngine and StatisticsService

### Plan

```
In lib/domain/services/, create two service files.
These are pure Dart — no ObjectBox, no Flutter, no Riverpod.
They take plain data as input and return plain data as output.
No database calls anywhere in these files.

---

FILE 1: streak_engine.dart

Create a class StreakEngine with a single static method:

static StreakResult calculate({
  required List<HabitEntryDto> entries,
  required List<HabitScheduleDto> scheduleHistory,
})

   NOTE ON IMPLICIT ABSENCE: The entries list passed to
   calculate() will NOT contain entries for missed days —
   absence is the signal. The engine must iterate every
   calendar day between the first entry and today, and
   for any day with no matching entry in the list, treat
   it as DayStatus.missed (if the day was scheduled) or
   DayStatus.notScheduled (if the active schedule doesn't
   require that day). Do NOT assume the entries list is
   complete — it will have gaps for missed days.

scheduleHistory must be sorted ascending by effectiveFrom —
this is the caller's responsibility.

Add a private static helper:

static HabitScheduleDto? _scheduleForDate(
  DateTime date, List<HabitScheduleDto> history)
— walks the sorted history and returns the schedule where
  date falls between effectiveFrom (inclusive) and
  effectiveTo (exclusive, or unbounded if null).
  Returns null if no schedule covers that date (shouldn't
  happen given every habit has an initial schedule, but
  handle it defensively by treating it as notScheduled).

The method must:
1. Normalize all entry dates to midnight UTC before any comparison
2. Sort entries by date ascending
3. For every day from the earliest entry date to today (UTC),
   resolve which schedule was active on that day using
   _scheduleForDate(). Then apply the matching logic:

   a. scheduleType.daily — a day counts as completed if an
      entry exists for that date AND value > 0. A missing
      day counts as missed.

   b. scheduleType.specificWeekdays — check if that day's
      weekday is in that schedule's scheduledWeekdays.
      If not, DayStatus.notScheduled — skip in streak math.
      If yes, apply same completed/missed logic as daily.

   c. scheduleType.timesPerWeek / timesPerMonth — these
      require window-based evaluation. A window may span a
      schedule change boundary — handle this by evaluating
      each day's completion individually against whatever
      schedule was active that day, but only count a day
      toward a window's target if timesPerWeek/timesPerMonth
      was the active type that day. Days under a different
      schedule type within the same window are excluded from
      that window's count entirely.

   d. If _scheduleForDate() returns null for a day, treat
      that day as DayStatus.notScheduled.

4. currentStreak: count consecutive scheduled-and-completed
   days going backwards from today. Skip notScheduled days
   (they don't break streaks). If today has no entry yet,
   do not break the streak — check yesterday first.
   If yesterday was completed (or notScheduled and the day
   before was completed), streak is intact.

5. longestStreak: the longest consecutive scheduled-and-completed
   sequence across all time. notScheduled days are skipped,
   not counted as breaks.

6. heatmap: Map<DateTime, DayStatus> for every day from
   the first entry date to today. Keys must be normalized
   to midnight UTC. Use DayStatus enum:
   - DayStatus.notTracked for days before the first entry.
   - DayStatus.notScheduled for days where the active
     schedule does not require tracking.
   - DayStatus.missed for scheduled days with no entry
     or value == 0.
   - DayStatus.met for value > 0.

This means a single habit's full history may be governed by
multiple different schedules over time, and the engine must
respect exactly which schedule was active on each individual day —
never apply today's schedule retroactively to past days.

Create a StreakResult class in the same file:
  final int currentStreak
  final int longestStreak
  final Map<DateTime, DayStatus> heatmap
  const constructor, toString() for debug output.

After writing this, walk me through one worked example in your
explanation: a habit created as 'daily' on day 1, changed to
'specificWeekdays: [monday, wednesday]' on day 15, with entries
on most days throughout. Show me what the heatmap looks like
for days 10 through 20 so I can verify the boundary is handled
correctly.

---

FILE 2: statistics_service.dart

Create a class StatisticsService with a single static method:

static StatisticsResult calculate({
  required List<HabitEntryDto> entries,
  HabitLimitDto? activeLimit,
})

The method must compute:
- average: mean of all entry values. 0.0 if no entries.
- sum: total of all entry values.
- completionRate: ratio of entries where value > 0
  divided by total entries. Returns 0.0 if no entries.
- totalTrackedDays: count of entries where value > 0.
- totalMissedDays: count of entries where value == 0.
- bestValue: highest single entry value. 0.0 if no entries.
- weeklyAverages: Map<int, double> where key is ISO week
  number (use the intl package's DateFormat or compute
  manually: week = ((dayOfYear - dayOfWeek + 10) / 7).floor()).
  Value is the average of all entries in that week.
  Only include weeks that have at least one entry.

Create a StatisticsResult class in the same file with
all the above fields, const constructor, toString().

Create lib/domain/services/services.dart as a barrel export.
```

### What to verify

**Test StreakEngine logic on paper first**

- Before running any code, manually trace through
  this scenario: entries exist for day 1, day 2,
  (gap on day 3), day 4, day 5, today.
  Expected: currentStreak = 2, longestStreak = 2.
  Trace the agent's code with these inputs.
  If the output would differ, find the bug before
  running it. This is how you develop debugging intuition.

**Check timezone handling specifically**

- The most common bug in streak logic is mixing local
  DateTime with UTC DateTime. Confirm every date
  comparison in StreakEngine uses DateTime.utc()
  or .toUtc() before comparison. A user in UTC+5:30
  creating an entry at 11pm local time would create
  it as the next UTC day without this normalization.

**Check the "today has no entry" case**

- Trace the code for a case where today has no entry
  but yesterday was completed. The streak should NOT
  break — a user opening the app in the morning
  before logging today's habit should still see
  their streak intact.

**Check weeklyAverages grouping**

- Trace two entries from different weeks.
  Confirm they produce two separate keys in the map.
  Trace two entries from the same week.
  Confirm they average together under one key.

**Think about what's missing**

- Notice that StreakEngine currently ignores the limit.
  A habit with a target of 10000 steps where the user
  logged 5000 steps gets DayStatus.met even though
  they didn't hit their target. Write this down as
  a note. You'll revisit it in a later phase when you
  pass the active limit into StreakEngine.

---

## Phase 7 — Terminal dev runner

### Plan

```
Create tool/dev_runner.dart as a standalone Dart script.
This file is a development utility only — it is never
imported by the app. It should not be in lib/.

The script must:

1. Open an ObjectBox store using a temp directory:
   final tempDir = Directory.systemTemp.createTempSync('habit_dev_');
   final store = openStore(directory: tempDir.path);
   (use the openStore function from your generated
   objectbox.g.dart, not AppDatabase — this runner
   is intentionally lower-level for direct testing)

2. Instantiate all three repositories:
   HabitRepository, HabitEntryRepository, HabitLimitRepository

3. Create two habits:
   - A boolean habit: 'Morning meditation', type: boolean,
     frequency: daily, colorHex: '#6C63FF', iconName: 'meditation'
   - A numeric habit: 'Daily steps', type: numeric,
     unit: 'steps', targetValue: 10000.0, frequency: daily,
     colorHex: '#FF6584', iconName: 'footsteps'

4. Insert 30 days of entries going back from today:
   - Meditation: completed (value: 1.0) for all days
     EXCEPT days 8, 15, and 22 (counting back from today).
     Those days are missed (no entry inserted at all —
     do not insert a 0.0 value, just skip those days).
   - Steps: insert a value every day. Use these values
     in a repeating pattern:
     [7500, 11000, 9200, 13000, 6800, 10500, 8900]
     cycling through for each day.

5. Set a limit on the steps habit:
   - From day 30 to day 16: maxValue 10000.0
   - From day 15 to today: maxValue 12000.0
   Use setLimit() twice — the second call should
   automatically close the first limit's effectiveTo.

6. Run StreakEngine.calculate() for both habits
   and print the results clearly.

7. Run StatisticsService.calculate() for the steps habit
   passing the currently active limit.
   Print all result fields clearly.

8. Print the heatmap for the meditation habit showing
   the last 14 days as a simple text grid:
   '■' for met, '□' for missed, '·' for notTracked

9. Clean up: store.close() and tempDir.deleteSync(recursive: true)

Run this script with: dart run tool/dev_runner.dart

After writing the script, show me the expected terminal
output based on the data you inserted, so I can verify
the real output matches.
```

### What to verify

**Run it and compare to expected output**

- The agent should have shown you expected output.
  Run `dart run tool/dev_runner.dart` and compare
  every number. Any mismatch is a bug in either
  the runner data setup or your service logic.

**Check the limit history**

- After running, temporarily add a line to the runner
  that calls getLimitHistoryForHabit() and prints both
  limits. Confirm there are exactly two limits,
  the first has a non-null effectiveTo, and the second
  has effectiveTo null. This verifies the setLimit()
  sequential logic works.

**Check the heatmap grid**

- The text grid output should show exactly 3 missed days
  (□) in the last 14 days if days 8 and 15 fall within
  that window. Count the squares and verify manually.

**Check for any Dart errors or warnings**

- Run `dart analyze tool/dev_runner.dart` separately.
  There should be zero errors. Warnings about unused
  imports are fine to fix but not critical.

**Run it twice**

- Run the script a second time without clearing the
  temp directory (remove the deleteSync line temporarily).
  What happens? Does it crash because data already exists?
  Does it create duplicates? This reveals whether your
  upsertEntry and UUID generation are idempotent.
  The script creates a fresh tempDir each run via
  createTempSync so this won't apply — but think about
  what would happen with a real persistent store.

---

## Phase 8 — Unit tests

### Plan

```
In test/, create two test files.
These test pure logic only — no ObjectBox, no mocking needed.
Import only the service classes, DTO classes, and enum classes.

---

FILE 1: test/domain/streak_engine_test.dart

Write the following test groups:

Group: 'empty input'
- 'returns currentStreak of 0 when entry list is empty'
- 'returns longestStreak of 0 when entry list is empty'
- 'returns empty heatmap when entry list is empty'

Group: 'basic streak building'
- '1 consecutive day gives currentStreak of 1'
- '5 consecutive days gives currentStreak of 5'
- 'streak counts correctly when entries are unsorted'

Group: 'streak breaking'
- 'a gap in the middle breaks the current streak'
- 'current streak resets to days after the last gap'
- 'longestStreak preserves the record before the gap'
- 'two gaps leaves longestStreak as the longest run'

Group: 'today edge cases'
- 'if today has no entry but yesterday was completed,
   current streak is not broken'
- 'if today AND yesterday have no entry, streak is 0'
- 'a single entry for today gives currentStreak of 1'

Group: 'heatmap correctness'
- 'a completed day maps to DayStatus.met'
- 'a day with no entry maps to DayStatus.missed'
- 'days before first entry map to DayStatus.notTracked'
- 'heatmap contains an entry for every day
   from first entry to today'

Group: 'timezone safety'
- 'entries created with local DateTime are normalized
   and streak calculates correctly'
   (create entries using DateTime.now() without .toUtc()
   and confirm the streak is the same as when using
   DateTime.now().toUtc())

---

FILE 2: test/domain/statistics_service_test.dart

Group: 'empty input'
- 'average is 0.0 with no entries'
- 'completionRate is 0.0 with no entries'
- 'weeklyAverages is empty with no entries'

Group: 'average calculation'
- 'average of [10, 20, 30] is 20.0'
- 'average ignores no entries (all positive values)'

Group: 'completion rate'
- 'completionRate is 1.0 when all entries have value > 0'
- 'completionRate is 0.5 when half the entries are 0.0'
- 'completionRate is 0.0 when all entries have value 0.0'

Group: 'best value'
- 'bestValue returns the highest single entry'
- 'bestValue is 0.0 with no entries'

Group: 'weekly averages'
- 'two entries in the same ISO week average together'
- 'entries in different ISO weeks produce separate keys'
- 'a week with only one entry has that value as the average'

Group: 'totalTrackedDays and totalMissedDays'
- 'counts entries with value > 0 as tracked'
- 'counts entries with value == 0 as missed'
- 'sum of tracked and missed equals total entry count'

---

Use descriptive helper functions to build test HabitEntryDto
objects — avoid repeating the full constructor on every line.
Example:
HabitEntryDto entry(DateTime date, double value) => HabitEntryDto(
  id: const Uuid().v4(),
  habitId: 'test-habit',
  date: date,
  value: value,
  createdAt: DateTime.now().toUtc(),
);

After writing both test files, run:
  flutter test test/domain/
and report the full output including pass/fail for each test.
```

### What to verify

**All tests must pass before moving on**

- Run `flutter test test/domain/` yourself.
  If any test fails, do not move to Phase 9.
  Share the exact failure message with the agent
  and ask it to fix only the failing test or
  the service method it exposes as broken.

**Read every test description**

- Go through each test name. If any test description
  is vague (e.g. 'it works correctly'), ask the agent
  to rename it to describe the specific behavior.
  Good test names are executable specifications —
  they tell you exactly what the system should do.

**Add one test yourself**

- This is important for learning. Pick a case
  the agent didn't cover. For example:
  'streak of 30 days with no gaps gives currentStreak 30'.
  Write this test yourself, run it, confirm it passes.
  If it fails, that's a real bug to fix before moving on.

**Check test isolation**

- Each test must be independent — it must not depend on
  another test running first. Confirm no test uses a
  shared mutable variable that could leak state.
  Each test should create its own entries list locally.

---

## Phase 9 — Riverpod providers

### Plan

```
In lib/application/providers/, create provider files
using the @riverpod annotation from riverpod_generator.

IMPORTANT: Do not create any UI code. These providers
are the public API between the backend and any future
UI. Every provider must be fully typed — no dynamic,
no var in return types.

---

FILE 1: database_provider.dart

@Riverpod(keepAlive: true)
Future<Store> objectBoxStore(ObjectBoxStoreRef ref)
— use path_provider's getApplicationDocumentsDirectory()
  to get the app documents path.
  Open the ObjectBox store at that path using
  openStore(directory: path).
  Register an onDispose callback: ref.onDispose(() => store.close())
  Return the store.

---

FILE 2: repository_providers.dart

@Riverpod(keepAlive: true)
HabitRepository habitRepository(HabitRepositoryRef ref)
— await ref.watch(objectBoxStoreProvider.future)
  return HabitRepository(store)

Same pattern for:
HabitEntryRepository habitEntryRepository(...)
HabitLimitRepository habitLimitRepository(...)
HabitScheduleRepository habitScheduleRepository(...)

---

FILE 3: habit_providers.dart

@riverpod
Stream<List<HabitDto>> habitList(HabitListRef ref)
— get the repository via ref.watch(habitRepositoryProvider)
  call and return watchAllHabits()

@riverpod
Future<HabitDto?> habitById(HabitByIdRef ref, String habitId)
— get the repository, call getHabitById(habitId)

@riverpod
Future<HabitScheduleDto?> activeSchedule(ActiveScheduleRef ref, String habitId)
— get the schedule repository via ref.watch(habitScheduleRepositoryProvider)
  call and return getActiveScheduleForHabit(habitId)
  (This is what any future UI will use to show "this habit is currently scheduled for Mon/Wed/Fri" without needing full history.)

@riverpod
Future<HabitLimitDto?> activeLimit(ActiveLimitRef ref, String habitId)
— get the limit repository via ref.watch(habitLimitRepositoryProvider)
  call and return getActiveLimitForHabit(habitId)
  (This is what any future UI will use to show current targets like "10,000 steps".)

---

FILE 4: streak_providers.dart

Create a DateRange class (just a simple class with
DateTime start and DateTime end) in
lib/domain/enums/date_range.dart for use in providers.

@riverpod
Future<StreakResult> habitStreak(HabitStreakRef ref, String habitId)
— get the entry repository and schedule repository
  fetch entries for the last 365 days:
  from: DateTime.now().toUtc().subtract(const Duration(days: 365))
  to: DateTime.now().toUtc()
  fetch schedule history via getScheduleHistoryForHabit(habitId)
  return StreakEngine.calculate(entries: entries, scheduleHistory: scheduleHistory)

@riverpod
Future<StatisticsResult> habitStatistics(
  HabitStatisticsRef ref,
  String habitId,
  DateRange range,
)
— get the entry repository and limit repository
  fetch entries for the given range
  get the active limit for the habit
  return StatisticsService.calculate(entries: entries, activeLimit: limit)

---

FILE 5: entry_providers.dart

@riverpod
Stream<List<HabitEntryDto>> habitEntries(
  HabitEntriesRef ref,
  String habitId,
)
— returns watchEntriesForHabit(habitId) from the entry repository

@riverpod
Future<List<HabitEntryDto>> entriesForDate(
  EntriesForDateRef ref,
  DateTime date,
)
— returns getEntriesForDate(date) from the entry repository

@riverpod
class EntryActions extends _$EntryActions {
  // or use a simple function provider:
  Future<HabitEntryDto> logEntry({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final repo = ref.read(habitEntryRepositoryProvider);
    return repo.upsertEntry(
      habitId: habitId, date: date, value: value, note: note);
  }
}
— Because the UI will need a way to both log today's entry and backfill previous days.

---

FILE 6: dashboard_providers.dart

@riverpod
Future<List<HabitDayStatus>> todayDashboard(TodayDashboardRef ref)
— get the habit repository: fetch all active (non-archived) habits
  CRITICAL TIMEZONE RULE: Determine today using the user's local calendar day, then normalize to UTC midnight:
    final localNow = DateTime.now();
    final todayUtc = DateTime.utc(localNow.year, localNow.month, localNow.day);
  get the entry repository: call getEntriesForDate(todayUtc)
  get the schedule repository and limit repository
  for each habit:
    - get its active schedule and active limit
    - check if today is a scheduled day for that habit based on the active schedule
    - find if an entry exists for today
    - produce a HabitDayStatus object with:
        HabitDto habit, HabitEntryDto? entry, bool isScheduledToday, DayStatus status, HabitScheduleDto? activeSchedule, HabitLimitDto? activeLimit
  return the list sorted by habit name

Create a HabitDayStatus class in lib/domain/services/
or lib/data/models/dtos/:
  final HabitDto habit
  final HabitEntryDto? entry       (null = not yet logged)
  final bool isScheduledToday
  final DayStatus status           (computed: met/missed/notScheduled)
  final HabitScheduleDto? activeSchedule
  final HabitLimitDto? activeLimit

---

FILE 7: day_change_provider.dart

Create a mechanism to detect when the calendar day changes
while the app is open. Two scenarios to handle:

1. App is open at midnight — the day rolls over.
   Use a Timer that fires at the next midnight local time.
   When it fires, invalidate todayDashboardProvider
   so the UI refreshes to show the new day's blank slate.

2. App is resumed from background on a new day.
   Use WidgetsBindingObserver.didChangeAppLifecycleState.
   When the app resumes (AppLifecycleState.resumed),
   compare the current local date to the last-known date.
   If different, invalidate todayDashboardProvider.

Store the "last active date" in a simple Riverpod state
provider (not in the database — this is ephemeral UI state).
NOTE ON LIFECYCLE OWNERSHIP: Make this provider @Riverpod(keepAlive: true) so it can be watched by the root app widget or dashboard, ensuring the timer and lifecycle observer initialize immediately when the app opens.

---

Create lib/application/providers/providers.dart
as a barrel export.

After writing all files, run:
  flutter pub run build_runner build --delete-conflicting-outputs

Confirm all .g.dart files are generated with no errors.
Report the full build output.
```

```
Run build_runner after. Report the full output.
```

### What to verify

**Run build_runner and read the output**

- `flutter pub run build_runner build --delete-conflicting-outputs`
  Every provider file should produce a corresponding .g.dart.
  Any error here is usually a missing import or a
  ref type mismatch. Share the exact error with the agent.

**Check keepAlive usage**

- Database and repository providers should be keepAlive: true.
  Habit and entry providers should NOT be keepAlive —
  they should rebuild when dependencies change.
  Confirm this in the generated code.

**Check that providers don't import from presentation/**

- Run `grep -r "presentation" lib/application/` in terminal.
  Should return nothing. If it does, there is a
  layer violation to fix.

**Trace one provider chain manually**

- Pick habitStreak. Trace the dependency chain:
  habitStreakProvider → habitEntryRepositoryProvider
  → objectBoxStoreProvider → openStore().
  Confirm each step has the right ref.watch() or
  ref.read() call. Understanding this chain is essential
  for debugging provider errors in the future.

**Check that the DateRange class is in domain/, not application/**

- It's a domain concept, not a provider concern.
  If the agent put it in application/, move it to
  lib/domain/enums/date_range.dart and update the import.

**Final architecture check**

- Run `grep -r "import.*objectbox" lib/domain/` in terminal.
  Should return nothing. The domain layer must be
  completely free of ObjectBox imports.
- Run `grep -r "import.*flutter" lib/data/` in terminal.
  Should return nothing (path_provider is allowed only
  in the provider layer, not in data/).

---

## Future UI Phases — Backfill UI Considerations

The habit detail screen must:

- Show a calendar/heatmap view (data from StreakEngine)
- Allow tapping on any PAST day to log or edit an entry
  (calls upsertEntry with that day's date)
- Prevent tapping on FUTURE days (greyed out / disabled)
- Show a visual indicator on days with no entry
  (e.g., empty circle vs filled circle)
- When the user taps a past day with no entry, show an
  input dialog pre-filled with the date. On save, call
  upsertEntry. The dashboard and streak should update
  reactively via Riverpod's dependency invalidation.

---

## General follow-up prompts to keep handy

When the agent makes a mistake, use targeted corrections:

**For a specific method bug:**

```
In [filename], the [methodName] method has a bug:
[describe the bug exactly]. Fix only that method.
Do not change any other code in the file.
```

**For a missing edge case:**

```
In [filename], the [methodName] method does not handle
[edge case]. Add handling for this case. Show me only
the changed method, not the full file.
```

**For an architecture violation:**

```
In [filename], I see an import from [wrong layer].
This violates our architecture: [explain the rule].
Remove this import and refactor so the dependency
flows in the correct direction.
```

**For a code explanation:**

```
Explain line [N] of [filename] in plain English.
Then show me two alternative ways this same
logic could have been written and explain the
tradeoff between them.
```

**For a self-audit after any phase:**

```
Review the code you just wrote in [filename].
List any edge cases you did not handle,
any assumptions you made that I should know about,
and any places where the code might behave
unexpectedly under real usage.
```

---

## Backend completion checklist

Before writing a single UI widget, confirm all of these:

- [ ] `flutter pub get` runs clean
- [ ] `flutter pub run build_runner build` runs clean
- [ ] `dart run tool/dev_runner.dart` produces correct output
- [ ] `flutter test test/domain/` — all tests pass
- [ ] `flutter analyze` — zero errors
- [ ] No ObjectBox imports in lib/domain/
- [ ] No Flutter imports in lib/data/ or lib/domain/
- [ ] No entity types in any public repository method signature
- [ ] Barrel export files exist for each layer
- [ ] objectbox-model.json is committed to git
- [ ] Keystore generated and stored securely (do this before first APK)
