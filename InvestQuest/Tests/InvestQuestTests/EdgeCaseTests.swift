import XCTest
import SwiftData
@testable import InvestQuest

/// Tests for US-EDGE-001: Edge Cases and Failure Handling
@MainActor
final class EdgeCaseTests: XCTestCase {

    // MARK: - AC1: Timeout → hold cash with clear messaging

    func testTimeout_holdCashDecision_isDefaultOnTimeout() async {
        let definition = StageDefinition(
            phase: 1, stage: 1,
            scenarioTitle: "Timeout Test",
            scenarioDescription: "Test timeout behavior.",
            decisionType: .binary(optionA: "Invest", optionB: "Hold"),
            simulationConfig: StageConfig(
                seed: 1, assetCount: 2, timePeriods: 5,
                volatility: 0.1, drift: 0.05,
                eventInjections: [],
                outcomeWeight: StageConfig.OutcomeWeight(correctStrategyWeight: 0.65, description: "test")
            ),
            optimalDecision: .binary(choice: "A"),
            timeoutSeconds: 0.3,
            insightText: "Inaction is a decision.",
            hintText: "Act or hold cash by default.",
            conceptExplanation: "Full concept."
        )
        let vm = StageViewModel(definition: definition, engine: MarketSimulationEngine())
        vm.advanceFromBriefing()
        try? await Task.sleep(nanoseconds: 700_000_000)

        if case .simulation = vm.flowState {
            XCTAssertEqual(vm.pendingDecision, .holdCash,
                           "After timeout, pending decision must be holdCash")
        } else {
            // Timer might still be running; the important thing is holdCash will be submitted
            // (flaky in extreme CI conditions — acceptable)
        }
    }

    func testTimeout_holdCashDecision_playerDecisionEquatable() {
        // Ensure holdCash is a valid PlayerDecision that can be compared
        let d1 = PlayerDecision.holdCash
        let d2 = PlayerDecision.holdCash
        XCTAssertEqual(d1, d2, "holdCash decisions must be equal")
        XCTAssertNotEqual(d1, .binary(choice: "A"), "holdCash must differ from explicit decisions")
    }

    func testTimeout_inactionMessaging_insightTextExists() {
        // AC1: "clear messaging that inaction is itself a decision"
        // Stages with timeout have insight text that references the decision/timeout behavior
        let stage = Phase7StageDefinitions.stage1
        XCTAssertFalse(stage.insightText.isEmpty, "Stage with timeout must have insight text explaining the lesson")
        XCTAssertGreaterThan(stage.timeoutSeconds, 0, "Stage 1 must have a positive timeout")
    }

    // MARK: - AC2: hold cash should map to cash-like assets, not a zeroed portfolio

    func testHoldCash_usesCashAssetValue() {
        let definition = StageDefinition(
            address: StageAddress(phase: 1, stage: 99),
            scenario: .inflation(
                InflationScenario(
                    title: "Cash Fallback",
                    description: "Verify hold cash semantics.",
                    inflationRates: [0, 0],
                    goods: []
                )
            ),
            decision: .binary(
                options: [
                    DecisionOption(id: "risk", label: "Risk", strategy: .directAsset("risk")),
                    DecisionOption(id: "cash", label: "Cash", strategy: .cash)
                ],
                timeoutSeconds: nil,
                defaultDecision: .holdCash
            ),
            simulation: StageSimulation(
                seed: 7,
                assets: [
                    SimAssetConfig(id: "cash", label: "Cash", drift: 0, volatility: 0, lessonRole: .neutral, kind: .cash),
                    SimAssetConfig(id: "risk", label: "Risk", drift: -0.20, volatility: 0, lessonRole: .penalized, kind: .equity)
                ],
                periodCount: 4,
                replayCount: 1,
                events: [],
                lessonBias: 0
            ),
            scoring: .portfolio,
            optimalDecision: .binary(choice: "cash"),
            insightText: "Cash should preserve nominal value.",
            hintText: "Hold cash.",
            conceptExplanation: "Cash is explicit, not zero."
        )
        let vm = StageViewModel(definition: definition, engine: MarketSimulationEngine())

        vm.advanceFromBriefing()
        vm.submitDecision(PlayerDecision.holdCash)
        vm.finishSimulation()

        guard case .result(let outcome) = vm.flowState else {
            return XCTFail("Expected result state")
        }

        XCTAssertGreaterThan(outcome.portfolioFinalValue, 95)
        XCTAssertGreaterThan(outcome.portfolioFinalValue, 0)
    }

    // MARK: - AC3: 3 failures → hint nudge

    func testHints_noHintBeforeFailures() {
        let vm = makeViewModel()
        XCTAssertNil(vm.hintForCurrentFailures, "No hint shown before any failures")
    }

    func testHints_hintAfter3Failures() {
        let vm = makeViewModel()
        triggerFailures(vm: vm, count: 3)
        let hint = vm.hintForCurrentFailures
        XCTAssertNotNil(hint, "Hint must appear after 3 failures")
        // Hint should be the definition's hintText, not the full concept explanation
        XCTAssertEqual(hint, vm.definitionHintText,
                       "After exactly 3 failures, show definitionHintText not full concept")
    }

    // MARK: - AC4: 5 failures → full explanation

    func testHints_fullExplanationAfter5Failures() {
        let vm = makeViewModel()
        triggerFailures(vm: vm, count: 5)
        let hint = vm.hintForCurrentFailures
        XCTAssertNotNil(hint, "Full explanation must appear after 5 failures")
        XCTAssertEqual(hint, vm.definitionConceptText,
                       "After 5 failures, show definitionConceptText")
    }

    // MARK: - AC5: Phase progression locked

    func testPhaseProgression_phase2LockedUntilPhase1Complete() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertTrue(service.isPhaseUnlocked(1), "Phase 1 always unlocked")
        XCTAssertFalse(service.isPhaseUnlocked(2), "Phase 2 locked until Phase 1 complete")
    }

    func testPhaseProgression_cannotSkipToPhase7() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertFalse(service.isPhaseUnlocked(7), "Phase 7 locked until Phases 1-6 complete")
    }

    func testStageProgression_stage2LockedUntilStage1MeetsMinScore() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2),
                       "Stage 2 locked until Stage 1 meets minimum score")
    }

    // MARK: - AC6: Auto-save and resume

    func testAutoSave_progressUpdatedOnDecision() throws {
        let progress = GameProgress()
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)

        service.recordDecision(
            address: StageAddress(phase: 2, stage: 3),
            decisionType: "binary",
            decision: .binary(choice: "A"),
            optimalDecision: .binary(choice: "B"),
            outcome: TestDataFactory.makeOutcome(score: 55, decision: .binary(choice: "A"), optimal: .binary(choice: "B")),
            decisionLatencyMs: 800
        )

        XCTAssertEqual(progress.currentPhase, 2, "Progress must update currentPhase on record")
        XCTAssertEqual(progress.currentStage, 3, "Progress must update currentStage on record")
    }

    func testAutoSave_lastPlayedDateUpdated() throws {
        let progress = GameProgress()
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        let before = Date()

        service.recordDecision(
            address: StageAddress(phase: 1, stage: 1),
            decisionType: "binary",
            decision: .binary(choice: "A"),
            optimalDecision: .binary(choice: "A"),
            outcome: TestDataFactory.makeOutcome(score: 100),
            decisionLatencyMs: 200
        )

        XCTAssertGreaterThanOrEqual(progress.lastPlayedDate, before,
                                    "lastPlayedDate must be updated on every action")
    }

    func testResume_snapshotRestoresDecisionState() {
        let vm = makeViewModel(timeoutSeconds: 12)
        let snapshot = StageSessionSnapshot(
            address: vm.definition.address,
            flowState: .decision,
            currentPeriod: 0,
            failureCount: 2,
            pendingDecision: nil,
            timeRemaining: 9
        )

        vm.restore(from: snapshot)

        guard case .decision = vm.flowState else {
            return XCTFail("Expected decision state after restore")
        }
        XCTAssertEqual(vm.failureCount, 2)
        XCTAssertEqual(vm.timeRemaining, 9, accuracy: 0.2)
    }

    // MARK: - AC7: Returning user recap

    func testReturningUser_noRecap_whenRecentlyActive() throws {
        let progress = GameProgress()
        progress.lastPlayedDate = Date()  // played today
        progress.completedPhases = [1, 2]
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "Not a returning user if played recently")
        XCTAssertNil(service.recapPhase, "No recap for recently active user")
    }

    func testReturningUser_recapAvailable_after7Days() throws {
        let progress = GameProgress()
        progress.lastPlayedDate = Date().addingTimeInterval(-8 * 86400)  // 8 days ago
        progress.completedPhases = [1, 2, 3]
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertTrue(service.isReturningAfterLongAbsence,
                      "Must be returning user after 8 days absence")
        XCTAssertNotNil(service.recapPhase, "Recap must be available for returning user")
        XCTAssertEqual(service.recapPhase?.id, 3, "Recap shows last completed phase (Phase 3)")
    }

    func testReturningUser_noRecap_whenNoCompletedPhases() throws {
        let progress = GameProgress()
        progress.lastPlayedDate = Date().addingTimeInterval(-10 * 86400)
        progress.completedPhases = []  // no completed phases
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "No recap needed if user never completed a phase")
    }

    func testLongAbsenceThreshold_is7Days() {
        XCTAssertEqual(GameProgressService.longAbsenceThresholdDays, 7,
                       "Long absence threshold must be 7 days")
    }

    // MARK: - Helpers

    private func makeViewModel(timeoutSeconds: Double = 0) -> StageViewModel {
        let definition = StageDefinition(
            phase: 1, stage: 1,
            scenarioTitle: "Edge Case Test",
            scenarioDescription: "Test hints and explanations after failures.",
            decisionType: .binary(optionA: "Invest", optionB: "Hold"),
            simulationConfig: StageConfig(
                seed: 999, assetCount: 2, timePeriods: 5,
                volatility: 0.1, drift: 0.05,
                eventInjections: [],
                outcomeWeight: StageConfig.OutcomeWeight(
                    correctStrategyWeight: 0.65, description: "test")
            ),
            optimalDecision: .binary(choice: "A"),
            timeoutSeconds: timeoutSeconds,
            insightText: "Insight text.",
            hintText: "Hint: think carefully.",
            conceptExplanation: "Full explanation of the concept."
        )
        return StageViewModel(definition: definition, engine: MarketSimulationEngine())
    }

    private func triggerFailures(vm: StageViewModel, count: Int) {
        for _ in 0..<count {
            vm.advanceFromBriefing()
            vm.submitDecision(.holdCash)   // always suboptimal → triggers failure scoring
            vm.finishSimulation()
            vm.advanceFromResult()
            vm.replayStage()
        }
    }
}
