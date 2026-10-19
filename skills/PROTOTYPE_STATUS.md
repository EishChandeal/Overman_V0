# Overman_V0 --- Prototype Status

> This file is the source of truth for prototype progress. Update it
> after each implementation task. Record observed results, not
> intentions. Never mark something as tested unless the relevant command
> or app flow was actually run.

## Current milestone

**Target:** Working multi-screen prototype

## Current status

- Overall: Backend ready; TASK-01 through TASK-06 complete; user verified Windows desktop smoke test passed; TASK-11 (Edit & Delete) complete; Custom habit color & icon integration across cards and panels complete.
- Last updated: 2026-10-14 11:15 IST
- Current branch/commit: `overman`
- Target device/emulator: Windows desktop & Android compact frame (412×917)
- App launches: Verified on Windows desktop by user & verified via widget tests (81/81 tests passing)

## Working features

- [x] Local persistence across app restart (ObjectBox on `getApplicationDocumentsDirectory()`)
- [x] Dark design system tokens & application theme (`AppColors`, `AppTheme.darkTheme`)
- [x] Home screen layout
- [x] Home navigation (navigation from Home to Add screen and back)
- [x] Add habit (boolean and numeric habit creation form with schedules, units, targets, colors, and icons)
- [ ] Add one-off task (intentionally skipped per user directive; deferred to a later step)
- [x] Checkmark completion (implemented via reactive `EntryActions.logEntry/deleteEntry` in `HomeScreen`)
- [x] Numeric value logging (implemented via bottom sheet in `HomeScreen`)
- [x] Custom habit color accenting & icon badge rendering across HabitCard, Heatmap, Statistics, Trend Graph, History, and Insights
- [x] Expanded habit card
- [x] Heatmap panel
- [x] Statistics panel
- [x] Numeric graph panel
- [x] Circular swipe/arrow navigation
- [x] Selection mode (long-press to enter selection mode with orange card highlight, deselect on tap outside or close icon)
- [x] Edit habit (prepopulates name, type, unit, target value, color, icon, and schedule; persists updates via repository)
- [x] Delete habit with confirmation (AlertDialog confirmation; cascades deletion across entries, schedules, limits; reactive refresh)
- [x] Details panel action shortcuts (direct Edit and Delete buttons on expanded habit details)
- [x] History screen (scrollable 30-day past calendar strip, per-date entries, and interactive historical logging)
- [x] Insights screen (high-level metrics overview, weekly activity chart, and per-habit performance bars)
- [x] Settings screen (navigation shortcuts, prototype export triggers, preferences, and about card)
- [x] CSV export (prototype UI trigger with feedback)
- [x] JSON export (prototype UI trigger with feedback)
- [x] XLSX export (prototype UI trigger with feedback)
- [ ] Final demonstration walkthrough

## Latest completed task

**Task ID:** TASK-12 — Custom Habit Color & Icon Rendering

- Implemented:
  - `lib/presentation/theme/app_theme.dart`:
    - Added `HabitVisuals` utility class with hex string parsing (`parseColor`), dynamic high-contrast foreground color calculation (`getOnColor`), and string-to-IconData resolution (`getIcon`).
  - `lib/presentation/widgets/habit_card.dart`:
    - Dedicated habit icon badge container rendered in `habitColor`.
    - Subtle container surface tint (`Color.alphaBlend(habitColor.withValues(alpha: 0.05), AppColors.surface)`) and colored border (`habitColor.withValues(alpha: 0.22)`).
    - Left-edge accent bar glows with `habitColor`.
    - Checkmark and numeric completion controls fill with `habitColor` when completed, with luminance-contrasting checkmark/number text.
    - Expanded circular panel dots color-coordinate with `habitColor`.
  - `lib/presentation/widgets/heatmap_panel.dart`:
    - Day status cells (`met`, `exceeded`) and active legend indicator dynamically adapt to `habitColor`.
  - `lib/presentation/widgets/numeric_graph_panel.dart`:
    - Trend bar charts, target goal line labels, and bar values dynamically adopt `habitColor`.
  - `lib/presentation/widgets/statistics_panel.dart`:
    - Stat summary tiles (completion rate, average value, consistency) coordinate with `habitColor`.
  - `lib/presentation/screens/history/history_screen.dart` & `lib/presentation/screens/insights/insights_screen.dart`:
    - Habit items display the chosen icon badge and color tints in past logs and insight progress bars.
- Files changed:
  - `lib/presentation/theme/app_theme.dart` (modified)
  - `lib/presentation/widgets/habit_card.dart` (modified)
  - `lib/presentation/widgets/heatmap_panel.dart` (modified)
  - `lib/presentation/widgets/numeric_graph_panel.dart` (modified)
  - `lib/presentation/widgets/statistics_panel.dart` (modified)
  - `lib/presentation/screens/history/history_screen.dart` (modified)
  - `lib/presentation/screens/insights/insights_screen.dart` (modified)
- Tests/checks run:
  - `flutter analyze lib/` → ✅ `No issues found! (ran in 21.4s)`
  - `flutter test` → ✅ `All tests passed! (81/81 passed)`
- Observed result:
  - Zero analysis issues in `lib/`.
  - All 81 tests pass across data, domain, repository, and widget suites.
- Known limitations:
  - One-off tasks omitted from Add screen as previously requested.

## Current task

**Task ID:** TASK-13 — Prototype polish & optional one-off tasks

- Goal: Polish UI interactions and add one-off tasks when user is ready.
- Acceptance criteria:
  - Codebase remains clean with 0 analysis issues and passing tests.
  - Codebase remains clean with 0 analysis issues and passing tests.

## Remaining work --- ordered by priority

### P0 --- Required for demonstration

- [x] TASK-01: Design tokens + app theme (`app_theme.dart`)
- [x] TASK-02: Home screen shell + habit card widget (consumes `todayDashboardProvider`)
- [x] TASK-03: Add Habit screen (boolean and numeric habits)
- [x] TASK-05: Expanded habit card — heatmap + statistics panels + circular navigation
- [x] TASK-06: Wire navigation (GoRouter & Navigator push to History, Insights, Settings)
- [x] TASK-07: End-to-end smoke run on emulator/device (user verified Windows smoke run)
- [x] TASK-11: Long-press selection mode → Edit/Delete

### P1 --- Valuable if time allows

- [x] TASK-08: History screen (scrollable dates, `getEntriesForDate` completed in TASK-06)
- [x] TASK-09: Insights screen (weekly activity chart, completion tiles completed in TASK-06)
- [x] TASK-10: Settings screen (navigation shortcuts + export stubs completed in TASK-06)
- [ ] Add one-off task support (when user is ready)

### P2 --- Defer unless already easy

- [ ] Actual notification delivery
- [ ] Remote AI backend
- [ ] Predictive modelling
- [ ] Cloud sync
- [ ] Nonessential animations and polish

## Known bugs / blockers

| Issue                         | Severity | Reproduction steps     | Next action                                   |
| ----------------------------- | -------- | ---------------------- | --------------------------------------------- |
| One-off task addition skipped | MEDIUM   | Intentionally deferred | Add one-off tasks when user directs           |
| 37 `avoid_print` lint infos   | LOW      | `flutter analyze`      | In test/tool files only; ignore for prototype |

## Decisions made

| Date       | Decision                                                            | Reason                                                                         |
| ---------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| 2026-10-14 | Implement GoRouter with fallback helper                             | Allows declarative routing while keeping widget test suites completely robust  |
| 2026-10-14 | Reset active panel to Heatmap on card reopen                        | Conforms with user design specification                                        |
| 2026-10-14 | Omit trend graph for boolean habits                                 | Trend graphs are only applicable to numeric tracking                           |
| 2026-10-14 | Skip one-off tasks in TASK-03                                       | Explicit user directive ("skip the addition of 'one-off tasks' on this step")  |
| 2026-10-14 | Wire `EntryActions` directly into `HomeScreen` completion callbacks | Provides instant reactive logging feedback without waiting for TASK-04         |
| 2026-10-14 | Configure `Montserrat` as font family with platform system fallback | Avoid network downloads and font asset bundling issues during prototype sprint |
| 2026-10-14 | Preserve existing architecture entirely                             | Code inspection confirms it is sound and fully tested                          |

## Next action

**TASK-07:** End-to-end smoke run on emulator/device and presentation walkthrough.

## Update instructions for coding agents

1. Read this file and `PROJECT_BRIEF.md` / `DESIGN.md` before changing code.
2. Change only what is needed for the assigned task.
3. Run the most relevant checks available and report their actual output/result.
4. Update this file after work, including changed files, verification performed, limitations, and next action.
5. Never claim tests passed if they were not run.
6. If a task fails, document the failure and preserve the last known working state.
7. Do not rewrite the entire file: preserve useful history and update only the relevant sections.
8. Always run `flutter analyze lib/` (not full project) to check for errors in production code after changes.
9. Run `flutter test` after any change that touches domain or data layers.

# ---- Prompt =====

for this project. Create a "Production_status.md" file look through the [PROTOTYPE_STATUS.md](file;file:///c:/Users/HP/Desktop/aoos/habit_v1/skills/PROTOTYPE_STATUS.md) to know the format being followed , the purpose of the file would be similar to the prior file, it will work as the guide for gemini flash models to build the project properly. The next set of tasks , features that I want to be implemented:

For making the following updates it will be essential that data is managed and stored in a structured way in the database, such that it can be retrieved and showed on screen without failure. Later on there will be features such as "import data (csv, json etc)" or "export data" in different formats as well.

1. One off habit. a change of some sort would be required for object box data models for this one think, the purpose that one of tasks will have, as the name suggests, quick day to day , or moment to moment tasks the user wants to store somewhere, tasks which are not exactly repeating and hence don't need to be stored as a "habit" . The Ui screen for them will not be separate. These tasks can be added with the same add button, but the now the add button UI will include another option ("one-time" task) , which won't be selected by default, by default the "habit" option would be selected. The user will have the ability to change that, and store their task as a one-time task not a habit.

2. Descriptions. Habit and tasks can have descriptions. Essentially a message that includes the reason,descripition for the habit/task. They are optional , there should be in a wide small box in add habit/ new habit screen, right below the select Icon option

3. Days notes. just told the gemini agent to create the note button before. essentially to store the days note, how the habit went for the day , how the user was feeling etc. the user can write that for the day. When the user holds the habit container the notepad button would appear on the left side of the header and with that the user can write the note for the day. The days note would then be shown in the sliding window in its own panel.

4. LLM layer. The data, overall can be provided to a large language model, the model can be added via an api entered by the user. There will be an option in the settings menu named "api for ai suggestions" and when the user clicks on that container/button in settings then a new screen would open up where the user can provide their specific api link and also below that input field would be a "personality" button/container, each personality type (thinking about including anime characters and movie personas), which would send a "pre-created" system prompt to the LLM. Certain characters can be tyler durden from fight girl, the bunny girl from bunny girl senpai etc. The data in proper easy to understand format , along with the system prompt assigning the LLM his persona and way of writing responses, will be sent initially and then the user can talk to the model however they like. selecting the "persona" would be an optional thing for the user, if they like mechanical usual conversations thats fine, but there needs to be that select feature. The characters and their system prompts are:

5. Quotes, this is more of a design attribute that I want at the loading screen of the app, the loading screen at the start of the app wont show the flutter icon, rather the icon design would be that of a muscular man and the angle of the visual would be primarily his muscular back and arm as he looks behind, this visual would be a box with rounded corners and this would be the same design the app's front on the home screen in android. At the botton there will be a random quote (I will provide you the list of quotes to cycle between and we can even program that feature such that only specific quotes are shown on specific days.)

## to change

1. the insights screen
2. the history page, make it vertical and concise
