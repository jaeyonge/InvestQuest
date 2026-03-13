import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class PhaseCompletionTests: XCTestCase {

    // MARK: - Helpers

    private func makeResults(phase: Int, count: Int, score: Int = 75) -> [StageResult] {
        (1...count).map {
            StageResult(phase: phase, stage: $0, score: score, completedAt: .now)
        }
    }

    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: GameProgress.self, DecisionRecord.self, PhaseCompletionRecord.self,
            configurations: config
        )
        return ModelContext(container)
    }

    // MARK: - AC1: Concept named in plain language

    func testConceptName_isPlainLanguage() {
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: makeResults(phase: 1, count: 5))
        XCTAssertEqual(vm.completedPhaseConfig.concept, "Inflation",
                       "Phase 1 concept must be 'Inflation'")
        XCTAssertFalse(vm.completedPhaseConfig.concept.isEmpty)
    }

    func testConceptName_allPhasesHaveConcept() {
        for phaseId in 1...7 {
            let vm = PhaseCompletionViewModel(
                phaseId: phaseId,
                stageResults: makeResults(phase: phaseId, count: 4))
            XCTAssertFalse(vm.completedPhaseConfig.concept.isEmpty,
                           "Phase \(phaseId) must have a non-empty concept name")
        }
    }

    // MARK: - AC2: Performance dashboard

    func testPerformanceDashboard_hasDataPointsPerStage() {
        let results = makeResults(phase: 1, count: 5, score: 80)
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: results)
        XCTAssertEqual(vm.performanceData.count, 5,
                       "Performance dashboard must have one data point per stage")
    }

    func testPerformanceDashboard_optimalIsAlways100() {
        let results = makeResults(phase: 1, count: 5, score: 60)
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: results)
        for point in vm.performanceData {
            XCTAssertEqual(point.optimalScore, 100,
                           "Optimal score must always be 100")
        }
    }

    func testPerformanceDashboard_playerScoreReflectsResults() {
        let results = makeResults(phase: 1, count: 3, score: 72)
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: results)
        for point in vm.performanceData {
            XCTAssertEqual(point.playerScore, 72)
        }
    }

    func testAverageScore_calculatedCorrectly() {
        let results = [
            StageResult(phase: 1, stage: 1, score: 60, completedAt: .now),
            StageResult(phase: 1, stage: 2, score: 80, completedAt: .now),
            StageResult(phase: 1, stage: 3, score: 100, completedAt: .now)
        ]
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: results)
        XCTAssertEqual(vm.averageScore, 80, "Average of 60+80+100 = 80")
    }

    // MARK: - AC3: Badge awarded and persisted

    func testBadge_awardedOnPhaseCompletion() {
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: makeResults(phase: 1, count: 5))
        XCTAssertNotNil(vm.badge, "Badge must be awarded on phase completion")
        XCTAssertEqual(vm.badge?.phaseId, 1)
    }

    func testBadge_allPhasesHaveBadge() {
        XCTAssertEqual(Badge.all.count, 7, "Must have one badge per phase")
        for phaseId in 1...7 {
            XCTAssertNotNil(Badge.all.first(where: { $0.phaseId == phaseId }),
                            "Phase \(phaseId) must have a badge")
        }
    }

    func testBadge_persistedToSwiftData() throws {
        let context = try makeInMemoryContext()
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: makeResults(phase: 1, count: 5))
        vm.persistCompletion(modelContext: context)

        let descriptor = FetchDescriptor<PhaseCompletionRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records.count, 1, "One PhaseCompletionRecord must be persisted")
        XCTAssertEqual(records[0].phaseId, 1)
        XCTAssertFalse(records[0].badgeIdentifier.isEmpty)
        XCTAssertTrue(vm.isPersisted)
    }

    // MARK: - AC4: Next phase unlocked with teaser

    func testNextPhase_teaserAvailableAfterPhase1() {
        let vm = PhaseCompletionViewModel(phaseId: 1, stageResults: makeResults(phase: 1, count: 5))
        XCTAssertNotNil(vm.nextPhaseConfig, "Next phase config must be available after Phase 1")
        XCTAssertEqual(vm.nextPhaseConfig?.id, 2)
        XCTAssertFalse(vm.nextPhaseConfig?.teaserDescription.isEmpty ?? true)
    }

    func testNextPhase_noTeaserAfterPhase7() {
        let vm = PhaseCompletionViewModel(phaseId: 7, stageResults: makeResults(phase: 7, count: 4))
        XCTAssertNil(vm.nextPhaseConfig, "No next phase after Phase 7")
    }

    func testNextPhase_progressServiceUnlocksNextPhase() throws {
        let context = try makeInMemoryContext()
        let progress = GameProgress()
        context.insert(progress)
        let service = GameProgressService(progress: progress)

        // Complete all 5 stages of phase 1
        for stage in 1...5 {
            service.completeStage(phase: 1, stage: stage, score: 80, modelContext: context)
        }
        XCTAssertTrue(service.isPhaseUnlocked(2),
                      "Phase 2 must be unlocked after completing all Phase 1 stages")
    }

    // MARK: - AC5: Phase completion data persisted for Phase 7 retrieval

    func testPersistence_completionDataRetrievableAfterSave() throws {
        let context = try makeInMemoryContext()
        let results = [
            StageResult(phase: 2, stage: 1, score: 90, completedAt: .now),
            StageResult(phase: 2, stage: 2, score: 85, completedAt: .now)
        ]
        let vm = PhaseCompletionViewModel(phaseId: 2, stageResults: results)
        vm.persistCompletion(modelContext: context)

        // Verify retrievable
        let descriptor = FetchDescriptor<PhaseCompletionRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records[0].phaseId, 2)
        XCTAssertEqual(records[0].conceptName, "Valuation")
        XCTAssertFalse(records[0].decisionSummaryJSON.isEmpty,
                       "Decision summary JSON must be populated for Phase 7 retrieval")
    }

    func testPersistence_decisionSummaryContainsStageData() throws {
        let context = try makeInMemoryContext()
        let results = makeResults(phase: 3, count: 4, score: 65)
        let vm = PhaseCompletionViewModel(phaseId: 3, stageResults: results)
        vm.persistCompletion(modelContext: context)

        let descriptor = FetchDescriptor<PhaseCompletionRecord>()
        let record = try context.fetch(descriptor).first!

        // JSON should encode stage data
        XCTAssertTrue(record.decisionSummaryJSON.contains("stage"),
                      "Decision summary must reference stage data")
    }
}
