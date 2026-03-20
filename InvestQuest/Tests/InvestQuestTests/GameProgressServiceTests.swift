import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class GameProgressServiceTests: XCTestCase {

    // MARK: - AC1: Phase map and routing metadata

    func testPhaseConfig_all7PhasesExist() {
        XCTAssertEqual(PhaseConfig.all.count, 7, "Must have exactly 7 phases")
        XCTAssertEqual(PhaseConfig.all.map { $0.id }, [1, 2, 3, 4, 5, 6, 7])
    }

    func testPhaseConfig_allPhasesHaveRequiredFields() {
        for phase in PhaseConfig.all {
            XCTAssertFalse(phase.title.isEmpty, "Phase \(phase.id) must have a title")
            XCTAssertFalse(phase.concept.isEmpty, "Phase \(phase.id) must have a concept")
            XCTAssertGreaterThan(phase.stageCount, 0, "Phase \(phase.id) must have stages")
            XCTAssertFalse(phase.teaserDescription.isEmpty, "Phase \(phase.id) must have a teaser")
        }
    }

    // MARK: - AC2: Sequential phase unlock

    func testPhaseUnlock_phase1AlwaysUnlocked() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertTrue(service.isPhaseUnlocked(1), "Phase 1 must always be unlocked")
    }

    func testPhaseUnlock_phase2LockedUntilPhase1Complete() throws {
        let (_, _, locked) = try TestDataFactory.makeService(progress: GameProgress(completedPhases: []))
        XCTAssertFalse(locked.isPhaseUnlocked(2), "Phase 2 must be locked when Phase 1 not done")

        let (_, _, unlocked) = try TestDataFactory.makeService(progress: GameProgress(completedPhases: [1]))
        XCTAssertTrue(unlocked.isPhaseUnlocked(2), "Phase 2 must unlock after Phase 1 completion")
    }

    func testPhaseUnlock_cannotSkipPhases() throws {
        let (_, _, service) = try TestDataFactory.makeService(progress: GameProgress(completedPhases: [1]))
        XCTAssertFalse(service.isPhaseUnlocked(3), "Phase 3 must not unlock when only Phase 1 done")
        XCTAssertFalse(service.isPhaseUnlocked(7), "Phase 7 must not unlock when only Phase 1 done")
    }

    func testPhaseUnlock_allUnlockSequentially() throws {
        var completed: [Int] = []
        for phaseId in 1...7 {
            let (_, _, service) = try TestDataFactory.makeService(progress: GameProgress(completedPhases: completed))
            XCTAssertTrue(service.isPhaseUnlocked(phaseId),
                          "Phase \(phaseId) should be unlocked after completing all previous")
            if phaseId < 7 {
                XCTAssertFalse(service.isPhaseUnlocked(phaseId + 1),
                               "Phase \(phaseId + 1) must not yet be unlocked")
            }
            completed.append(phaseId)
        }
    }

    func testPhaseCompletion_tracked() throws {
        let (_, _, service) = try TestDataFactory.makeService(progress: GameProgress(completedPhases: [1, 2]))
        XCTAssertTrue(service.isPhaseCompleted(1))
        XCTAssertTrue(service.isPhaseCompleted(2))
        XCTAssertFalse(service.isPhaseCompleted(3))
    }

    // MARK: - AC3: Stage unlock with minimum score

    func testStageUnlock_stage1AlwaysUnlockedInUnlockedPhase() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 1))
    }

    func testStageUnlock_stage2LockedWithoutSufficientScore() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2))
    }

    func testStageUnlock_stage2UnlocksAfterMinScore() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        service.completeStage(
            address: StageAddress(phase: 1, stage: 1),
            outcome: TestDataFactory.makeOutcome(score: 60)
        )
        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 2),
                      "Stage 2 should unlock after stage 1 score ≥ 60")
    }

    func testStageUnlock_belowMinScoreKeepsNextStageLocked() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        service.completeStage(
            address: StageAddress(phase: 1, stage: 1),
            outcome: TestDataFactory.makeOutcome(
                score: 40,
                decision: PlayerDecision.holdCash,
                optimal: PlayerDecision.binary(choice: "A")
            )
        )
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2),
                       "Stage 2 must remain locked when stage 1 score < 60")
    }

    func testStageUnlock_lockedInLockedPhase() throws {
        let (_, _, service) = try TestDataFactory.makeService()
        XCTAssertFalse(service.isStageUnlocked(phase: 2, stage: 1),
                       "Stage 1 of Phase 2 must be locked when Phase 2 is locked")
    }

    // MARK: - AC4 & AC5: Auto-save and persistence

    func testRecordDecision_persistsDecisionRecord() throws {
        let (_, context, service) = try TestDataFactory.makeService()
        let address = StageAddress(phase: 1, stage: 1)
        let decision = PlayerDecision.allocation(["cash": 0.25, "bonds": 0.75])
        let optimal = PlayerDecision.allocation(["cash": 0.10, "bonds": 0.90])
        let outcome = TestDataFactory.makeOutcome(score: 72, decision: decision, optimal: optimal, biasTags: ["loss-aversion"])

        service.recordDecision(
            address: address,
            decisionType: "allocation",
            decision: decision,
            optimalDecision: optimal,
            outcome: outcome,
            decisionLatencyMs: 1400,
            biasTags: ["loss-aversion"]
        )

        let descriptor = FetchDescriptor<DecisionRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records.count, 1, "Decision must be persisted")
        XCTAssertEqual(records[0].phase, 1)
        XCTAssertEqual(records[0].stage, 1)
        XCTAssertEqual(records[0].decisionType, "allocation")
        XCTAssertEqual(records[0].score, 72)
        XCTAssertEqual(records[0].decisionLatencyMs, 1400)
        XCTAssertEqual(records[0].biasTags, ["loss-aversion"])

        let savedDecision = try JSONDecoder().decode(
            PlayerDecision.self,
            from: Data(records[0].playerDecisionJSON.utf8)
        )
        let savedOptimal = try JSONDecoder().decode(
            PlayerDecision.self,
            from: Data(records[0].optimalDecisionJSON.utf8)
        )
        XCTAssertEqual(savedDecision, decision)
        XCTAssertEqual(savedOptimal, optimal)
    }

    func testRecordDecision_updatesCurrentPosition() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 1)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)

        service.recordDecision(
            address: StageAddress(phase: 2, stage: 3),
            decisionType: "binary",
            decision: PlayerDecision.binary(choice: "A"),
            optimalDecision: PlayerDecision.binary(choice: "A"),
            outcome: nil as StageOutcome?,
            decisionLatencyMs: 900
        )

        XCTAssertEqual(service.progress.currentPhase, 2)
        XCTAssertEqual(service.progress.currentStage, 3)
    }

    func testCompleteStage_persistsCompletionAndAdvancesProgress() throws {
        let (_, context, service) = try TestDataFactory.makeService()
        let address = StageAddress(phase: 1, stage: 1)

        service.completeStage(address: address, outcome: TestDataFactory.makeOutcome(score: 88))

        let records = try context.fetch(FetchDescriptor<StageCompletionRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.phase, 1)
        XCTAssertEqual(records.first?.stage, 1)
        XCTAssertEqual(records.first?.bestScore, 88)
        XCTAssertEqual(service.progress.currentPhase, 1)
        XCTAssertEqual(service.progress.currentStage, 2)
    }

    func testCompleteStage_completingAllStagesCompletesPhase() throws {
        let (_, _, service) = try TestDataFactory.makeService()

        for stage in 1...StageCatalog.stageCount(forPhase: 1) {
            service.completeStage(
                address: StageAddress(phase: 1, stage: stage),
                outcome: TestDataFactory.makeOutcome(score: 80)
            )
        }

        XCTAssertTrue(service.isPhaseCompleted(1), "Phase 1 must be complete after all 5 stages done")
        XCTAssertTrue(service.isPhaseUnlocked(2), "Phase 2 must unlock after Phase 1 completion")
    }

    func testSaveSession_roundTripsSnapshot() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 1, hasSeenIntro: true)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        service.completeStage(address: StageAddress(phase: 1, stage: 1), outcome: TestDataFactory.makeOutcome(score: 80))
        let snapshot = StageSessionSnapshot(
            address: StageAddress(phase: 1, stage: 2),
            flowState: .simulation,
            currentPeriod: 3,
            failureCount: 2,
            pendingDecision: .ranking(["stocks", "bonds", "cash"]),
            timeRemaining: 0
        )

        service.saveSession(snapshot)

        XCTAssertEqual(service.loadStageSession(), snapshot)
    }

    func testSaveSession_updatesCurrentPosition() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 1)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        let snapshot = StageSessionSnapshot(
            address: StageAddress(phase: 3, stage: 1),
            flowState: .briefing,
            currentPeriod: 0,
            failureCount: 0,
            pendingDecision: nil,
            timeRemaining: 0
        )

        service.saveSession(snapshot)

        XCTAssertEqual(progress.currentPhase, 3)
        XCTAssertEqual(progress.currentStage, 1)
    }

    func testLoadStageSession_discardsSessionBehindProgress() throws {
        let progress = GameProgress(currentPhase: 1, currentStage: 2, hasSeenIntro: true)
        let (_, context, service) = try TestDataFactory.makeService(progress: progress)
        context.insert(
            StageSessionRecord(
                phase: 1,
                stage: 1,
                flowState: StageFlowSnapshotState.briefing.rawValue,
                currentPeriod: 0,
                failureCount: 0,
                pendingDecisionJSON: nil,
                timeRemaining: 0
            )
        )
        try context.save()

        XCTAssertNil(service.loadStageSession())
        XCTAssertTrue((try context.fetch(FetchDescriptor<StageSessionRecord>())).isEmpty)
    }

    // MARK: - AC6: Returning user recap

    func testReturningUser_longAbsenceFlagTriggered() throws {
        let longAgo = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        let progress = GameProgress(completedPhases: [1], lastPlayedDate: longAgo)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertTrue(service.isReturningAfterLongAbsence,
                      "Long absence flag must be true after 8 days")
    }

    func testReturningUser_recentPlayerNotFlagged() throws {
        let progress = GameProgress(completedPhases: [1], lastPlayedDate: .now)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "Recent player must not be flagged as returning after long absence")
    }

    func testReturningUser_noCompletedPhasesNotFlagged() throws {
        let longAgo = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        let progress = GameProgress(completedPhases: [], lastPlayedDate: longAgo)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "First-time player must not see recap even after absence")
    }

    func testReturningUser_recapPhaseProvidesLastCompletedPhase() throws {
        let longAgo = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        let progress = GameProgress(completedPhases: [1, 2], lastPlayedDate: longAgo)
        let (_, _, service) = try TestDataFactory.makeService(progress: progress)
        let recap = service.recapPhase
        XCTAssertNotNil(recap)
        XCTAssertEqual(recap?.id, 2, "Recap should show last completed phase (2)")
    }

    func testHardMode_requiresBestScoreThresholdForEveryStage() throws {
        let (_, _, service) = try TestDataFactory.makeService()

        for stage in 1...StageCatalog.stageCount(forPhase: 1) {
            let score = stage == 2 ? 79 : 85
            service.completeStage(
                address: StageAddress(phase: 1, stage: stage),
                outcome: TestDataFactory.makeOutcome(score: score)
            )
        }

        XCTAssertFalse(service.isHardModeAvailable(forPhase: 1))
    }
}
