# iOS Codebase Review

## Executive Summary

InvestQuest is a compact, coherent SwiftUI codebase with strong deterministic behavior and an unusually healthy amount of automated testing for its size. The app is clearly maintainable in the short term by a small team, and the full scheme test run passed during this audit.

Engineering maturity is mixed:

- Gameplay correctness maturity: good
- Architectural maturity: low to moderate
- Operational maturity: low to moderate
- Production readiness: acceptable for a local-first educational app, but not yet hardened for safe long-term scaling

The main theme is not "bad code." The main theme is "prototype architecture that succeeded and now needs boundaries."

## Strengths

- Clear product flow and deterministic simulation engine
- Single-target simplicity and zero third-party dependency surface
- Good local naming and folder organization
- Strong unit-test coverage around gameplay rules and content integrity
- Seeded UI tests for first-run, progression, timeout, resume, and behavioral-review flows
- Offline-first design with no backend or auth attack surface

## Critical Issues

No Sev-0 or immediate ship blockers were found for the current offline scope.

The highest-risk items are reliability and architectural issues rather than crashing defects.

## High Priority Issues

### 1. Core persistence failures are silently ignored

Evidence:

- `GameProgressService.swift:20-29`
- `GameProgressService.swift:78-91`
- `GameProgressService.swift:124-188`
- `ContentView.swift:36-39`
- `PhaseCompletionViewModel.swift:27-38`
- `PhaseCompletionViewModel.swift:43-69`

Impact:

- Progress, session state, or completion data can fail to save without any user-visible indication.

### 2. Timed decisions trigger main-thread SwiftData saves every 100ms

Evidence:

- `StageViewModel.swift:183-203`
- `StageContainerView.swift:85-88`
- `GameProgressService.swift:164-188`

Impact:

- Unnecessary IO churn
- avoidable responsiveness and battery risk
- weak persistence design under sustained timers

### 3. The core architecture still carries dual legacy/current gameplay models

Evidence:

- `StageDefinition.swift:41-218`
- `StageDefinition.swift:475-579`
- `StageDefinition.swift:660-760`

Impact:

- Higher cognitive load
- more bug surface
- slower feature delivery

### 4. UI, domain, and persistence layers are tightly coupled

Evidence:

- `ContentView.swift:12-18`
- `StageContainerView.swift:19-20`
- `PhaseMapView.swift:10-20`
- `DecisionView.swift:337-468`
- `StageViewModel.swift:124-165`

Impact:

- Harder reuse and testing
- increasing change cost as features expand

## Medium Issues

- SwiftData persistence uses JSON-string fields instead of richer typed models.
- The app assumes a single `GameProgress` row but does not enforce uniqueness.
- There is no explicit SwiftData migration/versioning strategy.
- Some richer decision types appear unused by authored content:
  - valuation
  - stop-loss
  - review
- Behavioral bias logic is partly hard-coded by phase/stage ID.
- No CI, xcconfig, lint, or project-regeneration guard was found.
- No localization resources were found even though most user-facing text is inline in source.

## Minor Issues

- `StageCatalog.all` recomputes concatenated content repeatedly.
- Some convenience APIs appear unused outside tests.
- `fatalError` remains in a few production-facing paths.
- Release/version/signing configuration is minimal.

## Architecture Assessment

The actual architecture is a single-module SwiftUI app with MVVM-ish state holders, a lightweight route coordinator, a deterministic simulation engine, and direct SwiftData integration from the UI.

This is effective for a compact offline app. It is not a cleanly layered architecture. The main architectural risk is not the single target itself; it is the lack of enforced seams between presentation, domain rules, and persistence.

## Code Quality Assessment

Code quality is solid in local readability but weaker in global responsibility boundaries.

Best qualities:

- consistent naming
- deterministic core engine
- clear intent in static phase content

Main quality concerns:

- god files
- stringly-typed persistence
- unfinished migration code
- silent failure handling

## Testing Assessment

The repository has strong test breadth for gameplay and content rules. The full audited test run passed:

- 324 unit tests passed
- 6 UI tests passed

Where the suite is strongest:

- deterministic simulation behavior
- progression rules
- content regressions
- seeded UI flows

Where it is weaker:

- failure-path persistence testing
- schema/migration testing
- resilience against corrupted or duplicate local data

## Performance Assessment

Current performance is good for the app's size and workload.

Strong evidence:

- simulation tests assert sub-second behavior
- full unit suite is fast

Main risk:

- session persistence is far more frequent than necessary during timed decisions

## Security Assessment

Security posture is favorable for current scope:

- no secrets found
- no networking/auth stack
- no third-party SDK attack surface
- no PII detected in persisted models

The main recommendation is to introduce real security boundaries before any future remote accounts, sync, or sensitive telemetry are added.

## Technical Debt Summary

Most debt falls into four buckets:

- persistence hardening
- architectural separation
- unfinished legacy-model migration
- build/CI automation

This is manageable debt, but it is no longer incidental debt. It now shapes the cost of every new feature.

## Prioritized Action Plan

### Immediate Fixes

- Replace `try?` in core persistence paths with explicit error handling and logging.
- Throttle or debounce session saves during timed decisions.
- Enforce singleton semantics for `GameProgress`.
- Remove `fatalError` from user-reachable runtime paths where recovery is possible.

### Short-Term Improvements

- Introduce a persistence boundary so views no longer instantiate `GameProgressService` directly.
- Extract scoring, bias tagging, and behavioral summary generation into domain services.
- Add tests for save failures, duplicate progress rows, and malformed stored JSON.
- Add CI that runs `xcodebuild test` and optionally checks project generation drift.

### Medium-Term Refactors

- Complete the migration from `DecisionType`/`StageConfig` to `DecisionSpec`/`StageSimulation`.
- Normalize JSON-string persistence into explicit typed models where practical.
- Introduce SwiftData migration/versioning strategy before more schema changes land.
- Split large view and view-model files by responsibility.

### Long-Term Architecture Improvements

- Introduce clearer feature/domain/data boundaries, whether by modules or by strict internal layering.
- Consider moving authored content into a structured external format once the model layer is stable.
- Add localization and release-automation infrastructure if the product is moving beyond prototype scope.

## Final Assessment

InvestQuest is a strong small codebase with real product thinking, strong tests, and low dependency risk. It is not yet a mature production architecture. The fastest way to raise its technical ceiling is to harden persistence behavior, finish the legacy-model cleanup, and stop letting the UI own data-layer responsibilities.
