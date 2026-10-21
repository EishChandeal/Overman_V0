# Overman_V0 --- Project Brief

## Purpose

Overman_V0 is a Flutter-based habit-tracking and personal productivity
application. Its immediate goal is to demonstrate a coherent, working
multi-screen prototype for a college mentor presentation. The
longer-term direction is to combine low-friction habit tracking with
behavioural analytics and carefully grounded AI-assisted insights.

## Immediate prototype goal

Deliver a reliable Android-sized prototype with multiple navigable
screens and meaningful interactions. Prioritize working flows over
feature count.

### Must-have demonstration flow

1.  Home displays habits and their current status.
2.  User opens the Add screen and creates a habit or one-off task.
3.  The new item appears on Home.
4.  User marks a checkmark habit complete or logs a numeric value.
5.  User expands a habit and inspects its heatmap/statistics/details.
6.  Insights displays metrics calculated from the available tracking
    data.
7.  User can open History and inspect earlier dates.

Settings and real export functionality are desirable if time allows.
Notification delivery, a remote AI backend, cloud sync, and advanced
predictive models are explicitly out of scope for the first prototype
unless already implemented and trivial to reuse.

## Product principles

-   Low-friction: common actions should take very few taps.
-   Data integrity: historical entries should remain associated with the
    date they were recorded.
-   Progressive disclosure: show the simple habit card first; reveal
    detail on expansion.
-   Consistent design: use a small token-based design system and
    reusable components.
-   Privacy-conscious: do not send personal habit data to external
    services without an explicit design decision.
-   Honest functionality: do not present placeholder controls as working
    features.
-   Preserve working code: prefer targeted changes over rewrites.

## Home screen design reference

Target reference frame: Android compact frame, 412 × 917 logical pixels.
Treat measurements as starting points, not fixed dimensions for all
devices.

-   Background: `#0F1115`
-   Surface: `#1C1F26`
-   Blue accent: `#216CCF`
-   Orange accent: `#FF7A45`
-   Muted grey: `#A4AFBE`
-   Primary text: `#E7E8EA`
-   Main font: Montserrat
-   Date/history counter font: Miriam Mono CLM, if available and
    suitable for bundling
-   History button: approximately 171 × 88
-   Add/settings buttons: approximately 92 × 88
-   Habit card: approximately 375 × 109
-   Completion/value control: approximately 87 × 81

The supplied Home screenshot is the primary visual reference. The
supplied expanded-habit sketch is a reference for the heatmap,
statistics, and numeric graph panels.

## Main screens

1.  **Home:** date/progress header, Add and Settings controls, habit
    cards, streak/status indicators.
2.  **Add/Edit:** name, habit/task type, checkmark/numeric tracking,
    numeric unit/target, schedule, optional description, notification
    preference.
3.  **Expanded habit:** circular panel sequence starting with heatmap;
    statistics; numeric graph only for numeric habits; optional
    description and start date.
4.  **History:** scrollable dates in reverse chronological order, with
    the habits and recorded values for each date.
5.  **Insights:** charts and statistics calculated from available
    tracking data.
6.  **Settings:** sensible prototype settings and export options if
    feasible.

## Domain behaviour

-   A habit may be checkmark-based or numeric.
-   Habits may use daily, weekly, or every-N-days schedules, depending
    on what the existing architecture supports safely.
-   A task is a one-off item and must not be treated as a repeating
    habit.
-   Numeric records should preserve the value and unit relevant to that
    entry.
-   The daily completion counter should count applicable scheduled
    habits consistently; one-off tasks should not inflate future daily
    totals.
-   Expanding a habit opens the heatmap first. Closing and reopening it
    resets to the heatmap.
-   The available detail panels cycle circularly. Omit the graph for
    checkmark habits.
-   Long-pressing a card for roughly 1--2 seconds enters selection mode,
    exposing Edit/Delete. Tapping outside exits selection mode.
-   Notification toggles may be stored as preferences only for this
    prototype; notification delivery is not required.
-   Do not invent statistics when there is insufficient data. Label
    sample/demo data if used.

## Technical constraints

Inspect the repository before deciding architecture or dependencies.
Reuse the existing Flutter/Dart structure, state management,
persistence, routing, models, and tests where viable. Do not assume a
dependency exists just because it appears in a previous plan. Do not
replace ObjectBox, Riverpod, or other project choices without evidence
and a clear reason.

## Definition of prototype success

-   App launches reliably on the target emulator/device.
-   At least four screens are reachable through meaningful navigation.
-   Core habit/task creation and completion interactions work.
-   Expanded habit panels respond to taps/swipes and show the
    appropriate content.
-   Insights are based on real or clearly labelled seeded data.
-   No known blocking crash remains in the main demonstration flow.
-   A final walkthrough can be completed in 2--3 minutes.
