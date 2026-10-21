# Overman_V0 --- Design System

## Visual direction

**Quiet dark, vivid action.** Use a near-black canvas, charcoal
surfaces, electric blue for progress and completed states, and warm
orange for creation. The UI should feel focused, compact, confident, and
slightly distinctive---not like a generic admin dashboard.

The supplied Home screenshot is the source of truth for the first
prototype. Use the expanded-habit sketch to guide the internal
heatmap/statistics/graph panels. Do not redesign the whole product
unless asked.

## Design tokens

  --------------------------------------------------------------------------
  Token                      Value                   Usage
  -------------------------- ----------------------- -----------------------
  `color.background`         `#0F1115`               App canvas

  `color.surface`            `#1C1F26`               Habit cards, history
                                                     and settings buttons

  `color.accent.blue`        `#216CCF`               Completed controls,
                                                     streaks, card accent

  `color.accent.orange`      `#FF7A45`               Add button and primary
                                                     create action

  `color.text.primary`       `#E7E8EA`               Main headings and habit
                                                     names

  `color.text.muted`         `#A4AFBE`               Secondary text and
                                                     incomplete state

  `color.state.incomplete`   `#A4AFBE`               Dash control and
                                                     neutral accent

  `color.control.text`       `#0F1115`               Icons/text on blue or
                                                     orange fills
  --------------------------------------------------------------------------

Avoid adding extra accent colours without a concrete need. Derive subtle
borders and dividers from the existing palette.

## Typography

-   Main interface: Montserrat.
-   Date/history counter: Miriam Mono CLM if its font assets are
    available and licensing permits bundling.
-   Use a clear hierarchy: large habit title, smaller streak/status,
    compact supporting labels.
-   Verify font files, pubspec declarations, and runtime rendering
    before relying on custom fonts. Use a safe fallback if unavailable.

## Layout reference

Reference frame: 412 × 917 logical pixels.

-   History/date button: approximately 171 × 88.
-   Add and Settings buttons: approximately 92 × 88 each.
-   Habit card: approximately 375 × 109.
-   Completion/value control: approximately 87 × 81.
-   Use consistent page padding and spacing based on the screenshot.
-   These are reference dimensions, not a reason to overflow smaller
    devices. Use responsive layout constraints and test at the target
    emulator size.

## Home screen

-   Header row contains History/Date, Add, and Settings.
-   The date button shows the selected date and completion count,
    e.g. `23 Sep` and `0 / 2`.
-   Cards use `#1C1F26`, rounded corners, and a narrow left-edge status
    accent.
-   Completed habits use blue accent `#216CCF`; incomplete habits use
    muted grey `#A4AFBE`.
-   A checkmark control represents completion. A dash represents not yet
    logged. Numeric habits show the recorded value and unit.
-   Display streak information only when meaningful.
-   Preserve generous negative space and the screenshot's restrained
    visual density.

## Interaction states

### Normal

-   Add opens Add Habit/Task.
-   Settings opens Settings.
-   Date/history opens History.
-   Tapping a habit card expands it.
-   Tapping the completion/value control logs completion or opens the
    appropriate numeric-entry interaction.

### Expanded habit

-   Expands in place, beginning on the heatmap.
-   Supports horizontal swiping and visible circular previous/next
    controls.
-   Circular sequence:
    -   Checkmark habit: Heatmap → Statistics → Details → Heatmap.
    -   Numeric habit: Heatmap → Statistics → Graph → Details → Heatmap.
-   Reopening a collapsed card starts at Heatmap.
-   Do not show a numeric graph for a checkmark habit.
-   Details include the start date and description only when a
    description exists.

### Selection mode

-   Long-press for approximately 1--2 seconds to expose Edit/Delete
    actions in the top row.
-   Tapping outside exits selection mode.
-   Delete requires confirmation.
-   Edit prepopulates the form.

## Components to reuse

Create shared widgets/tokens only where they help maintain
consistency: - App surface/card - Header action button - Habit card -
Completion/numeric control - Streak label - Heatmap cell/grid -
Expanded-panel header and circular navigation controls - Form field and
selection controls - Empty state - Chart/statistic tile

Do not build a large design-system framework for a short prototype. Keep
components small and local to the existing architecture.

## Accessibility and usability

-   Maintain readable contrast for muted text.
-   Ensure tappable controls have practical hit areas.
-   Provide semantic labels for icon-only buttons.
-   Avoid relying on colour alone to distinguish completion.
-   Prevent text overflow for long habit names and numeric units.
-   Keep scrolling and swipe interactions predictable.

## Visual acceptance checklist

-   The Home screen resembles the supplied screenshot in structure,
    palette, and density.
-   Header controls align and fit the target device.
-   Habit cards and action controls share consistent radii and spacing.
-   Completed and incomplete states are visually distinct.
-   Expanded panels are legible and have working circular navigation.
-   No screen overflows at the target frame.
-   Existing interactions and data logic remain intact after visual
    changes.
