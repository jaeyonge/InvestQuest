# Testing Analysis

## Coverage Snapshot

Evidence from `xcodebuild test -scheme InvestQuest -project InvestQuest.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'`:

- Unit tests: 324 passed
- UI tests: 6 passed
- Unit test execution: about 4.7 seconds wall-clock from xcodebuild output
- UI test execution: about 120 seconds wall-clock from xcodebuild output

Test inventory:

- Phase-by-phase content tests
- State machine tests
- Persistence tests with in-memory SwiftData
- Non-functional requirement tests
- UI flow tests with seeded stores

## Strengths

- The repository has unusually strong test volume for its size.
- Engine determinism is well covered.
- In-memory SwiftData containers make most unit tests fast and isolated.
- UI tests seed local persistence predictably through `AppRuntimeSupport`.
- The tests document intended product behavior very clearly.

## What Is Actually Covered Well

- Phase content integrity and sequencing
- Basic progression and stage unlock rules
- Stage state machine transitions
- Simulation determinism and speed
- Selected first-run, recap, and resume flows

## Gaps And Weaknesses

### 1. Coverage Is Broad, But Not Deep At Failure Boundaries

The suite validates many happy-path requirements, but it barely exercises:

- SwiftData save failures
- duplicate `GameProgress` rows
- migration compatibility
- malformed persisted JSON
- invalid or partially corrupted stores
- route/persistence disagreement

### 2. Tests Are Strongly Coupled To Static Content

Many tests validate literal strings, static concept text, and authored stage configuration. This is useful for regression control, but it does not create strong confidence in architectural seams.

### 3. UI Tests Are Functional But Narrow

Current UI tests cover:

- first launch
- stage completion and unlock
- phase map lock state
- timed auto-submit
- resume after relaunch
- behavioral review summary

Not covered:

- phase summary flow
- failure/replay loops
- duplicate-store scenarios
- accessibility behavior beyond existence of identifiers
- device class differences

### 4. Mocking Strategy Is Minimal

Observed seam:

- `MarketSimulationEngineProtocol`

Missing seams:

- no repository protocol
- no routing abstraction
- no persistence failure injection boundary

This means many tests can only validate current implementation, not alternative implementations or error handling paths.

## Reliability Assessment

Positive:

- Unit tests are fast and deterministic.
- UI tests use seeded storage instead of brittle end-to-end setup.

Residual reliability risks:

- UI tests rely on literal text and accessibility IDs.
- UI tests still require long waits and can be slow.
- Some async timeout tests explicitly tolerate scheduler jitter, which is pragmatic but indicates boundary fragility.

## High-Risk Untested Areas

- Persistence failure handling
- SwiftData schema evolution
- data corruption recovery
- behavior when multiple `GameProgress` records exist
- throttling and performance characteristics of frequent session saves
- regression of unused richer decision types if they are later activated

## Recommended Improvements

- Add unit tests around save/fetch failure paths via an injected persistence boundary.
- Add store-integrity tests for duplicate or malformed progress/session records.
- Add migration smoke tests before changing SwiftData models.
- Add a small number of targeted snapshot/accessibility tests for key views.
- Add CI execution for the existing test suite and publish pass/fail plus optional coverage.

## Testing Maturity

Assessment:

- Gameplay correctness maturity: good
- Architecture/regression maturity: moderate
- Operability and failure-path maturity: low to moderate

The existing suite is a real asset, but its breadth should not be mistaken for strong resilience coverage.
