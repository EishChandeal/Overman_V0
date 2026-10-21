# Overman_V1 — Strategy Guide (Post-Production Features)

> This file defines the implementation strategy for features beyond PROD-06.
> It follows the same conventions as `PRODUCTION_STATUS.md`.
> Read this file **before writing any code**. Update it **after every task** with actual results.
> Never mark anything ✅ unless the code was written, analyzed, and the app behaves correctly.

---

## Context & Baseline

- Branch: `overman`
- Baseline: PROD-01 → PROD-06 all ✅ (156/156 tests passing, `dart analyze lib/` → 0 issues)
- Custom AI persona feature: implemented and committed (`ddd4d25`)
- Target device: Android compact (412 × 917 px, primary) + Windows desktop (dev/test)
- Dart/Flutter: see `pubspec.yaml` for current SDK constraints

---

## Hot Reload Error — Resolution Note

> [!IMPORTANT]
> **This is NOT a code bug.** The error below is a Flutter dev-tool limitation.
>
> ```
> Const class cannot remove fields:
> Library:'package:habit_tracker/presentation/screens/ai/ai_personas.dart'
> Class: AiPersona.
> ```
>
> **Root cause**: `AiPersona` was previously `const`-capable. Adding `imagePath`, `isCustom`,
> `PersonaIdentifier` wrapper, and `AiPersona.custom()` factory made it non-const. Flutter's
> hot-reload VM cannot patch const class field removals at runtime.
>
> **Fix**: Always use **hot restart** (not hot reload) after any class definition change that
> removes or restructures fields. After a hot restart the app runs correctly.
>
> **Rule for all future work**: Whenever you change a class that was previously `const` — or
> add/remove fields on any class — do a **hot restart**, not a hot reload.
>
> No code change is required for this error. The `AiPersona` class structure is intentionally
> non-const and correct as-is.

---

## Tasks — ordered by priority and dependency

### STRAT-01 — Habit Detail Screen

**Priority:** P1

**Goal:** Replace the delete button in the expanded habit card with a "View More" button that
navigates to a dedicated, single-habit detail screen featuring a heatmap, charts, and streak
analytics.

> [!NOTE]
> STRAT-01 is divided into 5 sub-parts (A → E). Execute them in order.
> Each sub-part has its own acceptance criteria. Do not combine sub-parts into a single commit.

---

#### STRAT-01-A — HabitDetailScreen scaffold + routing

**Goal:** Create the `HabitDetailScreen` shell and wire the route, so all later sub-parts
have a stable destination to render into.

**Spec:**

1. Create `lib/presentation/screens/habit_detail/habit_detail_screen.dart`.
2. Constructor parameter: `habitId` (`String`) — the UUID of the habit.
3. The screen reads the habit via an existing `habitProvider(habitId)` (or equivalent) using
   Riverpod. Show a `CircularProgressIndicator` while loading; show a 404-style message if
   the habit is not found.
4. **AppBar**:
   - Title: habit name (bold, 16 sp).
   - Leading: back arrow.
   - Background: `AppColors.surface`.
   - No trailing buttons yet (added in later sub-parts).
5. **Body**: a vertically scrollable `SingleChildScrollView` (or `CustomScrollView` with
   `SliverList`). Placeholder `Text('Content coming soon')` for now.
6. **Routing**:
   - Add route `AppRoutes.habitDetail` → `/habit-detail/:id` to `app_router.dart`.
   - The route extracts `id` from `pathParameters` and passes it to `HabitDetailScreen`.

**Acceptance criteria for STRAT-01-A:**

- [x] `HabitDetailScreen` file exists and compiles.
- [x] `/habit-detail/:id` route registered; app navigates to it without crashing.
- [x] AppBar shows habit name; back arrow returns to previous screen.
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (161/161).

---

#### STRAT-01-B — GitHub-style yearly heatmap widget

**Goal:** Build a reusable `YearHeatmapWidget` that renders a GitHub-style horizontal grid of
all days in a year, colored by completion intensity, scrollable left-right.

**Spec:**

1. Create `lib/presentation/widgets/year_heatmap_widget.dart`.
2. **Layout**:
   - A `SingleChildScrollView` with `scrollDirection: Axis.horizontal` wrapping a `Row` of
     week columns. Each column is 7 cells (Mon → Sun). Each cell is a small square
     (10 × 10 px) with 2 px gaps.
   - Above the grid: abbreviated month labels (`Jan`, `Feb`, …) aligned to the correct
     week column.
   - Left of the grid: abbreviated day labels (`M`, `T`, `W`, `T`, `F`, `S`, `S`) for the
     7 rows — 14 px height each, 10 px font.
3. **Color intensity** (5 levels):

   | Level | Condition (boolean habits)              | Condition (numeric habits)              | Color |
   |-------|-----------------------------------------|-----------------------------------------|-------|
   | 0     | No entry / not scheduled                | No entry                                | `AppColors.surface` with 20% opacity or a very dark grey (`#1a1a2e` or similar) |
   | 1     | Entry exists but `value == 0` (missed)  | Entry exists, value < 25% of target     | `habitColor.withOpacity(0.2)` |
   | 2     | —                                       | value 25–49% of target                  | `habitColor.withOpacity(0.4)` |
   | 3     | —                                       | value 50–74% of target                  | `habitColor.withOpacity(0.65)` |
   | 4     | `value == 1` (completed)                | value ≥ target (100%+)                  | `habitColor` (full opacity) |

   For boolean habits: only levels 0 (no entry / empty cell) and 4 (completed) — no
   intermediate levels. A missed entry (`value == 0`) uses level 1 (faint tint).

4. **Constructor parameters**:
   ```dart
   YearHeatmapWidget({
     required int year,                          // which year to display
     required List<HabitEntryDto> entries,       // all entries for this habit in the year
     required Color habitColor,
     required HabitType habitType,
     double? target,                             // for numeric habits
   })
   ```
5. **Tooltip on tap**: tapping a cell shows a `Tooltip` or a small `OverlayEntry` with the
   date and value (`"Mon, 14 Oct — ✅"` or `"Mon, 14 Oct — 7 glasses"`).
6. **Initial scroll position**: scroll to the current week (today's week) on build, using a
   `ScrollController` + `WidgetsBinding.instance.addPostFrameCallback`.
7. **Integration**: render this widget at the top of `HabitDetailScreen`'s scroll body,
   below a section header `"This Year"`, with 16 px horizontal padding and a year switcher
   row above the grid (left-arrow `IconButton` | `"2026"` label | right-arrow `IconButton`,
   right arrow disabled when showing current year).

**Acceptance criteria for STRAT-01-B:**

- [x] `YearHeatmapWidget` renders all 365/366 days as a grid in `HabitDetailScreen`.
- [x] Horizontal scroll works; month labels aligned correctly.
- [x] Color intensity reflects entry values correctly for both boolean and numeric habits.
- [x] Year switcher navigates between years; right arrow disabled for current year.
- [x] Cell tap shows date + value tooltip.
- [x] Scrolls to current week on initial render.
- [x] Widget test: renders with mock entries; correct cell count (364–366 cells).
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (168/168).

---

#### STRAT-01-C — Charts section

**Goal:** Render relevant charts below the heatmap: a completion bar chart for boolean habits,
a line graph with target line for numeric habits.

**Spec:**

Use the `fl_chart` package (already in `pubspec.yaml` if added; add it if missing).

1. Create `lib/presentation/widgets/habit_detail_chart.dart`.
2. **Boolean habits** → `WeeklyCompletionBarChart`:
   - Bar chart showing the last 12 weeks, each bar = number of completed days in that week
     (0–7, or 0–scheduled-days if the habit runs fewer days/week).
   - X-axis labels: week starting date (`Oct 7`, `Oct 14`, …).
   - Y-axis: 0 to max scheduled days per week (e.g., 0–7 for a daily habit).
   - Bar color: `habitColor`.
   - A faint horizontal dashed line at the scheduled-days-per-week value (the "perfect week"
     line).
3. **Numeric habits** → `NumericProgressLineChart`:
   - Line chart showing the last 30 days of raw values.
   - X-axis: dates.
   - Y-axis: 0 to `max(target, maxEntryValue) * 1.1` (10% headroom).
   - Data line: `habitColor`, width 2.5.
   - Target line: dashed, white with 40% opacity, labeled `"Target: {n} {unit}"`.
   - Dot at each data point (radius 3).
4. **Section header**: `"Performance"` label above the chart, 16 px font, bold.
5. **Chart height**: 180 px fixed. Wrapped in a `SizedBox`.
6. **No data state**: if fewer than 2 entries exist, show a muted centered text
   `"Not enough data yet — keep going!"` instead of the chart.

**Acceptance criteria for STRAT-01-C:**

- [x] `fl_chart` dependency present in `pubspec.yaml`.
- [x] Boolean habit shows bar chart in `HabitDetailScreen`; numeric shows line chart.
- [x] "Perfect week" dashed line present on bar chart.
- [x] Target dashed line present on line chart.
- [x] No-data state shows placeholder text (not a crash).
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (172/172).

---

#### STRAT-01-D — Streak analytics section

**Goal:** Compute and display streak statistics below the charts: top 5 longest streaks
in the current year, all-time greatest streak, and current streak.

**Spec:**

1. Create `lib/application/services/streak_calculator.dart`.

   ```dart
   class StreakCalculator {
     /// Computes the current streak (consecutive completed days ending on or before [today]).
     static int currentStreak(List<HabitEntryDto> entries, {DateTime? today});

     /// Computes the all-time greatest consecutive streak.
     static int allTimeGreatestStreak(List<HabitEntryDto> entries);

     /// Returns the top [topN] longest streaks within [year] (defaults to current year),
     /// each as a record: (streakLength, startDate, endDate).
     static List<({int length, DateTime start, DateTime end})> topStreaksInYear(
       List<HabitEntryDto> entries, {
       int year,
       int topN = 5,
     });
   }
   ```

   **Streak counting rules**:
   - An entry counts as "completed" if:
     - Boolean: `value == 1`.
     - Numeric: `value >= target` (if target is null, any `value > 0`).
   - Only days where the habit is scheduled count. Unscheduled days do not break streaks.
   - Consecutive completed scheduled days = streak.

2. **Streak UI section** in `HabitDetailScreen` (below charts):
   - Section header: `"Streaks"` (bold, 16 sp).
   - **Current streak**: large centered number (`{n} days`) with caption `"Current Streak"`.
     Use `AppColors.orange` for the number.
   - **All-time best**: same format, captioned `"All-Time Best"`, below the current streak row.
   - **Top 5 streaks this year**: a `ListView` (non-scrollable, `shrinkWrap: true`) of streak
     rows. Each row: rank badge (`#1`, `#2`, …) | `"{n} days"` | date range
     (`"Jan 3 → Jan 17"`).
   - If no streaks exist: muted text `"No streaks yet — start your first one today!"`.

3. **Unit tests** for `StreakCalculator`:
   - Current streak: 0 when no entries; counts only scheduled days.
   - All-time best: correct across multiple separate streaks.
   - Top streaks in year: only includes streaks starting/ending in the given year.

**Acceptance criteria for STRAT-01-D:**

- [x] `StreakCalculator` implemented with all three static methods.
- [x] Streak section renders in `HabitDetailScreen` with correct values.
- [x] Current streak uses `AppColors.orange`.
- [x] Top 5 list renders with rank, length, and date range.
- [x] Unit tests for all three `StreakCalculator` methods pass.
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (182/182).

---

#### STRAT-01-E — "View More" button integration

**Goal:** Replace the delete button in the expanded habit card with a "View More" button that
navigates to `HabitDetailScreen`. Keep delete functionality accessible elsewhere.

**Spec:**

1. In the expanded habit card (`lib/presentation/widgets/habit_card.dart` or equivalent):
   - **Remove** the delete `IconButton` from the expanded footer.
   - **Add** a `TextButton` or `OutlinedButton` labeled `"View More"` (icon: `Icons.arrow_forward_rounded`)
     that calls `context.push('/habit-detail/${habit.id}')`.
   - The button should be right-aligned in the expanded card footer row.

2. **Preserve delete functionality** — move delete to the long-press selection mode action
   bar (it may already be there; confirm it is still accessible). If it was only in the
   expanded card footer, add it to the selection mode AppBar actions.

3. **One-time tasks**: the "View More" button should still appear for one-time tasks (to see
   their status and notes), but the heatmap section should be hidden (already handled in
   STRAT-01-B by checking `habit.isOneTime`).

**Acceptance criteria for STRAT-01-E:**

- [x] "View More" button visible in expanded habit card.
- [x] Tapping "View More" navigates to `HabitDetailScreen` for that habit.
- [x] Delete remains accessible (selection mode action bar or equivalent).
- [x] One-time tasks also navigate to their detail screen (heatmap hidden).
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (182/182).

---

### STRAT-02 — Enhanced Insights & Analytics

**Priority:** P1

**Goal:** Enrich the Insights screen with app-open tracking, a user rank/category system,
and a corrected habit completion percentage formula.

> [!NOTE]
> STRAT-02 is divided into 3 sub-parts (A → C). Execute them in order.

---

#### STRAT-02-A — App-open session tracking

**Goal:** Track the number of unique calendar days the user has opened the app and compute
a "consecutive app-open streak."

**Spec:**

1. **New entity**: `AppSessionEntity` / `AppSessionDto`.

   | Field       | Type   | Nullable | Notes                                 |
   |-------------|--------|----------|---------------------------------------|
   | `obId`      | `int`  | no       | ObjectBox `@Id()`                     |
   | `id`        | `String` | no     | `@Unique` UUID                        |
   | `date`      | `int`  | no       | `@Unique @Index` — midnight UTC epoch ms of the day |
   | `createdAt` | `int`  | no       | Epoch ms — first open time of the day |

   > [!IMPORTANT]
   > The `date` field uses midnight UTC so that any time during a calendar day maps to the
   > same epoch ms. Use `DateTime(y, m, d).toUtc().millisecondsSinceEpoch`.

2. **Repository**: `AppSessionRepository` (`lib/data/repositories/app_session_repository.dart`):
   ```dart
   Future<void> recordTodayIfAbsent()   // called on every app open; upserts today's date
   Future<int> totalDaysOpened()        // count of all AppSessionEntity rows
   Future<int> currentOpenStreak()      // consecutive days ending on today (or yesterday if not yet recorded today)
   Stream<List<AppSessionDto>> watchAll()
   ```

3. **Call site**: call `AppSessionRepository.recordTodayIfAbsent()` in `main.dart` after
   the ObjectBox store is open, before `runApp`.

4. Register entity in `AppDatabase` and run `build_runner`.

5. Providers: `appSessionRepositoryProvider`, `totalDaysOpenedProvider` (FutureProvider),
   `currentOpenStreakProvider` (FutureProvider).

**Acceptance criteria for STRAT-02-A:**

- [x] `AppSessionEntity` and `AppSessionDto` created and registered in `AppDatabase`.
- [x] `build_runner` runs cleanly after entity addition.
- [x] `AppSessionRepository` implements all 4 methods.
- [x] `recordTodayIfAbsent()` called in `main.dart`.
- [x] Unit tests: `totalDaysOpened` returns correct count; `currentOpenStreak` counts consecutive days.
- [x] `dart analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass (191/191).

---

#### STRAT-02-B — User rank / category system

**Goal:** Display a user category badge on the Insights screen based on total days opened
and (for the top rank) habit completion performance.

**Spec:**

1. **Rank definitions**:

   | Rank              | Condition                                                                                     | Badge color suggestion |
   |-------------------|-----------------------------------------------------------------------------------------------|------------------------|
   | Common Man        | 0–14 days opened                                                                              | Muted grey             |
   | Man               | 15–29 days opened                                                                             | Muted green            |
   | The Man           | 30–59 days opened                                                                             | `AppColors.blue`       |
   | Exceptional One   | 60–99 days opened                                                                             | `AppColors.orange`     |
   | Chosen One        | 100+ days opened                                                                              | Gold (`#FFD700`)       |
   | Übermensch        | 100+ days opened **AND** all habits (that have been active ≥ 7 days) have ≥ 95% completion  | Custom purple/violet (`#9B59B6`) |

   > [!NOTE]
   > "Übermensch" takes precedence over "Chosen One" when both conditions are met.
   > Evaluate Übermensch eligibility only after 100+ days, to avoid false positives for
   > habits created recently with trivially high completion.

2. **Service**: `UserRankService` (`lib/application/services/user_rank_service.dart`):
   ```dart
   enum UserRank {
     commonMan, man, theMan, exceptionalOne, chosenOne, uebermensch
   }

   class UserRankService {
     static UserRank computeRank({
       required int totalDaysOpened,
       required List<HabitCompletionStat> habitStats,  // see below
     });

     static String rankLabel(UserRank rank);   // human-readable name
     static Color rankColor(UserRank rank);    // badge color
   }

   class HabitCompletionStat {
     final String habitId;
     final int completedDays;
     final int activeDays;   // days since createdAt that the habit was scheduled
     double get completionRate => activeDays == 0 ? 0 : completedDays / activeDays;
   }
   ```

3. **Insights screen integration**:
   - At the top of the Insights screen (before any existing widgets), add a prominent rank
     card:
     - Large rank label text (e.g., `"Exceptional One"`) in the rank color, centered.
     - Subtitle: `"You've opened the app {n} days"` in muted text.
     - For Übermensch only: a small italic footnote `"All habits followed with excellence"`.
     - Card background: `AppColors.surface` with a colored left border in the rank color
       (3 px border).
   - Below the card, add a stat row: `"{n} days total"` | `"{streak} day streak"`.

4. **Unit tests** for `UserRankService.computeRank`:
   - 0 days → `commonMan`.
   - 15 days → `man`.
   - 30 days → `theMan`.
   - 60 days → `exceptionalOne`.
   - 100 days, 50% completion → `chosenOne`.
   - 100 days, 96% completion across all habits → `uebermensch`.
   - 95 days, 99% completion → `exceptionalOne` (not Übermensch — days < 100).

**Acceptance criteria for STRAT-02-B:**

- [ ] `UserRank` enum and `UserRankService` implemented.
- [ ] Rank card renders at top of Insights screen with correct label and color.
- [ ] Übermensch displayed only when both conditions are met.
- [ ] All 7 unit tests for rank computation pass.
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

#### STRAT-02-C — Fix habit completion percentage

**Goal:** Correct the "100% completion" bug in the Insights screen's per-habit performance bars.

**Spec:**

1. **Correct formula**:
   ```
   completionRate = (completedDays / activeDays) * 100
   ```
   Where:
   - `completedDays` = number of days in `HabitEntryEntity` where the entry counts as
     completed (boolean: `value == 1`; numeric: `value >= target`).
   - `activeDays` = number of days the habit was **scheduled** since `habit.createdAt` up to
     and including today. For a daily habit this equals `(today - createdAt).inDays + 1`.
     For weekly/custom schedules, count only the scheduled days-of-week in the date range.

2. Create (or extend) a helper `HabitStatsCalculator` in
   `lib/application/services/habit_stats_calculator.dart`:
   ```dart
   class HabitStatsCalculator {
     static int computeActiveDays(HabitDto habit, List<String> scheduledWeekdays, DateTime today);
     static int computeCompletedDays(List<HabitEntryDto> entries, HabitDto habit);
     static double computeCompletionRate(HabitDto habit, List<HabitEntryDto> entries,
         List<String> scheduledWeekdays, DateTime today);
   }
   ```

3. Wire into:
   - The **Insights screen** per-habit performance bars — replace the current hardcoded/broken
     calculation with `HabitStatsCalculator.computeCompletionRate(...)`.
   - The `HabitCompletionStat` objects used in `UserRankService` (STRAT-02-B).

4. **Edge cases**:
   - Habit created today: `activeDays = 1`; if no entry yet, `completionRate = 0%`.
   - One-time tasks: show `100%` if completed, `0%` if pending (not scheduled, so regular
     formula doesn't apply — use a special case).
   - `activeDays == 0`: return `0%` (guard against divide-by-zero).

5. **Unit tests** for `HabitStatsCalculator`:
   - Daily habit, 7 days active, 5 completions → 71.4%.
   - Mon/Wed/Fri habit over 2 weeks (6 scheduled days), 6 completions → 100%.
   - One-time task completed → 100%.
   - One-time task pending → 0%.
   - `activeDays == 0` guard → 0%.

**Acceptance criteria for STRAT-02-C:**

- [ ] `HabitStatsCalculator` implemented with all 3 static methods.
- [ ] Insights screen shows correct (non-100%) completion percentages.
- [ ] One-time tasks handled correctly.
- [ ] All 5 unit tests pass.
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### STRAT-03 — New Themes

**Priority:** P2

**Goal:** Add two new themes (Warm and Custom/Wallpaper) alongside the existing dark theme,
with a theme selector in Settings.

> [!NOTE]
> STRAT-03 is divided into 4 sub-parts (A → D). Execute them in order.

> [!CAUTION]
> Theme changes touch global app-level state. Test on Android (compact) after every sub-part.
> Never remove `AppTheme.darkTheme` — it is the fallback.

---

#### STRAT-03-A — Theme persistence infrastructure

**Goal:** Establish how the selected theme is stored and provided to the app, before building
any new theme itself.

**Spec:**

1. **New entity**: `AppSettingsEntity` / `AppSettingsDto` (singleton, like `AiSettingsEntity`).

   | Field            | Type      | Nullable | Notes                                                       |
   |------------------|-----------|----------|-------------------------------------------------------------|
   | `obId`           | `int`     | no       | ObjectBox `@Id()`                                           |
   | `themeMode`      | `String`  | no       | `"dark"` | `"warm"` | `"custom"` (default: `"dark"`)         |
   | `wallpaperPath`  | `String?` | yes      | Absolute path to user-chosen wallpaper image (custom only)  |
   | `updatedAt`      | `int`     | no       | Epoch ms                                                    |

2. **Repository**: `AppSettingsRepository` (`lib/data/repositories/app_settings_repository.dart`):
   ```dart
   Future<AppSettingsDto> getSettings()    // returns default if none exists
   Future<void> saveSettings(AppSettingsDto dto)
   Stream<AppSettingsDto> watchSettings()
   ```

3. **Provider**: `appSettingsProvider` — a `StreamProvider<AppSettingsDto>` in
   `lib/application/providers/app_settings_providers.dart`.

4. **App-level wiring**: in `app.dart` (or wherever `MaterialApp` / `MaterialApp.router`
   is built), watch `appSettingsProvider` and pass `theme: AppTheme.themeForMode(dto.themeMode)`.

5. Register entity in `AppDatabase`; run `build_runner`.

**Acceptance criteria for STRAT-03-A:**

- [ ] `AppSettingsEntity` and `AppSettingsDto` exist and are registered.
- [ ] `build_runner` runs cleanly.
- [ ] `AppSettingsRepository` implements all 3 methods.
- [ ] `appSettingsProvider` stream provider created.
- [ ] `MaterialApp` reads `themeMode` from `appSettingsProvider` (defaults to dark — no visible change yet).
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

#### STRAT-03-B — Warm theme

**Goal:** Implement the "Warm" theme — a Blanchedalmond-based warm palette.

**Spec:**

1. In `lib/presentation/theme/app_theme.dart`, add:
   - `AppTheme.warmTheme` — a `ThemeData` using the warm palette below.
   - `static ThemeData themeForMode(String mode)` — returns `darkTheme`, `warmTheme`, or
     `customTheme` based on the mode string.

2. **Warm palette** (add as constants to `AppColors` or a new `WarmColors` class):

   | Token              | Color                | Hex       | Usage                                  |
   |--------------------|----------------------|-----------|----------------------------------------|
   | `warmBackground`   | Blanchedalmond       | `#FFEBCD` | Scaffold background                    |
   | `warmSurface`      | Bisque               | `#FFE4C4` | Cards, AppBar, bottom nav              |
   | `warmSurface2`     | PeachPuff            | `#FFDAB9` | Secondary containers, chips            |
   | `warmPrimaryText`  | Dark Brown           | `#3E2009` | Main text                              |
   | `warmSecondaryText`| Medium Brown         | `#7A4A2A` | Subtitles, captions                    |
   | `warmAccent`       | Sienna               | `#A0522D` | Buttons, selected rings, active icons  |
   | `warmAccent2`      | Peru                 | `#CD853F` | Secondary accents, icons               |
   | `warmDivider`      | Sandy Brown          | `#D4A574` | Dividers, borders with 40% opacity     |
   | `warmError`        | Tomato               | `#FF6347` | Error states                           |

3. Update all **widgets that use `AppColors.*` constants** to also respect the theme's
   `ColorScheme` or `Theme.of(context)` properties where possible, so they adapt to both
   dark and warm themes without hardcoding dark-only colors.

   > [!IMPORTANT]
   > Do not refactor every widget in one go. Instead, use `Theme.of(context).colorScheme`
   > in new widgets going forward. Existing widgets that use `AppColors.*` directly will
   > still work for dark theme. For warm theme, the key surfaces (Scaffold, AppBar, Cards)
   > are controlled by `ThemeData` — widget-level `AppColors` tokens only need changing if
   > they produce unreadable contrast in the warm theme.

4. **Text legibility check**: in warm mode, primary text must be dark brown — ensure
   `TextTheme` in `warmTheme` sets `bodyLarge`, `bodyMedium`, `bodySmall`, `titleLarge`,
   `titleMedium` to `warmPrimaryText`.

**Acceptance criteria for STRAT-03-B:**

- [ ] `AppTheme.warmTheme` implemented with the palette above.
- [ ] `AppTheme.themeForMode("warm")` returns `warmTheme`.
- [ ] Switching to warm theme (manually in code for testing) renders readable UI: no dark-text-on-dark-background or light-text-on-light-background issues on Scaffold, AppBar, Cards, Habit cards.
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

#### STRAT-03-C — Custom / Wallpaper theme

**Goal:** Let the user pick a wallpaper image from their device. The app renders the wallpaper
as a full-screen background; all UI elements become semi-transparent so the wallpaper is
partially visible through them.

**Spec:**

1. **ThemeExtension**: create `WallpaperThemeExtension` in
   `lib/presentation/theme/wallpaper_theme_extension.dart`:
   ```dart
   class WallpaperThemeExtension extends ThemeExtension<WallpaperThemeExtension> {
     final String? wallpaperPath;  // null = no wallpaper (dark/warm mode)
     final double cardOpacity;     // default 0.75 for custom theme, 1.0 for others
     final double surfaceOpacity;  // default 0.70 for custom theme
     // copyWith, lerp implementations
   }
   ```

2. **`AppTheme.customTheme`**: return a `ThemeData` identical to `darkTheme` but with
   `WallpaperThemeExtension(cardOpacity: 0.75, surfaceOpacity: 0.70)` added to
   `extensions`.

3. **App scaffold wrapper**: in `app.dart`, if `appSettingsProvider` returns `themeMode == "custom"` and `wallpaperPath != null`:
   - Wrap the router's output in a `Stack`:
     ```
     Stack
     ├── Positioned.fill → Image.file(File(wallpaperPath), fit: BoxFit.cover)
     └── child (the actual screen content)
     ```
   - Widgets that respect `WallpaperThemeExtension` will apply `cardOpacity` to their
     backgrounds via `context.extension<WallpaperThemeExtension>()`.

4. **Opacity application**: update `AppColors.surface`-using containers in key widgets
   (habit cards, AppBar, bottom nav, modals) to read `cardOpacity` from the extension:
   ```dart
   final ext = Theme.of(context).extension<WallpaperThemeExtension>();
   final opacity = ext?.cardOpacity ?? 1.0;
   color: AppColors.surface.withOpacity(opacity)
   ```

5. **Wallpaper picker** (wired in STRAT-03-D): the custom theme selection triggers a
   `FilePicker` image picker. The chosen path is saved to `AppSettingsEntity.wallpaperPath`.

**Acceptance criteria for STRAT-03-C:**

- [ ] `WallpaperThemeExtension` implemented with `cardOpacity` and `surfaceOpacity`.
- [ ] `AppTheme.customTheme` returns theme with extension attached.
- [ ] With `themeMode == "custom"` and a valid `wallpaperPath`, the wallpaper is visible behind UI elements.
- [ ] Habit cards, AppBar, bottom nav all render at ≤ 80% opacity in custom mode.
- [ ] No crash when `wallpaperPath` is null (falls back to `darkTheme` appearance).
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

#### STRAT-03-D — Theme switcher UI

**Goal:** Add a theme selection interface in Settings that lets the user switch between
Dark, Warm, and Custom themes.

**Spec:**

1. In `settings_screen.dart`, add a new section **APPEARANCE** above the AI ASSISTANT section:
   ```
   Section header: APPEARANCE
   Row: palette icon | "Theme" | subtitle: current theme name | › chevron
   ```
   Tapping opens `ThemeSelectorSheet` (a `showModalBottomSheet`).

2. **`ThemeSelectorSheet`**: a bottom sheet with three tiles:

   | Tile             | Icon                     | Description                              |
   |------------------|--------------------------|------------------------------------------|
   | 🌑 Dark           | `Icons.dark_mode`        | Default dark theme                       |
   | ☀️ Warm           | `Icons.wb_sunny_outlined` | Blanchedalmond warm palette              |
   | 🖼 Custom         | `Icons.wallpaper`        | Choose a wallpaper from your device      |

   - Each tile shows a small preview swatch (a 40 × 40 rounded rect with the background color).
   - The currently active theme has a checkmark trailing icon.
   - Tapping Dark or Warm saves `themeMode` to ObjectBox immediately and dismisses the sheet.
   - Tapping Custom:
     - Launches `FilePicker.platform.pickFiles(type: FileType.image)`.
     - On success: saves `themeMode = "custom"` and `wallpaperPath = result.files.single.path` to ObjectBox.
     - On cancel: no change.
     - If no wallpaper was previously set and user cancels picker: show SnackBar
       `"No wallpaper chosen — staying on current theme."`.

3. **Accessibility**: the bottom sheet has a drag handle at the top; closes on outside tap or drag down.

**Acceptance criteria for STRAT-03-D:**

- [ ] APPEARANCE section appears in Settings screen above AI ASSISTANT.
- [ ] Tapping Theme opens the bottom sheet with all 3 tiles.
- [ ] Selecting Dark or Warm changes the app theme immediately (reactive via `appSettingsProvider`).
- [ ] Selecting Custom opens the file picker; on success the wallpaper is applied immediately.
- [ ] Cancelling the picker leaves the theme unchanged and shows SnackBar.
- [ ] Active theme shows checkmark in the sheet.
- [ ] `dart analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

## Execution order

```
STRAT-01-A → STRAT-01-B → STRAT-01-C → STRAT-01-D → STRAT-01-E
    ↓
STRAT-02-A → STRAT-02-B → STRAT-02-C
    ↓
STRAT-03-A → STRAT-03-B → STRAT-03-C → STRAT-03-D
```

STRAT-01 and STRAT-02 can run in parallel if separate subagents are used. STRAT-03 depends
only on a stable codebase (no dependency on STRAT-01 or STRAT-02).

---

## File change map

| Task       | Files to create                                                                                                                 | Files to modify                                                             |
|------------|---------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| STRAT-01-A | `habit_detail_screen.dart`                                                                                                      | `app_router.dart`                                                           |
| STRAT-01-B | `year_heatmap_widget.dart`                                                                                                      | `habit_detail_screen.dart`                                                  |
| STRAT-01-C | `habit_detail_chart.dart`                                                                                                       | `habit_detail_screen.dart`, `pubspec.yaml` (fl_chart)                       |
| STRAT-01-D | `streak_calculator.dart`                                                                                                        | `habit_detail_screen.dart`                                                  |
| STRAT-01-E | —                                                                                                                               | `habit_card.dart` (or equivalent), `app_router.dart` (if needed)           |
| STRAT-02-A | `app_session_entity.dart`, `app_session_dto.dart`, `app_session_repository.dart`                                                | `app_database.dart`, `main.dart`, providers barrel, `objectbox.g.dart`      |
| STRAT-02-B | `user_rank_service.dart`                                                                                                        | `insights_screen.dart`                                                      |
| STRAT-02-C | `habit_stats_calculator.dart`                                                                                                   | `insights_screen.dart`                                                      |
| STRAT-03-A | `app_settings_entity.dart`, `app_settings_dto.dart`, `app_settings_repository.dart`, `app_settings_providers.dart`             | `app_database.dart`, `app.dart`, providers barrel, `objectbox.g.dart`       |
| STRAT-03-B | —                                                                                                                               | `app_theme.dart`, `app_colors.dart`                                         |
| STRAT-03-C | `wallpaper_theme_extension.dart`                                                                                                | `app_theme.dart`, `app.dart`, key widget files (habit_card, etc.)           |
| STRAT-03-D | `theme_selector_sheet.dart`                                                                                                     | `settings_screen.dart`                                                      |

---

## Known constraints and rules

1. **Default 5 personas** (`kPersonas`) must remain intact — never modify them.
2. **All existing tests** (156/156 at baseline) must continue to pass after every sub-task.
3. **`dart analyze lib/`** must return 0 issues after every sub-task.
4. **Hot restart after class changes** — never rely on hot reload when class definitions change.
5. **ObjectBox migrations** — never remove entity IDs or property IDs from `objectbox-model.json`.
6. **Übermensch condition**: 100+ days opened AND ≥ 95% completion on ALL habits active ≥ 7 days.
7. **Custom theme fallback**: if `wallpaperPath` is null or the file doesn't exist, fall back to the dark theme appearance silently.
8. **`fl_chart` version**: use the latest stable version compatible with current `pubspec.yaml` Flutter SDK constraint. Add it if not already present.

---

## Decisions made

| Date       | Decision                                                                                                         | Reason                                                                            |
|------------|------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|
| 2026-10-21 | Habit detail screen uses sub-parts (A–E) instead of one large task                                              | Each part has a clear boundary; easier to verify and commit independently          |
| 2026-10-21 | "View More" replaces delete button in expanded card; delete stays in selection mode                              | Frees primary action slot for navigation; delete via long-press is a known pattern |
| 2026-10-21 | Streaks count only scheduled days; unscheduled days don't break streaks                                          | A Mon/Wed/Fri habit user shouldn't have their streak broken on Tuesday             |
| 2026-10-21 | App-open tracking uses a separate `AppSessionEntity` (not a field on an existing entity)                         | Clean separation; supports future analytics without touching the habit data model  |
| 2026-10-21 | Übermensch rank requires BOTH 100+ days AND 95%+ completion; evaluated only after day 100                        | Prevents premature rank-ups from habits with trivially few active days             |
| 2026-10-21 | Warm theme uses static `WarmColors` constants rather than a separate `ThemeExtension`                            | Simpler for a fixed palette; ThemeExtension overhead not justified                 |
| 2026-10-21 | Custom/Wallpaper theme uses `WallpaperThemeExtension` for opacity values                                         | Allows widgets to adapt opacity without branching on a global theme mode string    |
| 2026-10-21 | Theme persistence uses a new `AppSettingsEntity` (not `AiSettingsEntity`)                                        | Separation of concerns; app settings will grow beyond just theme                   |
| 2026-10-21 | `AiPersona` is intentionally non-const; hot restart required after class definition changes (not a code bug)     | Documented here so future agents don't attempt to "fix" the non-const class        |

---

## Latest completed task

**Task ID:** STRAT-01-D — Streak analytics section

- **Implemented:**
  - `lib/application/services/streak_calculator.dart`:
    - `currentStreak`: Computes current consecutive streak backwards from today, preserving streak when today is still pending if yesterday was completed, and skipping unscheduled rest days.
    - `allTimeGreatestStreak`: Evaluates all historical streaks and returns the longest consecutive run.
    - `topStreaksInYear`: Extracts top $N$ longest streaks falling into a target year, sorted by length descending and recency, returning `({int length, DateTime start, DateTime end})` records.
  - `lib/presentation/widgets/streak_analytics_widget.dart`:
    - Current streak displayed with large bold font (28sp) in `AppColors.orange`.
    - All-Time Best streak displayed beneath current streak with clean separation.
    - Top 5 Streaks list rendered with rank badges (`#1`, `#2`, etc.), streak lengths, and date ranges (`MMM d → MMM d`).
    - Clean empty-state message: `"No streaks yet — start your first one today!"`.
  - `lib/presentation/screens/habit_detail/habit_detail_screen.dart`:
    - Integrated `StreakAnalyticsWidget` beneath the Performance chart section with section title `"Streaks"`.
  - Automated Tests:
    - Added `test/application/streak_calculator_test.dart` (10 tests) covering: empty entries, current streak counting, today pending logic, 0 streak on missed days, scheduled vs unscheduled day skipping, all-time best max calculation, year-bounded streak extraction, empty state widget rendering, current streak orange styling and rank badges, and integration into `HabitDetailScreen`.
- **Verification:**
  - `dart analyze lib/` → `No issues found!` (0 errors, 0 warnings)
  - `flutter test` → `All tests passed! (182/182 passed)`

## Current task

**STRAT-01-E** — "View More" button integration

- Status: Ready to start
- Goal: Replace the delete button in the expanded habit card footer with a "View More" button that navigates to `/habit-detail/:id`, while ensuring delete functionality remains fully accessible in selection mode.

## Next action

Execute **STRAT-01-E**: Update expanded habit card footer with "View More" button and verify delete accessibility.
