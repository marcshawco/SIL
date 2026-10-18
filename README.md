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
| Goals / Focus / You screens rebuilt | In progress |
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
- **Goals** — the long ones, weeks not minutes
- **Focus** — the timer
- **You** — attributes, consistency, rewards, moments, milestones

Habits and Rewards are opened from Today and You rather than being tabs. Old
five-tab deep links and the saved "Open App To" preference still resolve.

## Bundle identifiers

- App: `marcshaw.SIL`
- Widgets: `marcshaw.SIL.SILWidgets`
- Watch app: `marcshaw.SIL.watchkitapp`

## Brand

- Mark: "Three strokes" — S, I and L as rising bars, the last turning into an L.
  Drawn in-app as a vector by [`SILMark`](SIL/Design/SILMark.swift)
- Ground: `#0A0A0C` dark / `#EDEDEB` light; ink `#F4F4F5` / `#0E0E10`
- One accent, user-selectable: violet (default), orange, or mono
- Type: Schibsted Grotesk 600 + Martian Mono 400. Those files are not bundled,
  so the app falls back to SF Pro and SF Mono; `S.display/text/mono` pick the
  real faces up automatically if they are ever added
- App icons: Ink (primary), Paper, Violet, Ember — same mark, different ground

Tokens live in [`SIL/Design/SILTheme.swift`](SIL/Design/SILTheme.swift) under the
`S` namespace. `GW` and `SystemTheme` are compatibility shims that forward their
old names to `S`; they shrink as screens are rebuilt.

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

6.2 (build 6.2)
