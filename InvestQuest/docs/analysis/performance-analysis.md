# Performance And Reliability Review

## Evidence Summary

From the existing automated test suite and direct test execution:

- `MarketSimulationEngineTests` and `NonFunctionalRequirementsTests` assert sub-second simulation times.
- Full unit suite completed in about 4.7 seconds.
- Full UI suite completed in about 120 seconds.
- No performance warnings or runtime crashes appeared during the audited `xcodebuild test` run.

## Strengths

- The core simulation engine is fast and deterministic.
- There is no networking or remote content fetch during runtime.
- The data set is small and local.
- Startup work is relatively light: model container creation, simple route bootstrap, and a single progress fetch/create path.

## Main Performance Risks

### 1. Timer-Driven Persistence Writes

Fact:

- `StageViewModel.startDecisionTimer()` updates `timeRemaining` every 0.1 seconds and calls `refreshSessionSnapshot()` on each tick in `StageViewModel.swift:191-199`.
- `StageContainerView` persists every snapshot change through `service.saveSession(snapshot)` in `StageContainerView.swift:85-88`.
- `GameProgressService.saveSession()` writes through SwiftData and calls `try? modelContext.save()` in `GameProgressService.swift:164-188`.

Impact:

- Frequent main-thread writes during countdown timers
- unnecessary disk IO
- elevated battery and responsiveness risk

Assessment:

- This is the most meaningful performance issue in the codebase today.

### 2. Main-Actor Simulation Execution

Fact:

- `StageViewModel` is `@MainActor`.
- `runSimulation()` calls `engine.simulate(stage:)` synchronously in `StageViewModel.swift:206-217`.

Impact:

- Current stage definitions are small enough that this is acceptable.
- If replay counts, stage count, or asset complexity increases, simulation work will directly compete with UI responsiveness.

### 3. Resume Replays Simulation Instead Of Restoring It

Fact:

- Resume from `.simulation`, `.result`, or `.insight` reruns simulation in `StageViewModel.swift:55-71`.

Impact:

- Current engine determinism keeps behavior stable now.
- Future engine or content changes could make resumed sessions diverge across app versions.

### 4. Repeated Recomposition Of Stage Catalog Data

Fact:

- `StageCatalog.all` rebuilds the concatenated definition array on access.
- Several progression methods repeatedly scan `StageCatalog.all` or `StageCatalog.definitions(forPhase:)`.

Impact:

- Low at current scale
- Worth noting if content grows far beyond 30 stages

## App Launch Assessment

Fact:

- There is no dedicated launch measurement or instrumentation in the repo.
- `ContentView` bootstraps progress in `.task` and uses `@Query` for progress records.
- The UI test timing includes automation setup, so it is not a trustworthy app-launch metric.

Inference:

- Launch is likely acceptable for the current local-only workload.
- The repo lacks instrumentation to prove or regress-launch behavior over time.

## Memory And Allocation Review

Observed positives:

- No image pipeline or large caches are present.
- Simulations operate on small arrays and short-lived value types.
- There are no obvious long-lived retain cycles in the main flow.

Observed risks:

- Recomputing replay results and portfolio arrays on resume is extra work.
- `DecisionView` and `StageDefinition` carry many static strings and large inline content blocks in memory, though this is acceptable at current scale.

## Reliability Review

Strong points:

- Deterministic simulation makes bugs reproducible.
- Session restore exists and is validated by UI tests.

Weak points:

- Persistence failures are swallowed.
- `fatalError` still exists on some invalid states.
- Session fidelity depends on reconstructing state, not restoring an exact persisted runtime artifact.

## Recommended Improvements

- Throttle or batch session persistence during timers.
- Move simulation execution off the main actor if content expands.
- Add launch and save-frequency instrumentation.
- Cache or memoize static catalog arrays if phase count increases materially.
- Persist enough simulation output to make resume independent of future engine behavior if long-lived sessions matter.

## Performance Assessment

Current state:

- Good for present scope
- Not yet hardened for larger simulations, more content, or long-session persistence load

The codebase performs well because the workload is intentionally small. The main risk is not raw compute speed; it is unnecessary persistence churn on the main actor.
