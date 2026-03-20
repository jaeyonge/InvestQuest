# Code Quality Review

## Overall Assessment

The codebase is readable and consistent at a local level, but a few core files carry too many responsibilities. Quality is strongest in naming, determinism, and testability of the happy path. Quality is weakest in separation of concerns, legacy abstraction cleanup, and operational error handling.

## Strengths

- Naming is consistent and clear.
- File organization is intuitive.
- Most public-facing types have obvious responsibilities from their names.
- The deterministic simulation engine is concise and well-contained in `Engine/`.
- Test helper patterns are pragmatic and easy to follow.

## High-Impact Issues

### 1. God Types In Core Flow

Examples:

- `Sources/InvestQuest/Models/StageDefinition.swift` at 845 LOC
- `Sources/InvestQuest/Views/Gameplay/DecisionView.swift` at 469 LOC
- `Sources/InvestQuest/ViewModels/StageViewModel.swift` at 384 LOC
- `Sources/InvestQuest/Progression/GameProgressService.swift` at 311 LOC

Why it matters:

- Changes in one concern are likely to affect unrelated behavior.
- Review and debugging cost increases quickly.
- It is difficult to establish ownership boundaries within the team.

### 2. Silent Failure Patterns

Core gameplay persistence uses `try?` heavily.

Why it matters:

- The app can lose progress, stage completion, or session state without any user-visible failure.
- Operational issues will be hard to diagnose from crash-free telemetry because the failures are intentionally ignored.

### 3. Stringly-Typed Persistence And Behavior

Examples:

- `DecisionRecord.decisionType` is a raw string
- decision/outcome payloads are JSON strings
- `outcomeWeight.description` drives simulation behavior in `StageDefinition.swift:675-680`

Why it matters:

- Refactors are unsafe
- Schema evolution becomes expensive
- Querying and reporting are weak

## Naming And API Design

Mostly good:

- `StageAddress`, `StageOutcome`, `GameProgressService`, `PhaseCompletionViewModel` are clear.

Weaker spots:

- `GameProgressService` is more than a service; it is the effective repository, progression policy engine, session manager, and recap provider.
- `StageDefinition` is not only a definition object; it also hosts legacy adapters and scoring inference logic.

## Protocol Usage

Observed:

- `MarketSimulationEngineProtocol` is the only strong seam.

Assessment:

- Good use of a protocol around the simulation engine.
- There is no comparable abstraction for persistence, progression, or content loading.

## Generics And Extensions

Observed:

- Generic usage is minimal and appropriate.
- Extensions are used sparingly.

Assessment:

- This is not an abstraction-heavy codebase.
- The problem is under-separation, not over-engineering.

## Optional And Error Handling

Positive:

- Guard usage is consistent and straightforward.

Negative:

- `fatalError` is still present in production-facing paths:
  - `AppRuntimeSupport.swift:48`
  - `StageCatalog.swift:18`
  - `PhaseCompletionViewModel.swift:20`
- `try?` masks failures instead of modeling them.

## Duplication

### Structural Duplication

- Legacy and current stage models both exist:
  - `DecisionType` vs `DecisionSpec`
  - `StageConfig` vs `StageSimulation`
- Conversion code exists in both directions.

### Behavioral Duplication

- Passing-score logic is checked in both `AppViewModel` and `GameProgressService`.
- Bias logic is split between `StageViewModel` and `DecisionView`.

## Dead Code / Incomplete Migration Signals

The following capabilities exist in runtime types but are not used by authored stage content:

- `DecisionSpec.valuation`
- `DecisionSpec.stopLoss`
- `DecisionSpec.review`
- `PlayerDecision.valuation`
- `PlayerDecision.stopLoss`
- `PlayerDecision.review`

Repo-wide search shows stage definitions still author everything through legacy `DecisionType` and `StageConfig`, including stages that conceptually deserve richer models such as stop-loss and review flows.

Inference:

- The migration to richer decision models was started but not adopted by content authors, leaving dead or nearly-dead branches in core runtime code.

## Fragile Logic

Examples:

- `StageViewModel.inferredBiasTags()` keys off hard-coded phase/stage tuples.
- `StageScoringRule.infer()` special-cases Phase 2 Stage 1.
- `StageSimulation.fromLegacy()` derives preferred assets from string descriptions.

These are maintainable only while content remains small and static.

## Recommended Improvements

- Break up `StageViewModel` into stage-state, scoring, and analytics/bias helpers.
- Break up `DecisionView` into per-decision subviews and move behavioral summarization out of the view.
- Remove `try?` from core persistence code.
- Complete the legacy-model migration or explicitly delete the unused richer paths.
- Replace string-driven rules with explicit enums/typed configuration.
