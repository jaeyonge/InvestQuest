# InvestQuest Repository Map

## Project Overview

InvestQuest is a single-target iOS learning game built with SwiftUI and SwiftData. The app teaches investing concepts through staged simulations, persists player progress locally, and uses deterministic market simulations to drive gameplay.

Fact:
- Source layout contains 34 Swift source files and 17 test files.
- Product code is organized under `Sources/InvestQuest`.
- Tests are split into `Tests/InvestQuestTests` and `Tests/InvestQuestUITests`.
- `project.yml` is present and a generated `InvestQuest.xcodeproj` is also checked in.

Inference:
- This repository is closer to a well-tested prototype or vertical slice than a scaled production app. The surface area is compact, but core responsibilities are concentrated in a small number of types.

## Targets And Modules

From `project.yml`:

- `InvestQuest`
  - Type: iOS application
  - Deployment target: iOS 17.0
- `InvestQuestTests`
  - Type: unit test bundle
- `InvestQuestUITests`
  - Type: UI test bundle

There are no framework targets, no local Swift packages, and no third-party package managers in use.

## Module List

Logical modules inside the single app target:

- `App`
  - App entry, root container setup, launch/runtime helpers
- `Engine`
  - Deterministic market simulation engine and simulation protocols
- `Models`
  - Stage definitions, decision models, SwiftData entities, phase metadata
- `Phases`
  - Static stage content for phases 1 through 7
- `Progression`
  - Progress persistence and navigation/unlock logic
- `Services`
  - Haptic feedback wrapper
- `ViewModels`
  - App routing, stage state machine, phase summary state
- `Views`
  - SwiftUI gameplay, onboarding, phase map, and summary screens

## Key Directories

- `Sources/InvestQuest/App`
  - `InvestQuestApp.swift`: SwiftUI `@main` entry point
  - `ContentView.swift`: root routing container
  - `AppRuntimeSupport.swift`: SwiftData container setup, UI-test seeding, launch flags
- `Sources/InvestQuest/ViewModels`
  - `AppViewModel.swift`: top-level route state
  - `StageViewModel.swift`: per-stage flow state machine and scoring logic
  - `PhaseCompletionViewModel.swift`: phase summary and persistence
- `Sources/InvestQuest/Progression`
  - `GameProgressService.swift`: persistence, progression, sessions, recap logic
  - `StageCatalog.swift`: global stage lookup
- `Sources/InvestQuest/Models`
  - `StageDefinition.swift`: decision models, scenarios, scoring rules, legacy adapters
  - `GameProgress.swift`: SwiftData entities
  - `PhaseConfig.swift`: static phase metadata
- `Sources/InvestQuest/Phases`
  - `Phase1...Phase7StageDefinitions.swift`: stage content authored as static Swift
- `Sources/InvestQuest/Views/Gameplay`
  - Core screens: briefing, decision, simulation, result, insight, recap, stage container

Approximate code concentration by directory:

- `Models`: 1,099 LOC
- `Views/Gameplay`: 1,021 LOC
- `ViewModels`: 535 LOC
- `Progression`: 360 LOC
- `Engine`: 345 LOC
- `App`: 324 LOC
- `Phases`: 1,487 LOC across seven phase folders

## Entry Points

Primary entry points:

- SwiftUI app entry: `Sources/InvestQuest/App/InvestQuestApp.swift`
- Root content/routing view: `Sources/InvestQuest/App/ContentView.swift`
- Top-level route coordinator: `Sources/InvestQuest/ViewModels/AppViewModel.swift`
- Per-stage flow container: `Sources/InvestQuest/Views/Gameplay/StageContainerView.swift`

Not present:

- No `AppDelegate`
- No `SceneDelegate`
- No UIKit coordinator tree

## Dependency List

First-party / Apple frameworks observed:

- `SwiftUI`
- `SwiftData`
- `Foundation`
- `UIKit` for haptics and animation disabling in UI tests
- `XCTest`

Third-party dependencies observed:

- None via Swift Package Manager
- None via CocoaPods
- None via Carthage
- No analytics SDKs
- No crash reporting SDKs
- No networking SDKs

Repo-wide scans found no `Package.swift`, `Podfile`, `Cartfile`, `.github` CI config, `fastlane`, `.xcconfig`, `.strings`, or `.xcassets` files.

## Architecture Hints

Observed patterns:

- SwiftUI app with MVVM-like state holders
- One app-wide routing view model (`AppViewModel`) acting as a lightweight coordinator
- One stage-level state machine (`StageViewModel`)
- A service layer (`GameProgressService`) directly wrapping SwiftData
- Static content catalog pattern (`StageCatalog`, `PhaseConfig`, `PhaseNStageDefinitions`)

Patterns not observed:

- No TCA or reducer/store framework
- No Clean Architecture module boundaries
- No VIPER
- No repository abstraction boundary separate from UI
- No feature modules or Swift packages

## Observed Conventions

- File naming is consistent and feature-oriented: `Stage...`, `Phase...`, `...ViewModel`, `...Service`.
- Product tests are written around acceptance-criteria style names such as `testStage1_...`, `testStage4_...`, `testBootstrap_...`.
- Phase content is encoded as static Swift definitions rather than JSON or CMS content.
- Most core runtime objects are `@MainActor`.
- Persistence is local-only and centered on SwiftData `@Model` types.
- The codebase contains an unfinished migration from legacy types (`DecisionType`, `StageConfig`) to richer runtime types (`DecisionSpec`, `StageSimulation`).

## Initial Audit Notes

High-signal repository facts:

- The app is intentionally offline-first.
- The test suite is unusually large relative to repo size.
- The codebase is easy to scan but not strongly modularized.
- Core responsibilities are concentrated in `StageDefinition.swift`, `StageViewModel.swift`, and `GameProgressService.swift`.
