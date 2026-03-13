import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class GameProgressServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeService(
        currentPhase: Int = 1,
        currentStage: Int = 1,
        completedPhases: [Int] = [],
        lastPlayedDate: Date = .now
    ) -> GameProgressService {
        let progress = GameProgress(
            currentPhase: currentPhase,
            currentStage: currentStage,
            completedPhases: completedPhases,
            lastPlayedDate: lastPlayedDate
        )
        return GameProgressService(progress: progress)
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: GameProgress.self, DecisionRecord.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - AC1: Phase Map shows all 7 phases

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

    func testPhaseUnlock_phase1AlwaysUnlocked() {
        let service = makeService(completedPhases: [])
        XCTAssertTrue(service.isPhaseUnlocked(1), "Phase 1 must always be unlocked")
    }

    func testPhaseUnlock_phase2LockedUntilPhase1Complete() {
        let locked = makeService(completedPhases: [])
        XCTAssertFalse(locked.isPhaseUnlocked(2), "Phase 2 must be locked when Phase 1 not done")

        let unlocked = makeService(completedPhases: [1])
        XCTAssertTrue(unlocked.isPhaseUnlocked(2), "Phase 2 must unlock after Phase 1 completion")
    }

    func testPhaseUnlock_cannotSkipPhases() {
        let service = makeService(completedPhases: [1])
        XCTAssertFalse(service.isPhaseUnlocked(3), "Phase 3 must not unlock when only Phase 1 done")
        XCTAssertFalse(service.isPhaseUnlocked(7), "Phase 7 must not unlock when only Phase 1 done")
    }

    func testPhaseUnlock_allUnlockSequentially() {
        var completed: [Int] = []
        for phaseId in 1...7 {
            let service = makeService(completedPhases: completed)
            XCTAssertTrue(service.isPhaseUnlocked(phaseId),
                          "Phase \(phaseId) should be unlocked after completing all previous")
            if phaseId < 7 {
                XCTAssertFalse(service.isPhaseUnlocked(phaseId + 1),
                               "Phase \(phaseId + 1) must not yet be unlocked")
            }
            completed.append(phaseId)
        }
    }

    func testPhaseCompletion_tracked() {
        let service = makeService(completedPhases: [1, 2])
        XCTAssertTrue(service.isPhaseCompleted(1))
        XCTAssertTrue(service.isPhaseCompleted(2))
        XCTAssertFalse(service.isPhaseCompleted(3))
    }

    // MARK: - AC3: Stage unlock with minimum score

    func testStageUnlock_stage1AlwaysUnlockedInUnlockedPhase() {
        let service = makeService(completedPhases: [])
        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 1))
    }

    func testStageUnlock_stage2LockedWithoutSufficientScore() {
        let service = makeService(completedPhases: [])
        // No stage results recorded → stage 2 is locked
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2))
    }

    func testStageUnlock_stage2UnlocksAfterMinScore() throws {
        let service = makeService(completedPhases: [])
        let context = try makeInMemoryContext()
        // Complete stage 1 with score meeting threshold
        service.completeStage(phase: 1, stage: 1, score: 60, modelContext: context)
        XCTAssertTrue(service.isStageUnlocked(phase: 1, stage: 2),
                      "Stage 2 should unlock after stage 1 score ≥ 60")
    }

    func testStageUnlock_belowMinScoreKeepsNextStageLocked() throws {
        let service = makeService(completedPhases: [])
        let context = try makeInMemoryContext()
        service.completeStage(phase: 1, stage: 1, score: 40, modelContext: context)
        XCTAssertFalse(service.isStageUnlocked(phase: 1, stage: 2),
                       "Stage 2 must remain locked when stage 1 score < 60")
    }

    func testStageUnlock_lockedInLockedPhase() {
        let service = makeService(completedPhases: [])
        XCTAssertFalse(service.isStageUnlocked(phase: 2, stage: 1),
                       "Stage 1 of Phase 2 must be locked when Phase 2 is locked")
    }

    // MARK: - AC4 & AC5: Auto-save and persistence

    func testRecordDecision_persistsDecisionRecord() throws {
        let service = makeService()
        let context = try makeInMemoryContext()
        let progress = service.progress
        context.insert(progress)

        service.recordDecision(phase: 1, stage: 1, decisionType: "allocation",
                               value: 0.5, optimalValue: 0.7, modelContext: context)

        let descriptor = FetchDescriptor<DecisionRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records.count, 1, "Decision must be persisted")
        XCTAssertEqual(records[0].phase, 1)
        XCTAssertEqual(records[0].stage, 1)
        XCTAssertEqual(records[0].decisionType, "allocation")
        XCTAssertEqual(records[0].value, 0.5, accuracy: 0.001)
        XCTAssertEqual(records[0].optimalValue, 0.7, accuracy: 0.001)
    }

    func testRecordDecision_updatesCurrentPosition() throws {
        let service = makeService(currentPhase: 1, currentStage: 1)
        let context = try makeInMemoryContext()
        context.insert(service.progress)

        service.recordDecision(phase: 2, stage: 3, decisionType: "binary",
                               value: 1.0, optimalValue: 1.0, modelContext: context)

        XCTAssertEqual(service.progress.currentPhase, 2)
        XCTAssertEqual(service.progress.currentStage, 3)
    }

    func testCompleteStage_completingAllStagesCompletesPhase() throws {
        let service = makeService(completedPhases: [])
        let context = try makeInMemoryContext()
        context.insert(service.progress)

        // Phase 1 has 5 stages
        service.completeStage(phase: 1, stage: 1, score: 80, modelContext: context)
        service.completeStage(phase: 1, stage: 2, score: 80, modelContext: context)
        service.completeStage(phase: 1, stage: 3, score: 80, modelContext: context)
        service.completeStage(phase: 1, stage: 4, score: 80, modelContext: context)
        service.completeStage(phase: 1, stage: 5, score: 80, modelContext: context)

        XCTAssertTrue(service.isPhaseCompleted(1), "Phase 1 must be complete after all 5 stages done")
        XCTAssertTrue(service.isPhaseUnlocked(2), "Phase 2 must unlock after Phase 1 completion")
    }

    // MARK: - AC6: Returning user recap

    func testReturningUser_longAbsenceFlagTriggered() {
        let longAgo = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        let service = makeService(completedPhases: [1], lastPlayedDate: longAgo)
        XCTAssertTrue(service.isReturningAfterLongAbsence,
                      "Long absence flag must be true after 8 days")
    }

    func testReturningUser_recentPlayerNotFlagged() {
        let service = makeService(completedPhases: [1], lastPlayedDate: .now)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "Recent player must not be flagged as returning after long absence")
    }

    func testReturningUser_noCompletedPhasesNotFlagged() {
        let longAgo = Calendar.current.date(byAdding: .day, value: -10, to: .now)!
        let service = makeService(completedPhases: [], lastPlayedDate: longAgo)
        XCTAssertFalse(service.isReturningAfterLongAbsence,
                       "First-time player must not see recap even after absence")
    }

    func testReturningUser_recapPhaseProvidesLastCompletedPhase() {
        let longAgo = Calendar.current.date(byAdding: .day, value: -8, to: .now)!
        let service = makeService(completedPhases: [1, 2], lastPlayedDate: longAgo)
        let recap = service.recapPhase
        XCTAssertNotNil(recap)
        XCTAssertEqual(recap?.id, 2, "Recap should show last completed phase (2)")
    }
}
