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
- Branch/commit: `overman` (ea99957 — PROD-03 complete)
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
- [x] Toggle appears at top of Add screen; defaults to "Habit."
- [x] Schedule section animates in/out based on toggle selection.
- [x] Saving with "One-time Task" sets `isOneTime = true` in ObjectBox.
- [x] Home screen renders one-time task cards with "One-time" badge.
- [x] Checked one-time tasks show strikethrough + reduced opacity.
- [x] Heatmap panel hidden for one-time tasks.
- [x] `flutter analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass.

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
- [x] Description field present in Add/Edit screen below icon picker.
- [x] Description persists and displays in expanded Details panel.
- [x] Notepad icon appears in card header only when that card is selected (single selection).
- [x] Bottom sheet opens, pre-fills existing note, saves correctly.
- [x] Notes panel appears in carousel; shows up to 7 recent notes.
- [x] `DayNoteRepository` has all three methods implemented and tested.
- [x] `flutter analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass.

---

### PROD-04 — LLM / AI Layer

**Priority:** P1 — depends on PROD-01.

**Goal:** Let the user connect any OpenAI-compatible API endpoint, choose a persona with a character profile picture, control how much historical data is sent, persist conversation history, and have an immersive chat experience about their habits.

> [!IMPORTANT]
> PROD-04 is divided into **4 explicit sub-stages** (04-A → 04-D). Execute them in order.
> Do not combine sub-stages into a single commit. Each sub-stage has its own acceptance criteria.

---

### PROD-04-A — Data formatter + Preview tool

**Priority:** P0 within PROD-04 — all other sub-stages depend on this.

**Goal:** Build `AiDataFormatter`, wire it to live ObjectBox data, and produce a
**console-visible and document-exportable preview** of exactly what will be sent
to the LLM. The agent must run the preview script and paste the actual output
into the task log before marking this sub-stage done.

#### A.1 Schema additions to `AiSettingsEntity` / `AiSettingsDto`

Add two new fields (extend the existing entity, run build_runner after):

| Field | Type | Default | Notes |
|---|---|---|---|
| `contextWindowDays` | `int` | `30` | Number of past days of entry data to include. |
| `contextWindowUnit` | `String` | `"days"` | One of `"days"` or `"weeks"` (store as string, convert on read). |

> [!NOTE]
> `contextWindowDays` stores the raw integer. When unit is `"weeks"`, the UI shows
> the value as weeks (e.g. 4 = 4 weeks = 28 days internally). The formatter always
> works in calendar days.

#### A.2 `AiDataFormatter` (`lib/application/services/ai_data_formatter.dart`)

Static class. Single public method:

```dart
class AiDataFormatter {
  /// Formats [habits] and their [entriesByHabitId] (only entries within
  /// [windowDays] calendar days back from [today]) into a plain-text block
  /// suitable for sending to an LLM as part of a system prompt.
  ///
  /// [dayNotesByHabitId] is optional — include if not null/empty.
  static String format({
    required List<HabitDto> habits,
    required Map<String, List<HabitEntryDto>> entriesByHabitId,
    Map<String, List<DayNoteDto>>? dayNotesByHabitId,
    required int windowDays,
    DateTime? today,         // injectable for testability; defaults to DateTime.now()
  })
}
```

**Output format (exact structure — copy this verbatim into the implementation):**

```
=== User Habit Data (last {windowDays} days) ===
Generated: {Mon, 20 Oct 2026}

--- Habit: "Morning Run" ---
Type: Habit (boolean) | Schedule: Daily | Streak: 5 days | Started: 1 Jan 2026
Description: Run at least 3 km each morning to build cardiovascular endurance.
  Mon 14 Oct ✅   Tue 15 Oct ✅   Wed 16 Oct ❌   Thu 17 Oct ✅   Fri 18 Oct ✅
  Sat 19 Oct ✅   Sun 20 Oct —
  Notes:
    [Mon 14 Oct] "Felt strong today, hit 4 km."
    [Wed 16 Oct] "Skipped due to rain."

--- Habit: "Water Intake" ---
Type: Habit (numeric) | Unit: glasses | Target: 8 | Schedule: Daily | Streak: 3 days
  Mon 14 Oct  7   Tue 15 Oct  8 ✅  Wed 16 Oct  5   Thu 17 Oct  8 ✅  Fri 18 Oct  8 ✅
  Sat 19 Oct  6   Sun 20 Oct  —

--- One-time Task: "Read 50 Pages" ---
Status: ✅ Completed on Mon 14 Oct 2026
Description: Finish chapter 3 of Atomic Habits.

--- One-time Task: "File Taxes" ---
Status: ⏳ Pending

===
```

**Rules for the formatter:**
- Entries outside `[today - windowDays, today]` are excluded.
- Dates with no entry show `—`.
- Boolean completed entries show `✅`; boolean missed (value == 0) show `❌`.
- Numeric entries show the raw value; if value >= target, append `✅`.
- For one-time tasks, skip the entry day grid. Show status and completedAt only.
- Day notes for a habit are shown under the entry grid (if any notes exist for
  the window period).
- Descriptions are shown when non-null/non-empty.
- If no habits exist, return `"No habit data available."`.

#### A.3 Preview script (`test/tools/ai_data_preview.dart`)

Create a standalone Dart script (not a `testWidgets` test — a plain `void main()`)
that:
1. Opens the app's real ObjectBox store via `AppDatabase.openStore()`.
2. Fetches all habits via `HabitRepository.getAllHabits()`.
3. Fetches entries for each habit for the last 30 days via `HabitEntryRepository`.
4. Fetches day notes for each habit via `DayNoteRepository.getNotesForHabit`.
5. Calls `AiDataFormatter.format(...)` with the live data.
6. Prints the result to stdout (plain text — no ANSI colours).
7. Also writes the result to `test/tools/ai_data_preview_output.txt`.

Run with: `dart run test/tools/ai_data_preview.dart`

The agent **must** run this script and paste the actual terminal output into the
task log of PROD-04-A before marking it done.

#### A.4 Unit tests (`test/application/ai_data_formatter_test.dart`)

- Test with 0 habits → returns `"No habit data available."`.
- Test with 1 boolean habit, 3 entries in window → correct ✅/❌/— grid.
- Test with 1 numeric habit, entry at target → appends ✅.
- Test with description and day notes → both appear in output.
- Test with `windowDays = 7` → entries older than 7 days not shown.
- Test date injection (`today` parameter) ensures deterministic output.

**Acceptance criteria for PROD-04-A:**
- [x] `AiSettingsEntity` / `AiSettingsDto` have `contextWindowDays` (default 30) and `contextWindowUnit` (default `"days"`).
- [x] `build_runner` run cleanly after entity change; 0 conflicts.
- [x] `AiDataFormatter.format(...)` implemented with exact output format above.
- [x] Preview script runs: `dart run test/tools/ai_data_preview.dart` produces output.
- [x] Actual terminal output pasted into task log (copy of real output, not a mock).
- [x] `ai_data_preview_output.txt` written to `test/tools/`.
- [x] All unit tests in `ai_data_formatter_test.dart` pass.
- [x] `flutter analyze lib/` → 0 issues.
- [x] `flutter test` → all tests pass.

---

### PROD-04-B — AiSettings screen + context window control

**Priority:** Depends on PROD-04-A.

**Goal:** Surface the AI configuration in Settings, let the user set their API
credentials, choose a persona (with character avatar), and control how many
days/weeks of history to send.

#### B.1 Settings entry point

In `settings_screen.dart`, add a new settings tile **above** the DATA EXPORT section:

```
Section header: AI ASSISTANT
Row: brain/spark icon | "AI Assistant"  | subtitle: "Chat with your habit data" | › chevron
```

Tapping navigates to `AiSettingsScreen`.

#### B.2 `AiSettingsScreen` layout

File: `lib/presentation/screens/ai/ai_settings_screen.dart`

Scrollable column:
1. **API CONFIGURATION** section header.
2. **API Endpoint** `TextField` — placeholder `"https://generativelanguage.googleapis.com/v1beta"`, keyboard URL type. Saved to `AiSettingsEntity.apiEndpoint`.
3. **API Key** `TextField` — obscured, placeholder `"Your API key"`. Trailing eye-toggle icon. Saved to `AiSettingsEntity.apiKey`.
4. **Save** `ElevatedButton` — persists to ObjectBox. Shows SnackBar `"Settings saved"` on success.
5. Divider.
6. **CONTEXT WINDOW** section header + descriptive subtitle: *"How much of your habit history to share with the AI"*.
7. **Context slider**: a `Slider` from 1→90 days. Current value shown as a label:
   - Display format: if value < 14, show `"{n} days"`; if 14–60, show `"{n÷7} weeks"` (round); if >60, show `"All available"`.
   - Label and slider use `AppColors.orange` as active colour.
   - On change, save immediately to `AiSettingsEntity.contextWindowDays`.
8. Divider.
9. **PERSONA** section header + subtitle: *"Choose a character to guide your conversation (optional)"*.
10. **Persona grid**: 2-column `GridView` of persona cards. Each card:
    - **Character avatar image**: loaded from `assets/persona_dps/<filename>` using `Image.asset` with a circular clip (`CircleAvatar` or `ClipOval`). Filenames:
      - `sakuta`: `Sakuta Azusagawa.jfif`
      - `vegeta`: `Vegeta.jpg`
      - `dumbledore`: `Albus Dumbledore.jpg`
      - `spiderman`: `Spider-Man.jpg`
      - `nietzsche`: `Friedrich Nietzsche.jpg`
    - Character **name** (bold, 13 sp).
    - Short **tagline** (11 sp, muted grey, italic).
    - A coloured **border ring** (`AppColors.orange`, width 2.5) when selected; subtle border otherwise.
    - Tapping selects; tapping again deselects (sets to null).
11. **"Start Chat"** `ElevatedButton` at bottom — navigates to `AiChatScreen`.
    - Disabled (greyed out) if `apiEndpoint` or `apiKey` is empty.

> [!IMPORTANT]
> The persona images live in `persona_dps/` at the project root (already placed by user).
> They must be declared in `pubspec.yaml` under `flutter: assets:` as:
> ```yaml
> - assets/persona_dps/
> ```
> And **copied** from the project root `persona_dps/` folder to `assets/persona_dps/`
> during this sub-stage (the agent must do this file copy + pubspec update).

#### B.3 Persona definitions (`lib/presentation/screens/ai/ai_personas.dart`)

```dart
enum PersonaId { sakuta, vegeta, dumbledore, spiderman, nietzsche }

class AiPersona {
  final PersonaId id;
  final String name;
  final String tagline;
  final String assetPath;   // e.g. 'assets/persona_dps/Vegeta.jpg'
  final String systemPrompt;
  const AiPersona({...});
}

const List<AiPersona> kPersonas = [...];
```

System prompts (verbatim from original PROD-04 spec above — copy them here):
- `PERSONA_SAKUTA` — Sakuta Azusagawa
- `PERSONA_VEGETA` — Vegeta
- `PERSONA_DUMBLEDORE` — Albus Dumbledore
- `PERSONA_SPIDERMAN` — Peter Parker / Spider-Man
- `PERSONA_NIETZSCHE` — Friedrich Nietzsche

**Acceptance criteria for PROD-04-B:**
- [ ] `persona_dps/` images copied to `assets/persona_dps/` and declared in `pubspec.yaml`.
- [ ] "AI Assistant" tile appears in Settings screen under its own section.
- [ ] `AiSettingsScreen` saves endpoint + key to ObjectBox on tap of Save.
- [ ] Context slider renders, saves `contextWindowDays` immediately on change.
- [ ] All 5 persona cards render with avatar image, name, tagline, and correct selection ring.
- [ ] Selecting / deselecting updates stored `selectedPersona`.
- [ ] "Start Chat" button is disabled when credentials are empty.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-04-C — AiChat screen + conversation history

**Priority:** Depends on PROD-04-B.

**Goal:** Build the actual chat screen with persona-branded UI, persist conversation
history to ObjectBox, and stream responses from the LLM.

#### C.1 New entity: `AiConversationEntity` / `AiConversationDto`

Add to ObjectBox (run build_runner after):

| Field | Type | Notes |
|---|---|---|
| `obId` | `int` | `@Id` |
| `id` | `String` | `@Unique` UUID — conversation session ID |
| `personaId` | `String?` | One of the `PersonaId` names, or null |
| `contextWindowDays` | `int` | Snapshot of the window at conversation start |
| `createdAt` | `int` | Epoch ms |
| `updatedAt` | `int` | Epoch ms — updated on every new message |

And a separate `AiMessageEntity` / `AiMessageDto`:

| Field | Type | Notes |
|---|---|---|
| `obId` | `int` | `@Id` |
| `id` | `String` | `@Unique` UUID |
| `conversationId` | `String` | `@Index` — FK to conversation |
| `role` | `String` | `"user"` or `"assistant"` |
| `content` | `String` | Message text |
| `createdAt` | `int` | Epoch ms |

#### C.2 `AiConversationRepository` (`lib/data/repositories/ai_conversation_repository.dart`)

```dart
Future<AiConversationDto> createConversation({String? personaId, required int contextWindowDays})
Future<List<AiMessageDto>> getMessages(String conversationId)
Future<AiMessageDto> addMessage({required String conversationId, required String role, required String content})
Future<void> deleteConversation(String conversationId)   // cascade deletes messages
Stream<List<AiConversationDto>> watchAllConversations()  // for future history screen
```

#### C.3 `AiChatScreen` (`lib/presentation/screens/ai/ai_chat_screen.dart`)

**Constructor parameters:**
- `personaId` (`PersonaId?`) — the selected persona, or null
- `conversationId` (`String?`) — if null, creates a new conversation on first message

**Layout:**

1. **AppBar**:
   - If persona selected: circular avatar image (32 px) + character name as title.
   - If no persona: generic brain icon + "AI Assistant" as title.
   - Background: `AppColors.surface`.
   - Trailing: menu button (⋮) with option "Clear conversation" (calls `deleteConversation` after confirm dialog).

2. **Chat bubble list** (`ListView`, reversed = false, controller for auto-scroll):
   - **System message row** (appears first, not from chat API, just informational UI):
     Show a small padded chip/card: *"Context: last {n} days of your habits"* in muted text.
   - **User bubbles**: right-aligned, rounded (`BorderRadius.only(topLeft, topRight, bottomLeft)` circular), `AppColors.blue` background, white text. No avatar.
   - **AI bubbles**: left-aligned, rounded (`BorderRadius.only(topRight, topRight, bottomRight)` — wait, standard: top-left, top-right, bottom-right round, bottom-left squared for first), `AppColors.surface` background, `AppColors.primaryText` colour.
     - **Avatar**: 28 px circular persona image on the far left of the row (if persona); generic robot icon otherwise.
   - **Loading indicator**: when waiting for response, show an AI bubble with three animated dots (use three `AnimatedContainer`s that pulse their opacity: 0.3 → 1.0 → 0.3 staggered by 200 ms each).

3. **Input row** (pinned at bottom above keyboard):
   - `TextField` (no border, hint `"Message..."`, max lines 4 for multiline), expands with content.
   - Send `IconButton` (`Icons.send_rounded`, `AppColors.orange`). Disabled while loading.

#### C.4 System message construction (first message, sent as `role: "system"`, never rendered in UI)

```
{persona system prompt}

=== User Habit Data (last {windowDays} days) ===
{AiDataFormatter.format(...) output}
```

If no persona, use neutral default:
```
You are a helpful, concise habit-tracking assistant. Use the data below to give personalised observations.

=== User Habit Data (last {windowDays} days) ===
{AiDataFormatter.format(...) output}
```

The system message is the **first element** of the `messages` array sent to the API.
It is **stored** in `AiMessageEntity` with `role: "system"` (so it can be replayed
if the conversation is resumed later).

#### C.5 HTTP call

POST to `{apiEndpoint}/chat/completions`:
```json
{
  "model": "gemini-2.0-flash",
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user",   "content": "..." },
    { "role": "assistant", "content": "..." },
    ...
  ]
}
```
Header: `Authorization: Bearer {apiKey}`, `Content-Type: application/json`.

On success: parse `choices[0].message.content`, add to history, save to ObjectBox.
On HTTP error (non-200): show SnackBar with `"Error {statusCode}: {body snippet}"`.
On network error: show SnackBar `"Network error. Check your connection."`.
Never crash.

#### C.6 Auto-scroll behaviour

After every new message (user or assistant), call:
```dart
_scrollController.animateTo(
  _scrollController.position.maxScrollExtent,
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOut,
);
```
Wrap in `WidgetsBinding.instance.addPostFrameCallback`.

**Acceptance criteria for PROD-04-C:**
- [ ] `AiConversationEntity` and `AiMessageEntity` added to ObjectBox schema; build_runner clean.
- [ ] `AiConversationRepository` implemented with all 5 methods.
- [ ] `AiChatScreen` opens with persona avatar in AppBar (or generic icon).
- [ ] System message constructed and stored on first user message.
- [ ] User bubbles right-aligned; AI bubbles left-aligned with persona avatar.
- [ ] Loading dots render while waiting for API response.
- [ ] API call succeeds with a real endpoint; response rendered in bubble.
- [ ] Conversation history persisted to ObjectBox; survives app restart.
- [ ] "Clear conversation" deletes conversation + messages from ObjectBox.
- [ ] Auto-scroll works on new messages.
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

### PROD-04-D — Conversation history list

**Priority:** Depends on PROD-04-C. Can be deferred if P2 is acceptable.

**Goal:** Let the user browse past conversations and resume them.

#### D.1 "History" tab or button in AI Settings screen

Add a "Previous Conversations" row in `AiSettingsScreen` (above "Start Chat").
Tapping navigates to `AiHistoryScreen`.

#### D.2 `AiHistoryScreen` (`lib/presentation/screens/ai/ai_history_screen.dart`)

- Displays a `ListView` of past conversations, ordered by `updatedAt` descending.
- Each row shows:
  - Persona avatar (or robot icon if null) — 40 px circular.
  - Persona name (or "No Persona") — bold.
  - Snippet of last message (first 60 chars) — muted.
  - Relative timestamp ("2 hours ago", "Yesterday") — trailing.
- Swipe-to-delete (with confirm dialog): calls `AiConversationRepository.deleteConversation`.
- Tapping a row opens `AiChatScreen` with that `conversationId` (resumes conversation).

**Acceptance criteria for PROD-04-D:**
- [ ] "Previous Conversations" row visible in `AiSettingsScreen`.
- [ ] `AiHistoryScreen` lists conversations ordered by recency.
- [ ] Each row shows persona avatar, name, message snippet, and relative time.
- [ ] Swipe-to-delete works with confirmation.
- [ ] Tapping a row resumes the conversation (existing messages reload).
- [ ] `flutter analyze lib/` → 0 issues.
- [ ] `flutter test` → all tests pass.

---

**Overall PROD-04 acceptance criteria (all sub-stages):**
- [ ] PROD-04-A complete.
- [ ] PROD-04-B complete.
- [ ] PROD-04-C complete.
- [ ] PROD-04-D complete.
- [ ] `flutter analyze lib/` → 0 issues across all new files.
- [ ] `flutter test` → all tests pass (all new tests included).

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

### `AiSettingsEntity` (ObjectBox) — NEW in PROD-01, extended in PROD-04-A

```
obId                int     @Id
apiEndpoint         String
apiKey              String
selectedPersona     String?
contextWindowDays   int     NEW (default 30)   — calendar days of history to include
contextWindowUnit   String  NEW (default "days") — "days" or "weeks" (display only)
updatedAt           int
```

### `AiConversationEntity` (ObjectBox) — NEW in PROD-04-C

```
obId               int     @Id
id                 String  @Unique  UUID
personaId          String?          one of PersonaId names, or null
contextWindowDays  int              snapshot at conversation start
createdAt          int
updatedAt          int
```

### `AiMessageEntity` (ObjectBox) — NEW in PROD-04-C

```
obId            int     @Id
id              String  @Unique  UUID
conversationId  String  @Index
role            String           "system" | "user" | "assistant"
content         String
createdAt       int
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
| PROD-04 | `ai_settings_screen.dart`, `ai_chat_screen.dart`, `ai_personas.dart`, `ai_data_formatter.dart`, `ai_conversation_repository.dart`, `ai_history_screen.dart` | `settings_screen.dart`, `app_router.dart`, `pubspec.yaml`, `app_database.dart` |
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
| 2026-10-20 | PROD-04 split into 4 sub-stages (04-A: formatter + preview, 04-B: settings + context slider, 04-C: chat + history persistence, 04-D: history list screen) | Each sub-stage has a clear boundary and can be executed and verified independently |
| 2026-10-20 | Context window is user-controlled (1–90 days) with friendly display (days/weeks) | Prevents users from accidentally sending too much data and hitting API token limits |
| 2026-10-20 | Persona images stored in `assets/persona_dps/`, loaded via `Image.asset` | Images provided by user in `persona_dps/` project root; must be copied to assets folder and declared in pubspec |
| 2026-10-20 | Conversation history persisted in ObjectBox (`AiConversationEntity` + `AiMessageEntity`) | Survives app restarts; enables history browsing and conversation resumption |
| 2026-10-20 | System message (persona prompt + habit data) stored as a message with `role: "system"` | Enables conversation replay — the full system context is re-sent to the API when resuming |
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

**Task ID:** PROD-04-A — Data formatter + Preview tool

- Implemented:
  - `lib/data/database/ai_settings_entity.dart`:
    - Added `contextWindowDays` (`int`, default 30) and `contextWindowUnit` (`String`, default `"days"`).
    - Updated `fromDto` and `toDto` mappings.
  - `lib/data/models/dtos/ai_settings_dto.dart`:
    - Added `contextWindowDays` and `contextWindowUnit` fields.
    - Updated `copyWith`, `toJson`, `fromJson`, `operator ==`, `hashCode`, and `toString`.
  - ObjectBox Schema:
    - Ran `dart run build_runner build --delete-conflicting-outputs` cleanly (wrote 24 outputs, updated `objectbox.g.dart` and `objectbox-model.json`).
  - `lib/application/services/ai_data_formatter.dart`:
    - Implemented `AiDataFormatter.format(...)` supporting date windowing, boolean grid (✅/❌/—), numeric formatting with target checks, one-time task status & completion dates, descriptions, and habit day notes.
  - `test/tools/ai_data_preview.dart`:
    - Standalone preview script that queries ObjectBox repositories and prints/writes the exact formatted text.
  - `test/tools/ai_data_preview_output.txt`:
    - Generated live preview text file verified against ObjectBox data.
  - `test/application/ai_data_formatter_test.dart`:
    - Added 7 comprehensive unit tests verifying 0 habits, boolean grid, numeric target check, descriptions & notes, windowDays filtering, date injection, and one-time tasks.
- Actual Output from Preview Tool:
```
=== User Habit Data (last 7 days) ===
Generated: Tue, 20 Oct 2026

--- Habit: "Morning Run" ---
Type: Habit (boolean) | Schedule: Daily | Streak: 3 days | Started: 20 Oct 2026
Description: Run at least 3 km each morning to build cardiovascular endurance.
  Wed 14 Oct ✅   Thu 15 Oct ✅   Fri 16 Oct ❌   Sat 17 Oct ✅   Sun 18 Oct ✅
  Mon 19 Oct ✅   Tue 20 Oct —
  Notes:
    [Wed 14 Oct] "Felt strong today, hit 4 km."
    [Fri 16 Oct] "Skipped due to rain."

--- Habit: "Water Intake" ---
Type: Habit (numeric) | Unit: glasses | Target: 8 | Schedule: Daily | Streak: 0 days | Started: 20 Oct 2026
  Wed 14 Oct 7   Thu 15 Oct 8 ✅   Fri 16 Oct 5   Sat 17 Oct 8 ✅   Sun 18 Oct 8 ✅
  Mon 19 Oct 6   Tue 20 Oct —

--- One-time Task: "Read 50 Pages" ---
Status: ✅ Completed on Wed 14 Oct 2026
Description: Finish chapter 3 of Atomic Habits.

--- One-time Task: "File Taxes" ---
Status: ⏳ Pending

===
```
- Tests/checks run:
  - `flutter test test/tools/ai_data_preview.dart` → `All tests passed! (1/1)`
  - `flutter test test/application/ai_data_formatter_test.dart` → `All tests passed! (7/7)`
  - `flutter analyze lib/` → `No issues found! (ran in 66.5s)`
  - `flutter test` → `All tests passed! (103/103 passed)`

## Previous completed tasks

- **PROD-01** — Data model expansion (HabitEntity, HabitDto, DayNoteEntity, AiSettingsEntity, QuoteEntity, AppDatabase accessors, build_runner, 86/86 tests).
- **PROD-02** — One-time task support (Toggle in Add screen, strikethrough, 50% opacity, badge, skip heatmap, 88/88 tests).
- **PROD-03** — Descriptions + Day Notes (DayNoteRepository, DayNoteBottomSheet, NotesPanel, 96/96 tests).

## Current task

**PROD-04-B** — AiSettings screen + context window control

- Status: Not started
- Goal: Surface the AI configuration in Settings, let the user set their API credentials, choose a persona (with character avatar), and control how many days/weeks of history to send.

## Next action

Execute **PROD-04-B**: Copy images to `assets/persona_dps/`, declare in `pubspec.yaml`, build `ai_personas.dart`, implement `AiSettingsScreen` with API fields, context window slider (1-90 days), and 2-column persona grid, wire into `SettingsScreen`.
