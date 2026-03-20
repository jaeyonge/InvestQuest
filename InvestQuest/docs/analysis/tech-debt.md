# Technical Debt Analysis

## Summary

The repository carries meaningful structural debt, but it is concentrated in a few places rather than spread everywhere. Most debt comes from a successful prototype growing features without finishing architectural cleanup.

## Debt Categories

### 1. Architectural Drift Debt

Evidence:

- Legacy and current stage models coexist in `StageDefinition.swift`.
- Authored content still uses `DecisionType` and `StageConfig`.
- Runtime uses `DecisionSpec` and `StageSimulation`.
- Adapter code exists in both directions.

Root cause:

- Migration was started but not completed.

Risk:

- High

Why:

- Every new feature has to respect both worlds.
- Developers have to understand multiple representations of the same concept.

### 2. Persistence Debt

Evidence:

- Core persistence paths use `try?`.
- SwiftData entities store JSON blobs and strings instead of richer typed fields.
- Singleton assumptions for `GameProgress` are not enforced.
- No explicit migration/versioning strategy is present.

Root cause:

- Simplicity-first local persistence design.

Risk:

- High

Why:

- This affects correctness, operability, and schema evolution.

### 3. Separation-Of-Concerns Debt

Evidence:

- Views directly instantiate services from `@Query`.
- `StageViewModel` owns simulation, scoring, hinting, snapshot generation, and bias logic.
- `DecisionView` contains behavioral summary domain logic.

Root cause:

- Product features were added in the shortest path through existing types.

Risk:

- High

Why:

- Future features will increase coupling nonlinearly.

### 4. Content Configuration Debt

Evidence:

- Phase content is authored as static Swift files.
- Several behaviors depend on magic strings or phase/stage IDs.
- Unused richer decision types exist but are not adopted by content.

Root cause:

- Static content gave fast iteration and easy testing early on.

Risk:

- Medium to high

Why:

- Content maintenance and evolution become brittle as content volume grows.

### 5. Build And Operational Debt

Evidence:

- No CI config found
- No xcconfigs
- generated project and generator source both checked in
- no lint/format enforcement
- minimal signing/versioning setup

Root cause:

- Local development focus over team-scale workflow.

Risk:

- Medium

Why:

- The app is easy to work on alone, but not guarded well for team changes.

### 6. Testing Debt

Evidence:

- Test count is high, but failure-path and migration coverage are weak.
- Tests are strongly coupled to static content and literal strings.

Root cause:

- Requirements-first test authoring.

Risk:

- Medium

Why:

- The suite is impressive, but it can create false confidence around resilience and maintainability.

## Root Causes

Primary root causes across categories:

- Prototype-to-product growth without module extraction
- unfinished migration away from legacy stage models
- optimization for deterministic gameplay delivery over durable architecture
- absence of release/CI automation

## Risk Assessment

Highest-risk debt:

- silent persistence failures
- high-frequency session saves
- dual-model architecture in `StageDefinition`
- lack of explicit boundaries between UI, domain logic, and storage

Lower-risk debt:

- repeated catalog recomputation
- missing formatting/lint tooling
- some unused APIs and dead branches

## Debt That Can Wait

- performance micro-optimizations in catalog lookups
- modularization into multiple packages if team size stays small
- advanced analytics or remote configuration concerns

## Debt That Should Not Wait

- persistence error handling
- session save throttling
- SwiftData singleton/migration hardening
- legacy/current model cleanup plan

## Recommended Debt Paydown Order

1. Reliability debt in persistence and session saving
2. Domain boundary cleanup around `StageViewModel` and `GameProgressService`
3. Legacy model migration completion
4. Build/CI automation
5. Content authoring and localization strategy
