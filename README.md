# SIL

**Systematically Improving Lifestyle**

SIL is an iOS-first behaviour engine. You do the work; SIL closes the feedback
loop with structured goals, measurable progress, and visible growth over time.

SIL is the successor to the GAMELIFE / PRAXIS codebase. The engine is the same;
the surface is being rebuilt around a calm, typographic design language instead
of the previous game-styled interface.

## Status

| Area | State |
|---|---|
| Engine, data, services ported from GAMELIFE | Done |
| Project renamed to `SIL` (targets, bundle IDs, schemes) | Done |
| Design tokens, type scale, accents (SIL Prototype) | Done |
| Component library (`SILComponents`) | Done |
| Four-tab shell + Today screen | Done |
| Goals / Focus / You screens rebuilt | Done |
| Habits screen + Settings | Done |
| Onboarding + completion / level-up / recalibration overlays | Done |
| Compose sheet | Done |
| Widgets + watch app restyled | Done |
| Glasswork + SystemTheme shims retired | Done |
| Copy sweep: notifications, titles, system messages | Done |
| Localisation pass for the five translations | Outstanding |
| Icon + brand asset distribution | Done |

## Project layout

```
SIL.xcodeproj          Xcode project (targets: SIL, SILWidgets, SILWatch)
SIL/                   iOS app
  Design/              Design tokens and theme
  Models/              Domain models
  Services/            Engine, HealthKit, location, sync, notifications
  Views/               SwiftUI screens
SILWidgets/            Home Screen and Lock Screen widgets
SILWatch/              watchOS companion app
SILWatchExtension/     watchOS views
Tests/                 Regression checks and logic tests
sil-logo-pack/         Brand assets: mark, lockup, app icons, web, social
```

## Vocabulary

SIL 2.0 drops the RPG framing. The engine keeps its own names; the screens read
through [`SILVocabulary.swift`](SIL/Design/SILVocabulary.swift):

| Engine | Product |
|---|---|
| Quests | Habits |
| Bosses | Goals |
| Gold | Credits |
| XP | Progress |
| HP | Momentum |
| Shop | Rewards |
| Death penalty | Recalibration |

The six stats collapse into four attributes, told apart by glyph rather than
hue: **Body** (strength + agility), **Mind** (intelligence), **Energy**
(vitality), **Spirit** (spirit + willpower). That merge is a view concern —
`Player.stats` still stores all six, so no data migration is needed.

## Navigation

Four destinations behind a floating tab bar, with a compose button beside it:

- **Today** — momentum, level, the dot calendar, what's left, next up
- **Goals** — one number, a tick grid, a sparkline and an honest pace. A goal
  is a measurement, not an enemy with a health bar
- **Focus** — a 60-tick dial that empties as the session runs
- **You** — the four-attribute radar, 26 weeks of consistency, rewards,
  moments, milestones

Habits and Rewards are opened from Today and You rather than being tabs. Old
five-tab deep links and the saved "Open App To" preference still resolve.

## Recalibration

Running out of momentum resets the meter rather than wiping history. What else
it costs is yours to choose, in Settings → Momentum: drop one level, ease
attributes back, give up 20% of credits. Each is a separate switch and the
engine honours all three.

## Bundle identifiers

- App: `marcshaw.SIL`
- Widgets: `marcshaw.SIL.SILWidgets`
- Watch app: `marcshaw.SIL.watchkitapp`

## Brand

- Mark: "Three strokes" — S, I and L as rising bars, the last turning into an L.
  Drawn in-app as a vector by [`SILMark`](SIL/Design/SILMark.swift)
- Ground: `#0A0A0C` dark / `#EDEDEB` light; ink `#F4F4F5` / `#0E0E10`
- One accent, user-selectable: violet (default), orange, or mono
- Type: Schibsted Grotesk (text) + Martian Mono (labels), bundled under
  [`SIL/Resources/Fonts`](SIL/Resources/Fonts) with their OFL licences. Both
  ship as static instances cut from the variable originals at the weights SIL
  uses — SwiftUI's `.weight()` does not drive a variable axis, so one variable
  file would have meant synthetic bolding. `S.display/text/mono` resolve the
  face per weight and fall back to the system face if registration fails. The
  old bundled "Good Times" display face and its SIL FONT switch are gone
- App icons: Ink (primary), Paper, Violet, Ember — same mark, different ground

Tokens live in [`SIL/Design/SILTheme.swift`](SIL/Design/SILTheme.swift) under the
`S` namespace. Every screen reads `S` directly — the `GW` and `SystemTheme`
shims are gone. Three Glasswork primitives survive in `GlassworkComponents`,
redrawn on SIL surfaces, until the habit editor is rebuilt.

## Known gaps

- The five translations (de, es, fr, it, ru) still carry game-era wording.
  The string keys were renamed to SIL's vocabulary and the existing
  translations carried across, so nothing is missing at runtime, but the
  non-English copy says "Quest" and "Dungeon" and needs a human pass.
- Leaving the app during a focus session still abandons it with a penalty,
  which sits awkwardly against the running screen's "ending early keeps
  partial credit". Kept from the GAMELIFE engine pending a decision.
- The watch app is restyled and builds, but has not been seen running: no
  watchOS simulator runtime is installed on this machine, and fetching one is
  a multi-gigabyte download.

Full asset inventory and usage rules: [`sil-logo-pack/README.md`](sil-logo-pack/README.md)

## Build

```bash
xcodebuild -project SIL.xcodeproj -scheme SIL \
  -destination 'generic/platform=iOS Simulator' build
```

Regression checks:

```bash
bash Tests/run_regression_checks.sh
```

## Version

6.13 (build 6.13)
