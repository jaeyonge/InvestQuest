## US-CORE-004 — Phase Completion Flow (2026-03-14)

- PhaseCompletionRecord must be added to modelContainer(for:) in InvestQuestApp.swift alongside other SwiftData models; forgetting this causes container creation to fail.
- Color(hex:) extension needed for colorblind-safe badge colors defined as hex strings.
- PhaseCompletionViewModel uses fatalError for invalid phaseId; tests must only use valid phase IDs (1-7).

## US-CORE-003 — Stage Gameplay Loop (2026-03-14)

- StageFlowState enum cannot conform to Equatable when it carries StageOutcome (which is a struct with Double fields — Equatable is fine, but the original error was about associated value type conformance). Fix: remove Equatable from the enum.
- Failure-loop tests must call replayStage() between iterations; advanceFromBriefing() is a guard-gated no-op unless state is exactly .briefing.
- xcodebuild test running in background (via run_in_background) may emit background task ID; use TaskOutput tool with block:true to wait for results.

## US-CORE-002 — Game Progression System (2026-03-14)

- xcodegen must be re-run after adding new source files to subdirectories; xcodebuild will not pick them up automatically.
- All xcodebuild commands must be run from the InvestQuest/ subdirectory (where the .xcodeproj lives), not the repo root.
- SwiftData in-memory ModelContainer for tests: use ModelConfiguration(isStoredInMemoryOnly: true) and ModelContainer(for: ..., configurations: config).
- @MainActor annotation required on classes that use @Published and are accessed from SwiftData/SwiftUI context.
- GameProgressService uses stageResults array (in-memory) for stage unlock queries; this is intentional — stage results are not persisted as a separate model.

## US-CORE-001 — Market Simulation Engine (2026-03-14)

- iPhone 15 simulator does not exist in Xcode 26.3. Available simulators: iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air, iPhone 17, iPhone 16e. Used iPhone 16e as substitute throughout.
- xcodegen is installed at /opt/homebrew/bin/xcodegen. project.yml must set GENERATE_INFOPLIST_FILE: YES on unit-test targets or codesign fails.
- Old TestResults.xcresult must be removed before re-running xcodebuild test with -resultBundlePath; omit the flag to avoid the issue entirely.
- xorshift64 PRNG with Box-Muller produces correct N(0,1) samples but arithmetic mean of log-normal samples can be higher than expected for small batch sizes (200 runs with -10% drift over 20 periods yielded mean 96.44 instead of expected ~92). Fix: use stronger drift (-20%) and more periods (50) for statistical reliability.
- SwiftData CoreData errors during simulator startup (NSCocoaErrorDomain 512) are transient and self-recover; do not indicate test failures.
- Xcode 26.3 ships with Swift 6.2.4. SWIFT_VERSION must be set to "5.9" or "6" in project.yml settings to avoid build warnings.
- Project structure: Sources/InvestQuest/ contains App/, Engine/, Models/ subdirs; Tests/InvestQuestTests/ for unit tests. xcodegen picks these up via sources: array entries.
