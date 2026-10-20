# Overman_V1 — Production Status

> This file is the authoritative guide for production feature implementation.
> Read it **before writing a single line of code**. Update it **after every task**
> with observed results, not intentions. Never mark anything ✅ unless the
> relevant code was actually written, analyzed, and the app behaves correctly
> on the target device.

---

## Current milestone

**Target:** Production-ready feature set — data integrity, AI layer, rich UX

## Current status

- Overall: Prototype complete (TASK-01 → TASK-12 done). Production phase begins here.
- Last updated: 2026-10-20
- Branch/commit: `overman` (continue from last prototype commit)
- Target devices: Windows desktop (dev/test) + Android compact (412 × 917 px, primary)
- App launches: ✅ Verified (81/81 tests passing from prototype)

---

## Working features (inherited from prototype — do not regress)

- [x] Local persistence via ObjectBox (`getApplicationDocumentsDirectory()`)
- [x] Dark design system (`AppColors`, `AppTheme.darkTheme`, Montserrat font)
- [x] Home screen layout + habit cards
- [x] Add Habit screen (boolean / numeric, schedules, units, targets, color, icon)
- [x] Checkmark + numeric completion logging
- [x] Custom habit color + icon across all widgets
- [x] Expanded habit card with Heatmap / Statistics / Numeric Graph panels
- [x] Long-press selection mode → Edit / Delete
- [x] History screen (30-day calendar strip)
- [x] Insights screen (weekly chart, per-habit bars)
- [x] Settings screen (export stubs: CSV, JSON, XLSX)

---

## Production tasks — ordered by dependency and priority

### PROD-01 — Data model expansion (prerequisite for everything else)

**Priority:** P0 — must be done first; all other tasks depend on this.

**Goal:** Extend the ObjectBox schema and DTO layer to support all new fields
needed by PROD-02 through PROD-06 without breaking existing data.

**Spec:**

#### 1. `HabitEntity` / `HabitDto` additions

| New field | Type | Nullable | Purpose |
|---|---|---|---|
| `description` | `String?` | yes | Optional user-written reason / description for this habit or task |
| `isOneTime` | `bool` | no (default `false`) | `true` → one-time task; `false` → recurring habit |
| `completedAt` | `int?` (epoch ms) | yes | For one-time tasks: the date/time the task was marked done; `null` if not yet done |

> [!IMPORTANT]
> `HabitType` enum currently has `boolean` and `numeric`. Do **not** add a third
> enum value for one-time tasks. One-time vs. recurring is controlled by the
> new `isOneTime` boolean flag so that one-time tasks can still be boolean
> (done/not done) or numeric (e.g. "drink 3 glasses today"). The existing
> type enum is preserved as-is.

#### 2. `HabitEntryEntity` / `HabitEntryDto` — Day Note support

The `note` field already exists on `HabitEntryEntity` (`String? note`). 
**No new field is needed here.** The note on each entry IS the "day note."
However the field has never been surfaced in the UI. PROD-03 will wire it up.

#### 3. New entity: `DayNoteEntity` / `DayNoteDto`

A second note store scoped to a calendar day (not per-entry), for PROD-03's
"how did the day go overall" note. This is separate from per-entry notes.

| Field | Type | Nullable | Notes |
|---|---|---|---|
| `obId` | `int` | no | ObjectBox `@Id()` |
| `id` | `String` | no | `@Unique @Index` UUID |
| `habitId` | `String` | no | `@Index` — which habit this note belongs to |
| `date` | `int` | no | `@Index` — epoch ms of the day (midnight UTC) |
| `note` | `String` | no | The actual note text |
| `createdAt` | `int` | no | Epoch ms |
| `updatedAt` | `int` | no | Epoch ms — updated on every save |

#### 4. New entity: `AiSettingsEntity` / `AiSettingsDto`

Stores user's LLM API configuration (for PROD-04). A singleton row (only one
row ever exists; load with `getAll().firstOrNull`).

| Field | Type | Nullable | Notes |
|---|---|---|---|
| `obId` | `int` | no | ObjectBox `@Id()` |
| `apiEndpoint` | `String` | no | Full base URL (e.g. `https://generativelanguage.googleapis.com/v1beta`) |
| `apiKey` | `String` | no | Raw key — stored locally only |
| `selectedPersona` | `String?` | yes | One of: `sakuta`, `vegeta`, `dumbledore`, `spiderman`, `nietzsche`, or `null` for no persona |
| `updatedAt` | `int` | no | Epoch ms |

#### 5. New entity: `QuoteEntity` / `QuoteDto`

Stores the pool of splash-screen quotes (for PROD-05).

| Field | Type | Nullable | Notes |
|---|---|---|---|
| `obId` | `int` | no | ObjectBox `@Id()` |
| `id` | `String` | no | `@Unique` UUID |
| `text` | `String` | no | Quote body |
| `author` | `String?` | yes | Attribution (optional) |
| `dayOfYear` | `int?` | yes | 1–366. If set, only show on that day. If null, show randomly. |
| `isActive` | `bool` | no | Default `true`; allows toggling quotes off |

**Seed quotes on first launch** (check `QuoteBox.count() == 0`) with the
sample list provided in PROD-05.

**Acceptance criteria for PROD-01:**
- [x] `HabitEntity` has `description` and `isOneTime` and `completedAt` fields.
- [x] `HabitDto` mirrors above; `copyWith`, `toJson`, `fromJson`, `==`, `hashCode` all updated.
- [x] `DayNoteEntity` and `DayNoteDto` exist and are registered in `app_database.dart`.
- [x] `AiSettingsEntity` and `AiSettingsDto` exist and are registered.
- [x] `QuoteEntity` and `QuoteDto` exist and are registered.
- [x] Run `flutter pub run build_runner build --delete-conflicting-outputs` and commit the regenerated `objectbox.g.dart` and `objectbox-model.json`.
- [x] `flutter analyze lib/` → 0 errors, 0 warnings.
- [x] `flutter test` → all tests pass (update existing tests to pass new required fields with sensible defaults).

---

### PROD-02 — One-time task support

**Priority:** P0 — depends on PROD-01.

**Goal:** Let the user mark any new entry as a "one-time task" instead of a
recurring habit. No separate screen; the existing Add Habit screen gains a
small toggle at the top.

**Spec:**

#### Add screen (`add_habit_screen.dart`)

1. At the very top of the form (above the habit name field), add a compact
   **segmented toggle / tab bar** with exactly two options:
   - `Habit` (default, selected on screen open)
   - `One-time Task`
2. The toggle uses `AppColors` surface tokens and `habitColor` accent for the
   selected chip. Keep it visually minimal — two rounded chips side by side,
   full row width, 40 px height.
3. When **"One-time Task"** is selected:
   - The "Schedule" section (days of week / frequency) is **hidden** (animated
     collapse, `AnimatedSize`).
   - The "Target value / Unit" fields remain — a one-time task can still be
     numeric (e.g. "finish 5 chapters today").
   - `isOneTime = true` is written to `HabitDto` on save.
4. When **"Habit"** is selected (default):
   - Full form shown as today. `isOneTime = false`.
5. Validation: one-time tasks require a name. All other fields optional.

#### Home screen (`home_screen.dart`)

1. One-time tasks appear in the **same list** as habits, not a separate section.
2. On the card, show a small pill/badge label **"One-time"** using a muted
   `AppColors.onSurface.withValues(alpha: 0.5)` tint so it reads as secondary
   info.
3. When a one-time task is checked ✅ (`completedAt` is set), the card gets a
   subtle strikethrough on the name and 50 % opacity, so the user can see it's
   done. It is **not** removed from the list automatically — the user can
   delete it when ready.
4. One-time tasks do **not** show the Heatmap panel (meaningless for single
   entries). They show only: Details + History (single entry). The circular
   panel navigation skips Heatmap for `isOneTime == true`.

**Acceptance criteria for PROD-02:**
- [ ] Toggle appears at top of Add screen; defaults to "Habit."
- [ ] Schedule section animates in/out based on toggle selection.
- [ ] Saving with "One-time Task" sets `isOneTime = true` in ObjectBox.
- [ ] Home screen renders one-time task cards with "One-time" badge.
- [ ] Checked one-time tasks show strikethrough + reduced opacity.
- [ ] Heatmap panel hidden for one-time tasks.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-03 — Descriptions + Day Notes

**Priority:** P1 — depends on PROD-01.

**Goal:** (a) Add optional description field to habits/tasks.
         (b) Surface per-day notes on the expanded card.

#### Part A — Descriptions (`add_habit_screen.dart` + `HabitDto`)

1. In the Add / Edit Habit screen, add a **description `TextField`** placed
   immediately **below the icon picker row**.
2. Styling: wide, short (max 3 visible lines, scrollable), placeholder text
   `"Add a reason or description (optional)"`, uses existing `AppColors`
   input decoration. Border matches the name field style.
3. `maxLength`: 300 characters. Show character counter only when focused.
4. On save / edit-save, persist `description` to `HabitDto` / `HabitEntity`.
5. In the **expanded habit card Details panel** (`details_panel.dart`), if
   `description` is non-null and non-empty, show it in a small italic text
   block below the habit name. If null/empty, omit the block entirely.

#### Part B — Day Notes

**Trigger:** Long-pressing a habit card already enters selection mode. Extend
this so that when selection mode is active for a **single selected** card, a
**notepad icon button** appears in the card header (left side of the row,
before the habit name).

> [!NOTE]
> Do not change the existing long-press → selection mode behaviour. The
> notepad button is an additional affordance that appears only when exactly
> one card is in the selected state.

1. Tapping the notepad icon opens a **bottom sheet** (`DayNoteBottomSheet`):
   - Title: today's date formatted as `"Note for Mon, 20 Oct"`
   - Large `TextField` (multiline, min 4 lines, max 10 lines visible).
   - "Save" button and "Cancel" button.
   - Pre-populates with existing note for that habit + today if one exists.
2. On save: upsert a `DayNoteEntity` (habitId + today midnight UTC as key).
3. The saved note is surfaced in the **expanded habit card** as a new panel
   called **"Notes"** in the circular panel navigator (between Statistics and
   any existing last panel). The Notes panel shows:
   - A scrollable list of the most recent 7 day-notes for this habit.
   - Each note shows: date header, note text. Oldest at bottom, newest at top.
   - If no notes exist: placeholder text `"No notes yet. Hold the card to add one."`.
4. Repository: create `DayNoteRepository` in
   `lib/data/repositories/day_note_repository.dart` with:
   - `upsertNote(DayNoteDto dto) → Future<void>`
   - `getNotesForHabit(String habitId, {int limit = 7}) → Future<List<DayNoteDto>>`
   - `deleteNote(String noteId) → Future<void>`
5. Provider: add `dayNoteRepositoryProvider` and `habitDayNotesProvider(habitId)`
   in `lib/application/providers/`.

**Acceptance criteria for PROD-03:**
- [ ] Description field present in Add/Edit screen below icon picker.
- [ ] Description persists and displays in expanded Details panel.
- [ ] Notepad icon appears in card header only when that card is selected (single selection).
- [ ] Bottom sheet opens, pre-fills existing note, saves correctly.
- [ ] Notes panel appears in carousel; shows up to 7 recent notes.
- [ ] `DayNoteRepository` has all three methods implemented and tested.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-04 — LLM / AI Layer

**Priority:** P1 — depends on PROD-01.

**Goal:** Let the user connect any OpenAI-compatible API endpoint, choose a
persona, and have a chat conversation about their habits, powered by the live
ObjectBox data.

#### 4.1 Settings entry point (`settings_screen.dart`)

Add a settings row labelled **"AI Suggestions"** (use a brain/sparkle icon).
Tapping it navigates to the new `AiSettingsScreen`.

#### 4.2 `AiSettingsScreen` (`lib/presentation/screens/ai/ai_settings_screen.dart`)

Layout (top to bottom):

1. **API Endpoint field** — `TextField`, placeholder `"https://..."`,
   keyboard type URL, stores to `AiSettingsDto.apiEndpoint`.
2. **API Key field** — `TextField`, obscure text, placeholder `"sk-..."`,
   stores to `AiSettingsDto.apiKey`. Show a small eye-toggle icon.
3. **"Save" button** — persists `AiSettingsEntity` to ObjectBox.
4. Divider + section header: **"Persona (optional)"**
5. **Persona grid**: 2-column grid of persona cards. Each card shows:
   - Character name
   - Short 1-sentence tagline (see list below)
   - A selection ring when active (uses `habitColor`-style accent, here use
     the app's orange accent `AppColors.primary`).
   - Selecting a card sets `selectedPersona`; selecting the same card again
     deselects (sets to `null` — "no persona / default").
6. **"Start Chat" button** (bottom, primary style) — navigates to `AiChatScreen`.
   Disabled if `apiEndpoint` or `apiKey` is empty.

#### 4.3 Personas — full system prompt catalogue

Store these verbatim as constants in
`lib/presentation/screens/ai/ai_personas.dart`:

```
PERSONA_SAKUTA
Name: Sakuta Azusagawa
Tagline: Laid-back, warm, and oddly wise.
System prompt:
"You are Sakuta Azusagawa from 'Rascal Does Not Dream of Bunny Girl Senpai'.
You help the user reflect on their habits in a calm, cheerful, and supportive way.
You listen carefully, ask thoughtful follow-up questions, and create a safe space
where the user feels comfortable talking about their struggles. You are respectful,
never dismissive, and always a little dry-witted. Never say anything inappropriate.
The user's habit data will be provided at the start of the conversation; use it
to give personalised observations."

PERSONA_VEGETA
Name: Vegeta
Tagline: The Prince of all Saiyans demands your best.
System prompt:
"You are Vegeta, Prince of all Saiyans. You are proud, fiercely competitive, and
will accept nothing less than absolute effort. You push the user to be stronger
every single day. You acknowledge no excuses, only results. Your tone is sharp and
demanding — but underneath it all, you know that pushing people hard is how they
grow. Use the user's habit data to call out weakness and demand improvement."

PERSONA_DUMBLEDORE
Name: Albus Dumbledore
Tagline: Ancient wisdom, patient guidance.
System prompt:
"You are Albus Dumbledore, Headmaster of Hogwarts, the greatest sorcerer of the
age. You speak with patience, warmth, and a gravity that makes every word feel
meaningful. You draw on deep wisdom to gently guide the user toward better habits,
using metaphor, reflection, and the occasional touch of gentle humour. Use the
user's habit data as your 'pensive' — a window into their inner world — and help
them understand themselves better."

PERSONA_SPIDERMAN
Name: Peter Parker / Spider-Man
Tagline: With great power comes great responsibility.
System prompt:
"You are Peter Parker — Spider-Man. Life hasn't been easy for you: loss, hardship,
and sacrifice have followed you everywhere. And yet, every single time, you get
back up. You inspire the user with that same resilience: no matter how many times
they've failed their habit goals, what matters is that they keep showing up. Your
tone is warm, relatable, a little self-deprecating, and deeply encouraging.
Use the user's habit data to remind them that being their best self is always
worth the effort."

PERSONA_NIETZSCHE
Name: Friedrich Nietzsche
Tagline: Become who you are — ruthlessly.
System prompt:
"You are Friedrich Nietzsche — the philosopher, the hammer, the prophet of the
Übermensch. You do not console; you confront. You strip away comfortable illusions
and present the user with the raw truth of their habits and choices. Your words
carry weight, your insights are sharp, and your standard is nothing less than the
ideal: the Übermensch — the person who creates their own values and masters
themselves absolutely. Reference Nietzsche's philosophy: the will to power, eternal
recurrence, amor fati, self-overcoming. Speak with authority and poetic force.
This app is named after your philosophy — live up to it. Use the user's habit data
to deliver an honest, unflinching assessment."
```

#### 4.4 `AiChatScreen` (`lib/presentation/screens/ai/ai_chat_screen.dart`)

1. **System message construction** (sent as the first message, never shown to user):
   - Persona system prompt (if selected), or a neutral default: `"You are a
     helpful habit-tracking assistant. Be concise and supportive."`.
   - Followed by a structured data dump of all habits + recent 30 days of
     entries, formatted as human-readable plain text (not raw JSON). Example
     structure:
     ```
     === User Habit Data (last 30 days) ===
     Habit: "Morning Run" | Type: boolean | Streak: 5 days
       Mon 14 Oct: ✅  Tue 15 Oct: ✅  ...
     Habit: "Water intake" | Type: numeric | Unit: glasses | Target: 8
       Mon 14 Oct: 7  Tue 15 Oct: 8  ...
     One-time Task: "Read 50 pages" | Status: Pending
     ===
     ```
2. **Chat UI**: standard bubble layout.
   - User messages: right-aligned, `AppColors.primary` background.
   - AI messages: left-aligned, `AppColors.surface` background.
   - Scrollable `ListView` that snaps to the bottom on new messages.
3. **Input row** at the bottom: `TextField` + send `IconButton`.
4. **HTTP call**: use `http` package (already in `pubspec.yaml` — add if
   missing). POST to `{apiEndpoint}/chat/completions` with:
   ```json
   {
     "model": "gemini-2.0-flash",
     "messages": [ ... full history ... ]
   }
   ```
   Include `Authorization: Bearer {apiKey}` header.
   This is deliberately generic so it works with any OpenAI-compatible endpoint
   (Gemini, OpenAI, Groq, etc.).
5. Show a loading indicator (three animated dots) while awaiting response.
6. Error handling: on HTTP error, show a `SnackBar` with the error message.
   Do not crash.

#### 4.5 Data formatter

Create `lib/application/services/ai_data_formatter.dart` with a single
static method:
```dart
static String formatHabitsForAi(List<HabitDto> habits, Map<String, List<HabitEntryDto>> entries)
```
Returns the plain-text structured dump described in 4.4.

**Acceptance criteria for PROD-04:**
- [ ] "AI Suggestions" row visible in Settings screen.
- [ ] `AiSettingsScreen` saves endpoint + key + persona to ObjectBox.
- [ ] All 5 persona cards render with correct names and taglines.
- [ ] Selecting / deselecting a persona updates stored `selectedPersona`.
- [ ] `AiChatScreen` constructs and sends system message with habit data on first open.
- [ ] Chat bubbles render correctly; scroll to bottom on new message.
- [ ] HTTP errors shown as SnackBar; app does not crash.
- [ ] `AiDataFormatter.formatHabitsForAi` covered by a unit test.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-05 — Splash screen + Quotes

**Priority:** P1 — depends on PROD-01 (QuoteEntity).

**Goal:** Replace the default Flutter splash with a branded screen featuring
the Overman silhouette and a rotating quote.

#### 5.1 Splash screen (`lib/presentation/screens/splash/splash_screen.dart`)

Layout (full screen, `AppColors.background` background):

1. **Centre visual** — a `Container` with `BorderRadius.circular(24)` and
   dimensions ~280 × 320 px (responsive: 65 % of screen width, max 300 px).
   Background: very dark card (`AppColors.surface`). 
   Content: a stylised vector/icon of a muscular man viewed from the back,
   looking over his shoulder. Until a proper asset exists, use the `Icons.fitness_center`
   icon at 120 px in `AppColors.primary` as a placeholder, centred in the box.
   > [!NOTE]
   > The final asset will be provided by the user later. Use the icon placeholder
   > for now but structure the code so that swapping in an `Image.asset` requires
   > only changing one widget.
2. **Quote text** — below the visual box, with 32 px vertical gap.
   - Italic, `Montserrat` 15 sp, `AppColors.onBackground.withValues(alpha: 0.75)`.
   - Max 3 lines, centered, soft wrap.
   - Attribution on the next line, smaller (12 sp), muted.
3. **Quote selection logic** (in `QuoteService`):
   - On splash open, query `QuoteBox` for today's day-of-year.
   - If any quote has `dayOfYear == today`, pick the first matching one.
   - Otherwise, pick a random active quote (`isActive == true`).
   - If the box is empty, show the hardcoded fallback:
     *"Become who you are." — Friedrich Nietzsche*
4. **Navigation**: after a 2.5-second delay (`Future.delayed`), navigate to
   `/home` using `GoRouter`. No user interaction required.

#### 5.2 Seed quotes (insert on first launch via `QuoteSeeder`)

Create `lib/data/seeders/quote_seeder.dart`. Call `QuoteSeeder.seedIfEmpty(store)`
in `main.dart` before `runApp`.

Initial seed pool (sample — user will extend this later):

| # | Text | Author | dayOfYear |
|---|---|---|---|
| 1 | "Become who you are." | Friedrich Nietzsche | null |
| 2 | "He who has a why to live can bear almost any how." | Friedrich Nietzsche | null |
| 3 | "Without music, life would be a mistake." | Friedrich Nietzsche | null |
| 4 | "It does not matter how slowly you go as long as you do not stop." | Confucius | null |
| 5 | "We are what we repeatedly do. Excellence, then, is not an act but a habit." | Aristotle | null |
| 6 | "With great power comes great responsibility." | Uncle Ben | null |
| 7 | "Push beyond your limits. That's what makes a Super Saiyan." | Vegeta | null |
| 8 | "It is our choices that show what we truly are, far more than our abilities." | Albus Dumbledore | null |

#### 5.3 Router update

In `app_router.dart`, add `/splash` as the **initial route**. The splash
screen navigates to `/home` after its delay. Adjust the initial location from
`/home` to `/splash`.

**Acceptance criteria for PROD-05:**
- [ ] App opens to splash screen (not the Flutter logo).
- [ ] Overman icon/placeholder renders in a rounded container.
- [ ] A quote from the seed pool displays below.
- [ ] After 2.5 s the app navigates automatically to `/home`.
- [ ] `QuoteSeeder` seeds exactly the 8 quotes above (or more, if user adds) only once.
- [ ] `QuoteService.pickQuote()` covered by a unit test (day-match + random fallback).
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-06 — Export/Import infrastructure (data integrity foundation)

**Priority:** P2 — not blocked by other production tasks but critical before
any cloud or sharing features.

**Goal:** Replace export stubs in Settings with real implementations; lay
groundwork for future CSV/JSON import.

#### Export (real implementation)

- **CSV export**: all habits + all entries, two CSV files zipped together
  (`habits.csv` + `entries.csv`), saved to the device Downloads folder via
  `path_provider` + `share_plus`.
- **JSON export**: a single JSON file with the full data graph
  (`{ habits: [...], entries: [...], schedules: [...], limits: [...] }`).
- **XLSX export**: two sheets (Habits, Entries) using the `excel` package.

#### Import (stub + UI only — no parsing logic yet)

- Add an "Import Data" row in Settings.
- Tapping it opens a `FilePicker` dialog (CSV or JSON).
- On file selection, show a confirmation dialog: *"Import will merge data.
  Continue?"*
- On confirm: show a `SnackBar`: *"Import coming soon."*
- The architecture (repository `importHabits(List<HabitDto>)`) should be
  stubbed so future tasks can fill it in.

**Acceptance criteria for PROD-06:**
- [ ] CSV, JSON, XLSX exports produce real files on device.
- [ ] Import row visible in Settings; file picker works; confirmation shown.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

## Data model — complete field reference

### `HabitEntity` (ObjectBox) — after PROD-01

```
obId         int          @Id
id           String       @Unique @Index  (UUID)
name         String
type         String                       ("boolean" | "numeric")
unit         String?
targetValue  double?
colorHex     String                       ("#RRGGBB")
iconName     String
description  String?      NEW
isOneTime    bool         NEW             (default false)
completedAt  int?         NEW             (epoch ms, one-time tasks only)
createdAt    int                          (epoch ms)
isArchived   bool
──── relations ────
entries      ToMany<HabitEntryEntity>
limits       ToMany<HabitLimitEntity>
schedules    ToMany<HabitScheduleEntity>
```

### `HabitEntryEntity` (ObjectBox) — unchanged

```
obId       int     @Id
id         String  @Unique @Index
habitId    String  @Index
date       int     (epoch ms)
value      double
note       String? (already exists — surfaced in PROD-03)
createdAt  int
──── relations ────
habitEntity  ToOne<HabitEntity>
```

### `DayNoteEntity` (ObjectBox) — NEW in PROD-01

```
obId       int     @Id
id         String  @Unique @Index
habitId    String  @Index
date       int     @Index  (midnight UTC epoch ms)
note       String
createdAt  int
updatedAt  int
```

### `AiSettingsEntity` (ObjectBox) — NEW in PROD-01

```
obId             int     @Id
apiEndpoint      String
apiKey           String
selectedPersona  String?
updatedAt        int
```

### `QuoteEntity` (ObjectBox) — NEW in PROD-01

```
obId       int     @Id
id         String  @Unique
text       String
author     String?
dayOfYear  int?    (1–366; null = random)
isActive   bool
```

---

## File change map (expected files per task)

| Task | Files to create | Files to modify |
|---|---|---|
| PROD-01 | `habit_entity.dart`, `habit_dto.dart`, `day_note_entity.dart`, `day_note_dto.dart`, `ai_settings_entity.dart`, `ai_settings_dto.dart`, `quote_entity.dart`, `quote_dto.dart`, `app_database.dart` | `objectbox.g.dart` (regen), `objectbox-model.json` (regen) |
| PROD-02 | — | `add_habit_screen.dart`, `home_screen.dart`, `habit_card.dart` |
| PROD-03 | `day_note_repository.dart`, `day_note_bottom_sheet.dart`, `notes_panel.dart` | `add_habit_screen.dart`, `habit_card.dart`, `details_panel.dart`, providers barrel |
| PROD-04 | `ai_settings_screen.dart`, `ai_chat_screen.dart`, `ai_personas.dart`, `ai_data_formatter.dart` | `settings_screen.dart`, `app_router.dart` |
| PROD-05 | `splash_screen.dart`, `quote_seeder.dart`, `quote_service.dart` | `app_router.dart`, `main.dart` |
| PROD-06 | `export_service.dart`, `import_service.dart` (stub) | `settings_screen.dart` |

---

## Known bugs / deferred items

| Issue | Severity | Notes |
|---|---|---|
| One-off tasks skipped in prototype | MEDIUM | Addressed in PROD-02 |
| `note` field on `HabitEntryEntity` never surfaced | LOW | Surfaced in PROD-03 |
| Export stubs (CSV, JSON, XLSX) not real | MEDIUM | Addressed in PROD-06 |
| 37 `avoid_print` lint infos in test/tool files | LOW | Ignore for now |
| Splash screen shows Flutter logo | LOW | Addressed in PROD-05 |
| No AI layer | — | Addressed in PROD-04 |

---

## Decisions made

| Date | Decision | Reason |
|---|---|---|
| 2026-10-20 | One-time tasks use `isOneTime` bool, not a new `HabitType` enum value | Preserves existing type semantics; one-time tasks can still be boolean or numeric |
| 2026-10-20 | `DayNoteEntity` is separate from `HabitEntryEntity.note` | Entry notes are per-completion log; day notes are freeform daily journal entries scoped to a habit |
| 2026-10-20 | AI layer uses OpenAI-compatible chat completions API | Works with Gemini, OpenAI, Groq, and any proxy — user chooses the endpoint |
| 2026-10-20 | Persona selection is optional; null = no persona | User should not be forced into a character voice |
| 2026-10-20 | Splash screen visual is a placeholder icon until user provides the final asset | Ship the mechanism; swap the asset later with one widget change |
| 2026-10-20 | Quote seed pool lives in `QuoteSeeder`; seeded once on first launch | Allows future quote management via UI without code changes |

---

## Update instructions for coding agents

1. **Read this file, `PROJECT_BRIEF.md`, and `DESIGN.md` before touching code.**
2. Implement **one task at a time** in the order listed (PROD-01 → PROD-02 → …).
   Do not skip ahead; each task has dependency notes.
3. After every code change run **`flutter analyze lib/`** — 0 errors required.
4. After any change to domain or data layers run **`flutter test`** — all tests must pass.
5. After `@Entity` changes always run **`flutter pub run build_runner build --delete-conflicting-outputs`** and commit the generated files.
6. Record **actual** observed output (copy-paste command output), never intentions.
7. Update the **"Latest completed task"** and **"Current task"** sections below.
8. Never delete historical task records — preserve the log.
9. If a task fails or a blocker is hit, document it clearly and preserve the last known working state (commit hash or file backup).
10. When editing `objectbox-model.json`, never remove existing entity IDs or property IDs — ObjectBox uses them for migration.

---

## Latest completed task

**Task ID:** PROD-01 — Data model expansion

- Implemented:
  - `HabitEntity` (`lib/data/database/habit_entity.dart`): Added `description` (`String?`), `isOneTime` (`bool`, default `false`), and `completedAt` (`int?`).
  - `HabitDto` (`lib/data/models/dtos/habit_dto.dart`): Added `description`, `isOneTime`, and `completedAt` with updated `copyWith`, `toJson`, `fromJson`, `operator ==`, `hashCode`, and `toString`.
  - `DayNoteDto` (`lib/data/models/dtos/day_note_dto.dart`) & `DayNoteEntity` (`lib/data/database/day_note_entity.dart`): Scoped day note with `id`, `habitId`, `date`, `note`, `createdAt`, `updatedAt`.
  - `AiSettingsDto` (`lib/data/models/dtos/ai_settings_dto.dart`) & `AiSettingsEntity` (`lib/data/database/ai_settings_entity.dart`): LLM API settings singleton storing `apiEndpoint`, `apiKey`, `selectedPersona`, and `updatedAt`.
  - `QuoteDto` (`lib/data/models/dtos/quote_dto.dart`) & `QuoteEntity` (`lib/data/database/quote_entity.dart`): Splash quote pool model storing `id`, `text`, `author`, `dayOfYear`, and `isActive`.
  - Registered all new entities and added typed box accessors in `lib/data/database/app_database.dart` (`habitBox`, `habitEntryBox`, `habitLimitBox`, `habitScheduleBox`, `dayNoteBox`, `aiSettingsBox`, `quoteBox`).
  - Exported all new DTOs in `lib/data/models/dtos/dtos.dart`.
  - Regenerated `lib/objectbox.g.dart` and `lib/objectbox-model.json` via `dart run build_runner build --delete-conflicting-outputs`.
  - Added comprehensive entity mapping, CRUD, and DTO round-trip tests to `test/database_test.dart`.
- Files changed:
  - `lib/data/database/habit_entity.dart` (modified)
  - `lib/data/models/dtos/habit_dto.dart` (modified)
  - `lib/data/database/day_note_entity.dart` (created)
  - `lib/data/models/dtos/day_note_dto.dart` (created)
  - `lib/data/database/ai_settings_entity.dart` (created)
  - `lib/data/models/dtos/ai_settings_dto.dart` (created)
  - `lib/data/database/quote_entity.dart` (created)
  - `lib/data/models/dtos/quote_dto.dart` (created)
  - `lib/data/database/app_database.dart` (modified)
  - `lib/data/models/dtos/dtos.dart` (modified)
  - `lib/objectbox.g.dart` (regenerated)
  - `lib/objectbox-model.json` (regenerated)
  - `test/database_test.dart` (modified)
  - `test/widget_test.dart` (modified)
- Tests/checks run:
  - `flutter analyze lib/` → `No issues found! (ran in 4.1s)`
  - `flutter test` → `All tests passed! (86/86 passed)`
- Observed result:
  - Zero analysis errors or warnings in `lib/`.
  - All 86 tests pass across database, repository, domain, and widget suites.

## Current task

**PROD-02** — One-time task support

- Status: Not started
- Goal: Add toggle to Add Habit screen, conditionally show/hide schedule section, render "One-time" badge, strikethrough/opacity upon completion on HabitCard, and adjust panel sequence to omit Heatmap for one-time tasks.

## Next action

Execute **PROD-02**: Update `add_habit_screen.dart`, `habit_card.dart`, and `home_screen.dart` to support one-time tasks.
