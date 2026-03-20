# InvestQuest Architecture Analysis

## Current Architecture Description

InvestQuest uses a compact, single-module SwiftUI architecture with three effective runtime layers:

1. Presentation
   - SwiftUI views under `Views`
   - `AppViewModel`, `StageViewModel`, and `PhaseCompletionViewModel`
2. Gameplay / business logic
   - `StageDefinition`, `StageCatalog`, `PhaseConfig`
   - `MarketSimulationEngine`
   - progression and scoring rules in `StageViewModel` and `GameProgressService`
3. Persistence
   - SwiftData `@Model` entities in `GameProgress.swift`
   - direct use of `ModelContext` and `@Query`

Fact:
- The app is not layered into separate modules or packages.
- Views instantiate `GameProgressService` directly from `@Query` results in `ContentView.swift:12-18`, `StageContainerView.swift:19-20`, `PhaseMapView.swift:10-20`, `StageRecapView.swift:12-13`, and `PhaseSummaryView.swift:39-48`.
- `StageViewModel` owns both UI flow state and core gameplay logic such as scoring, portfolio weighting, replay statistics, and behavioral bias inference in `StageViewModel.swift:124-165`, `StageViewModel.swift:236-363`.

Inference:
- The architecture was optimized for shipping end-to-end gameplay quickly, not for long-term separability or feature scaling.

## Textual Architecture Diagram

```text
InvestQuestApp
  -> ContentView
    -> AppViewModel (route state)
      -> IntroAnimationView
      -> PhaseMapView
      -> StageRecapView
      -> StageContainerView
        -> StageViewModel (stage flow state machine)
          -> MarketSimulationEngine
          -> StageDefinition / StageCatalog / PhaseNStageDefinitions
        -> GameProgressService
          -> SwiftData ModelContext
            -> GameProgress
            -> StageCompletionRecord
            -> StageSessionRecord
            -> DecisionRecord
            -> PhaseCompletionRecord
      -> PhaseSummaryView
        -> PhaseCompletionViewModel
          -> SwiftData ModelContext
```

## Presentation Layer Pattern

Actual pattern:

- MVVM-ish, but not pure MVVM
- `AppViewModel` handles routing
- `StageViewModel` is a state machine, simulation orchestrator, scoring engine, and hint provider
- Views remain declarative overall, but some contain domain logic

Evidence:

- `AppViewModel` owns route transitions in `AppViewModel.swift:6-78`.
- `StageViewModel` owns stage transitions and simulation execution in `StageViewModel.swift:42-217`.
- `BehavioralProfileReviewPanel` computes cross-session bias summaries directly inside a view in `DecisionView.swift:337-401`.

## State Management Strategy

State ownership is split across:

- `AppViewModel.currentRoute` for app-wide navigation
- `StageViewModel` for per-stage gameplay state
- `@Query` for persisted progress and historical decisions
- `@State` in views for transient form state such as sliders and ranking order

Strength:

- The state surface is understandable and local for a repo of this size.

Weakness:

- There is no explicit source-of-truth boundary between route state, SwiftData state, and stage runtime state.
- Reconstructing `GameProgressService` in views means state access depends on view rendering rather than dependency injection.

## Business Logic Boundaries

Current boundaries are blurred.

Business rules live in multiple places:

- Progression rules: `GameProgressService.swift:36-76`, `GameProgressService.swift:128-161`, `GameProgressService.swift:211-232`
- Scoring rules: `StageDefinition.swift:468-491` and `StageViewModel.swift:295-326`
- Bias tagging: `StageViewModel.swift:350-363`
- Behavioral summary generation: `DecisionView.swift:371-399`
- Phase content and game rules: `PhaseNStageDefinitions.swift`

There is no dedicated domain layer or use-case layer.

## Data Flow Across Layers

Primary flow:

1. Static stage content is defined in `PhaseNStageDefinitions.swift`.
2. `StageCatalog` and `StageDefinition` expose the selected stage definition.
3. `StageContainerView` creates `StageViewModel` from the selected definition.
4. `StageViewModel` runs `MarketSimulationEngine`, computes outcome and snapshot state.
5. `StageContainerView` persists snapshot and final results through `GameProgressService`.
6. `AppViewModel` updates route based on stage outcome.

This is straightforward, but most boundaries are runtime conventions rather than type-enforced layers.

## Dependency Directions

Healthy directions:

- Views depend on view models and models.
- Engine depends only on Foundation.
- Models are mostly dependency-light.

Problematic directions:

- Views depend directly on persistence (`@Query`, `ModelContext`, `GameProgressService`).
- The view model depends on content, scoring, simulation, and behavioral heuristics.
- Legacy and current model abstractions depend on each other through adapters in `StageDefinition.swift:540-735`.

## Cross-Module Coupling

Since the app is one module, the relevant question is cross-directory coupling.

Observed coupling:

- `Views` <-> `Progression` is tight because views directly construct `GameProgressService`.
- `ViewModels` <-> `Models` is tight because `StageViewModel` understands simulation asset kinds, scoring rules, and phase/stage IDs.
- `Phases` <-> `Models` is tight because every phase definition still uses the legacy `StageDefinition(phase:stage:decisionType:simulationConfig:...)` initializer.

## Violations Of Separation Of Concerns

Key violations:

- Persistence leaks into UI:
  - `ContentView.swift:5-27`
  - `PhaseMapView.swift:4-22`
  - `StageContainerView.swift:7-20`
  - `PhaseSummaryView.swift:6-58`
- Business summarization logic lives in a SwiftUI view:
  - `DecisionView.swift:337-401`
- `StageViewModel` owns simulation, scoring, session serialization, hint policy, and bias tagging:
  - `StageViewModel.swift:124-165`
  - `StageViewModel.swift:183-203`
  - `StageViewModel.swift:295-363`

## Strengths

- The runtime flow is easy to reason about end to end.
- `AppViewModel` provides a simple and effective top-level coordinator.
- `MarketSimulationEngineProtocol` gives at least one real seam for testability.
- Static phase content makes the app deterministic and testable offline.

## Weaknesses

- Architectural boundaries are informal, not enforced.
- Presentation, domain, and persistence are collapsed into the same types.
- Legacy/current model duplication increases cognitive load.
- Several behaviors are keyed off phase/stage numbers or string descriptions rather than explicit domain types.

## Architectural Drift And Inconsistency

This codebase shows clear migration drift.

Fact:

- Newer runtime types exist:
  - `DecisionSpec`
  - `StageSimulation`
- Legacy types still drive authored content:
  - `DecisionType`
  - `StageConfig`
- `StageDefinition` converts legacy content into runtime models in `StageDefinition.swift:540-579`.
- Reverse adapters also still exist in `StageDefinition.swift:737-760`.

Inference:

- The team started a richer modeling migration but stopped midway. The result is duplicated concepts, adapter code in the core model layer, and tests that continue to validate the legacy surface.

## Architecture Assessment

Overall assessment: coherent but tightly coupled.

- Good enough for a compact offline educational app
- Not ready for easy feature scaling, content expansion, or schema evolution
- Highest-risk architecture issue is not the single target itself; it is the absence of clear seams between UI, domain rules, and persistence
