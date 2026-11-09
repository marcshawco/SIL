# Agent log

A running record of agent work on SIL. `CLAUDE.md` asks for this file to be
read at the start of every session; it did not exist until 2025-11-09, so the
entries before that date are reconstructed from the git history rather than
written at the time.

Newest first. One entry per session, not per commit.

---

## 2025-11-09 — Review fixes, habit editor, legacy removal

**Versions:** 6.14 → 6.16

Ran a code review of the SIL rewrite, fixed what it found, then finished the
two pieces of de-gamification that were still outstanding.

**Review findings, all fixed (6.15)**

1. Focus's "End early" called `complete()`, which paid the whole session's
   reward from the *configured* duration — a minute into a 90-minute sit paid
   out in full, under copy promising partial credit. Settlement now runs
   through `TrainingManager.finish(share:)`.
2. Reward purchases dropped `PurchaseResult.message`, so a momentum top-up
   refused at full momentum did nothing visible. Both outcomes now surface.
3. `SILGoalsView.trim()` guarded `isFinite` but not magnitude, and `Int(1e20)`
   traps — Goals crashed on open after a large target was typed. Added
   `SILFormat.clampedInt`, and the compose sheet now bounds the target.
4. `SILFormat` built its formatters on `Locale.current`, bypassing the locale
   the app root publishes. They now read `AppLanguage.currentLocale`, use a
   date template rather than a fixed pattern, and cache per locale.

**Focus product decision**, open since the rewrite and decided here: leaving
the app mid-session now *holds* the session (the clock stops, nothing is
taken) instead of abandoning it with a penalty. `abandon()` and the penalty
path are gone. A focus session has no failure state any more.

**Habit editor rebuilt (6.16).** `QuestFormSheet` — 2,260 lines, two parallel
forms behind a page control, a readiness card scoring the user's progress
through the form, Glasswork chrome — is replaced by `SILHabitEditor` (~700
lines) plus `SILHabitEditorSupport`. Every field round-trips as before; the
six stats are picked as the four SIL attributes; the Apple Health wheel is a
plain list; address resolution moved to `SILAddressResolver`.

**Legacy removal (6.16).** With the editor gone, nothing used the shims:
deleted `SIL/Views/Glasswork/` and `SIL/Design/LegacyTypeAndLayout.swift`, and
moved the last five call sites onto `S`. Added `S.uiSans` for the UIKit
appearance proxies.

Rebuilt the last two pre-SIL screens while converting them: **Permissions**
(was "Neural Links", with a brain icon and three sections of connection
telemetry) and **Questions** (the FAQ, whose answers still described hunters,
ranks, death penalties and the Shop — and which rendered clipped off both
edges in its old sheet). Settings' disclosure rows are now tappable across
their full width rather than only on the chevron.

**Verified** on an iPhone 17 Pro simulator: edit → save round-trips a habit,
Permissions and Questions render correctly. Regression checks repointed to the
new files and extended to cover all four fixes.

**Still open:** 26 strings await translation in five languages
(`TRANSLATION-TODO.md`), and the watch app's populated state has not been
seen — WatchConnectivity does not come up between paired simulators.

---

## 2025-10 / 2025-11 — The SIL rewrite (reconstructed)

Took the GAMELIFE / PRAXIS codebase and made it stop looking like a game,
implementing the design language from the SIL Prototype handoff.

Roughly in order: ported the engine and renamed the project; built the `S`
token namespace and `SILComponents`; replaced the tab shell and rebuilt Today,
Goals, Focus, You, Habits and Settings; wrote the compose sheet, onboarding
and the completion / level-up / recalibration overlays; restyled the widgets
and the watch app; bundled Schibsted Grotesk and Martian Mono as static cuts;
distributed the `sil-logo-pack` icons; and swept the copy.

The method worth remembering: rather than rewrite 33k lines at once, `GW` and
`SystemTheme` were redefined as shims forwarding to `S`, so every screen
de-gamified in one step. The shims then shrank as screens were rebuilt, and
were deleted on 2025-11-09 when the last caller went.

About 11,000 lines were deleted — both old onboarding flows, the Glasswork
gallery and mockups, `QuestsView`, `BossesView`, `SettingsView`, the
pre-Glasswork screens, and the unreachable UI living inside service files.

Running it on a simulator in both light and dark caught five bugs that reading
the code did not: the tab bar's selected pill swallowing the width, onboarding
clipping, Skip writing habits anyway, the default player being "Hunter", and
dark mode being entirely dead because Settings wrote a key the app root never
read.
