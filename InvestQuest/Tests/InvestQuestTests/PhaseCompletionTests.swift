import XCTest
import SwiftData
@testable import InvestQuest

@MainActor
final class PhaseCompletionTests: XCTestCase {

    // MARK: - Helpers

    private func seedStageCompletions(
        phase: Int,
        scores: [Int],
        context: ModelContext
    ) throws {
        for (index, score) in scores.enumerated() {
            context.insert(
                StageCompletionRecord(
                    phase: phase,
                    stage: index + 1,
                    latestScore: score,
                    bestScore: score,
                    latestStars: StageOutcome.starRating(for: score),
                    bestStars: StageOutcome.starRating(for: score),
                    isPassed: score >= 60
                )
            )
        }
        try context.save()
    }

    // MARK: - AC1: Concept named in plain language

    func testConceptName_isPlainLanguage() {
        let vm = PhaseCompletionViewModel(phaseId: 1)
        XCTAssertEqual(vm.completedPhaseConfig.concept, "Inflation",
                       "Phase 1 concept must be 'Inflation'")
        XCTAssertFalse(vm.completedPhaseConfig.concept.isEmpty)
    }

    func testConceptName_allPhasesHaveConcept() {
        for phaseId in 1...7 {
            let vm = PhaseCompletionViewModel(phaseId: phaseId)
            XCTAssertFalse(vm.completedPhaseConfig.concept.isEmpty,
                           "Phase \(phaseId) must have a non-empty concept name")
        }
    }

    // MARK: - AC2: Performance dashboard

    func testPerformanceDashboard_hasDataPointsPerStage() {
        let container = try! TestDataFactory.makeContainer()
        let context = ModelContext(container)
        try! seedStageCompletions(phase: 1, scores: [80, 80, 80, 80, 80], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 1)
        vm.loadPerformance(modelContext: context)
        XCTAssertEqual(vm.performanceData.count, 5,
                       "Performance dashboard must have one data point per stage")
    }

    func testPerformanceDashboard_optimalIsAlways100() {
        let container = try! TestDataFactory.makeContainer()
        let context = ModelContext(container)
        try! seedStageCompletions(phase: 1, scores: [60, 60, 60, 60, 60], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 1)
        vm.loadPerformance(modelContext: context)
        for point in vm.performanceData {
            XCTAssertEqual(point.optimalScore, 100,
                           "Optimal score must always be 100")
        }
    }

    func testPerformanceDashboard_playerScoreReflectsResults() {
        let container = try! TestDataFactory.makeContainer()
        let context = ModelContext(container)
        try! seedStageCompletions(phase: 1, scores: [72, 72, 72], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 1)
        vm.loadPerformance(modelContext: context)
        for point in vm.performanceData {
            XCTAssertEqual(point.playerScore, 72)
        }
    }

    func testAverageScore_calculatedCorrectly() {
        let container = try! TestDataFactory.makeContainer()
        let context = ModelContext(container)
        try! seedStageCompletions(phase: 1, scores: [60, 80, 100], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 1)
        vm.loadPerformance(modelContext: context)
        XCTAssertEqual(vm.averageScore, 80, "Average of 60+80+100 = 80")
    }

    // MARK: - AC3: Badge awarded and persisted

    func testBadge_awardedOnPhaseCompletion() {
        let vm = PhaseCompletionViewModel(phaseId: 1)
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
        let (_, context, _) = try TestDataFactory.makeService()
        try seedStageCompletions(phase: 1, scores: [70, 80, 90, 85, 75], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 1)
        vm.loadPerformance(modelContext: context)
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
        let vm = PhaseCompletionViewModel(phaseId: 1)
        XCTAssertNotNil(vm.nextPhaseConfig, "Next phase config must be available after Phase 1")
        XCTAssertEqual(vm.nextPhaseConfig?.id, 2)
        XCTAssertFalse(vm.nextPhaseConfig?.teaserDescription.isEmpty ?? true)
    }

    func testNextPhase_noTeaserAfterPhase7() {
        let vm = PhaseCompletionViewModel(phaseId: 7)
        XCTAssertNil(vm.nextPhaseConfig, "No next phase after Phase 7")
    }

    func testNextPhase_progressServiceUnlocksNextPhase() throws {
        let (_, _, service) = try TestDataFactory.makeService()

        for stage in 1...StageCatalog.stageCount(forPhase: 1) {
            service.completeStage(
                address: StageAddress(phase: 1, stage: stage),
                outcome: TestDataFactory.makeOutcome(score: 80)
            )
        }
        XCTAssertTrue(service.isPhaseUnlocked(2),
                      "Phase 2 must be unlocked after completing all Phase 1 stages")
    }

    // MARK: - AC5: Phase completion data persisted for Phase 7 retrieval

    func testPersistence_completionDataRetrievableAfterSave() throws {
        let (_, context, _) = try TestDataFactory.makeService()
        try seedStageCompletions(phase: 2, scores: [90, 85], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 2)
        vm.loadPerformance(modelContext: context)
        vm.persistCompletion(modelContext: context)

        let descriptor = FetchDescriptor<PhaseCompletionRecord>()
        let records = try context.fetch(descriptor)
        XCTAssertEqual(records[0].phaseId, 2)
        XCTAssertEqual(records[0].conceptName, "Valuation")
        XCTAssertFalse(records[0].decisionSummaryJSON.isEmpty,
                       "Decision summary JSON must be populated for Phase 7 retrieval")
    }

    func testPersistence_decisionSummaryContainsStageData() throws {
        let (_, context, _) = try TestDataFactory.makeService()
        try seedStageCompletions(phase: 3, scores: [65, 65, 65, 65], context: context)
        let vm = PhaseCompletionViewModel(phaseId: 3)
        vm.loadPerformance(modelContext: context)
        vm.persistCompletion(modelContext: context)

        let descriptor = FetchDescriptor<PhaseCompletionRecord>()
        let record = try context.fetch(descriptor).first!

        // JSON should encode stage data
        XCTAssertTrue(record.decisionSummaryJSON.contains("stage"),
                      "Decision summary must reference stage data")
    }
}
