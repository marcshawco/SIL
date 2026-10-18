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
| Design language rebuild (SIL Prototype) | In progress |
| Icon + brand asset distribution | In progress |

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

## Bundle identifiers

- App: `marcshaw.SIL`
- Widgets: `marcshaw.SIL.SILWidgets`
- Watch app: `marcshaw.SIL.watchkitapp`

## Brand

- Mark: "Three strokes" — S, I and L as rising bars, the last turning into an L
- Colours: black `#0A0A0C`, white `#FFFFFF`
- Type: Schibsted Grotesk 600 + Martian Mono 400

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

6.0 (build 6.0)
