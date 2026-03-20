# Layer-By-Layer Analysis

## UI Layer

### Strengths

- SwiftUI is used consistently across the app.
- Navigation is simple and comprehensible.
- Core gameplay screens are clearly separated by state:
  - briefing
  - decision
  - simulation
  - result
  - insight
- Accessibility identifiers are present on major interaction points, which helps UI tests.

### Issues

- Views directly access persistence through `@Query` and `ModelContext` instead of depending on injected abstractions.
- `DecisionView.swift` is 469 LOC and combines multiple unrelated decision UIs, scenario rendering, and behavioral review logic.
- `BehavioralProfileReviewPanel` performs domain aggregation and classification in the view layer at `DecisionView.swift:337-468`.
- `ContentView` performs persistence writes directly in the intro completion closure at `ContentView.swift:36-39`.

### Risks

- UI changes can accidentally break persistence behavior.
- View tests will be harder to isolate because the UI is not separated from data access.
- Reuse of gameplay components outside the current routing structure will be expensive.

### Recommended Improvements

- Introduce a root app store or dependency container and stop constructing services inside views.
- Extract behavioral summary logic into a domain service or view model.
- Split `DecisionView` by decision type.

## State Management

### Strengths

- `AppViewModel` gives the app one explicit routing state.
- `StageViewModel` encapsulates stage progression clearly enough for tests.
- `@Published private(set)` is used well to restrict write access from views.

### Issues

- State is duplicated across three places:
  - `AppViewModel.currentRoute`
  - `GameProgress` persisted state
  - `StageViewModel` runtime state
- Session snapshots are regenerated on every significant state change and persisted from the view in `StageContainerView.swift:85-88`.
- During timed decisions, snapshot state changes every 100ms because `StageViewModel.startDecisionTimer()` updates `timeRemaining` and refreshes the snapshot on each tick in `StageViewModel.swift:191-199`.

### Risks

- Excessive persistence churn
- Divergence between route state and persisted state
- Hard-to-reason-about bugs if future features add more global state

### Recommended Improvements

- Make session persistence explicit and throttled.
- Define a single authoritative source for route/progress decisions.
- Consider a stage reducer/store style object if gameplay states grow further.

## Domain / Business Logic

### Strengths

- Stage content is deterministic and easy to audit.
- Simulation behavior is reproducible from seeded inputs.
- Core gameplay concepts are encoded directly in phase definitions, which makes intent visible.

### Issues

- Business rules are spread across `StageDefinition`, `StageViewModel`, `GameProgressService`, and some views.
- Bias tagging is hard-coded by phase/stage number in `StageViewModel.swift:350-363`.
- Scoring rules are partly inferred from legacy decision types in `StageDefinition.swift:475-491`.
- The richer runtime model still depends on legacy adapters and magic strings such as `outcomeWeight.description` in `StageDefinition.swift:675-680`.

### Risks

- Adding new stage types or rules will keep increasing switch-based coupling.
- Subtle content bugs may appear when rules are encoded indirectly through strings or phase IDs.
- Domain behavior is hard to reuse or validate outside UI-heavy tests.

### Recommended Improvements

- Move scoring, bias tagging, and strategy mapping into dedicated domain types.
- Replace string-driven engine hints with explicit fields.
- Finish the migration away from `DecisionType` and `StageConfig`.

## Networking Layer

### Fact

- No networking layer is present.
- Repo-wide scans found no `URLSession`, no third-party networking library, and no auth stack.

### Assessment

- This is consistent with the app's offline-first design.
- There is no abstraction for future remote content, analytics upload, or sync.

### Recommendation

- No immediate networking work is needed.
- If remote content is planned, introduce it behind a repository boundary rather than from SwiftUI views.

## Persistence Layer

### Strengths

- SwiftData usage is simple and local.
- Tests use in-memory containers effectively.
- The persisted model set is small.

### Issues

- Persistence errors are silently swallowed throughout core flows:
  - `GameProgressService.swift:22-29`
  - `GameProgressService.swift:83`
  - `GameProgressService.swift:91`
  - `GameProgressService.swift:125`
  - `GameProgressService.swift:161`
  - `GameProgressService.swift:188`
  - `GameProgressService.swift:299`
  - `ContentView.swift:38`
  - `PhaseCompletionViewModel.swift:33`
  - `PhaseCompletionViewModel.swift:49`
  - `PhaseCompletionViewModel.swift:68`
- Several entities persist JSON blobs and strings instead of structured fields:
  - `DecisionRecord.playerDecisionJSON`
  - `DecisionRecord.optimalDecisionJSON`
  - `DecisionRecord.outcomeJSON`
  - `StageSessionRecord.pendingDecisionJSON`
  - `PhaseCompletionRecord.decisionSummaryJSON`
- The app assumes one canonical `GameProgress` by reading `progressRecords.first` or `fetch(...).first`:
  - `ContentView.swift:12`
  - `StageContainerView.swift:20`
  - `PhaseMapView.swift:10`
  - `GameProgressService.swift:20-29`

### Risks

- Silent data loss or silent state corruption
- Hard migrations once the persisted model evolves
- Nondeterministic behavior if duplicate `GameProgress` rows are ever created

### Recommended Improvements

- Replace `try?` with surfaced domain errors or structured logging.
- Enforce singleton semantics for `GameProgress`.
- Normalize JSON-string fields into explicit model properties where possible.
- Add a SwiftData migration/versioning strategy before schema changes accumulate.

## Concurrency

### Strengths

- Core mutable gameplay objects are marked `@MainActor`.
- The simulation engine itself is stateless and deterministic.
- Timed decisions cancel their timeout task on submit or deinit.

### Issues

- Simulation runs synchronously on the main actor in `StageViewModel.runSimulation()` at `StageViewModel.swift:206-217`.
- Timer-driven snapshot updates plus main-actor SwiftData saves create avoidable contention.
- Session restore replays simulation rather than restoring a persisted result in `StageViewModel.swift:48-73`.

### Risks

- Main-thread blocking if stage complexity increases
- Unnecessary energy and IO use during countdown timers
- Fragile resume semantics across future engine or content changes

### Recommended Improvements

- Throttle or debounce session persistence.
- Move heavy simulation work off the main actor if scenarios become larger.
- Persist stable replay/result artifacts if resume fidelity matters across versions.

## Overall Layer Assessment

The app layers are understandable but not cleanly separated. The current design is effective for an offline educational game with a small team, but the persistence and domain boundaries need attention before the codebase can scale safely.
