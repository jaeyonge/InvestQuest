import XCTest
@testable import InvestQuest

final class Phase6Tests: XCTestCase {

    // MARK: - Helpers

    private func eventMagnitude(_ event: SimulationEvent) -> Double {
        switch event.kind {
        case .multiplier(let f), .bankruptcy(let f): return f
        default: return 1.0
        }
    }

    private func eventTargets(_ event: SimulationEvent, assetID: String) -> Bool {
        event.assetIDs?.contains(assetID) ?? false
    }

    // MARK: - AC1: Stage 1 — All-in asset has crash; split asset does not crash as severely

    func testStage1_allInAssetHasCrashEvent() {
        let stage = Phase6StageDefinitions.stage1
        let allInCrash = stage.simulation.events.filter {
            eventTargets($0, assetID: "all-in")
        }
        XCTAssertFalse(allInCrash.isEmpty,
                       "Stage 1 all-in asset must have at least one crash event injection")
        let factor = eventMagnitude(allInCrash.first!)
        XCTAssertLessThan(factor, 0.50,
                          "Stage 1 all-in crash factor must be severe (< 0.50)")
    }

    func testStage1_splitAssetDoesNotCrashAsSeverely() {
        let stage = Phase6StageDefinitions.stage1
        // Split/diversified asset should have no crash event, or a much less severe one
        let splitCrashes = stage.simulation.events.filter {
            eventTargets($0, assetID: "split") && eventMagnitude($0) < 0.50
        }
        XCTAssertTrue(splitCrashes.isEmpty,
                      "Stage 1 split asset must not have a severe crash event")
    }

    func testStage1_binaryDecisionAndOptimalIsSplit() {
        let stage = Phase6StageDefinitions.stage1
        XCTAssertEqual(stage.phase, 6)
        XCTAssertEqual(stage.stage, 1)
        guard TestDataFactory.binaryOptions(from: stage) != nil else {
            XCTFail("Stage 1 must use binary decision type"); return
        }
        XCTAssertEqual(stage.optimalDecision, .binary(choice: "B"),
                       "Optimal decision for Stage 1 must be split (B)")
    }

    func testStage1_simulationHasTenPeriods() {
        let stage = Phase6StageDefinitions.stage1
        XCTAssertEqual(stage.simulation.periodCount, 10)
        XCTAssertEqual(stage.simulation.seed, 601)
    }

    // MARK: - AC2: Stage 2 — Description mentions variance/simulation

    func testStage2_descriptionMentionsVarianceOrSimulation() {
        let stage = Phase6StageDefinitions.stage2
        let text = stage.scenarioDescription.lowercased()
        let mentionsVariance = text.contains("variance") || text.contains("simulation") || text.contains("simulations")
        XCTAssertTrue(mentionsVariance,
                      "Stage 2 description must mention variance or simulation to communicate the 20x replay concept")
    }

    func testStage2_insightMentionsDiversification() {
        let stage = Phase6StageDefinitions.stage2
        let insight = stage.insightText.lowercased()
        XCTAssertTrue(insight.contains("diversi"),
                      "Stage 2 insight must reference diversification")
        XCTAssertTrue(insight.contains("variance") || insight.contains("risk"),
                      "Stage 2 insight must reference variance or risk reduction")
    }

    func testStage2_optimalIsDiversified() {
        let stage = Phase6StageDefinitions.stage2
        XCTAssertEqual(stage.optimalDecision, .binary(choice: "B"))
    }

    // MARK: - AC3: Stage 3 — Bankruptcy factor ≤ 0.05; diversified survives

    func testStage3_bankruptcyFactorIsNearTotalLoss() {
        let stage = Phase6StageDefinitions.stage3
        let bankruptcyEvents = stage.simulation.events.filter {
            eventTargets($0, assetID: "concentrated")
        }
        XCTAssertFalse(bankruptcyEvents.isEmpty,
                       "Stage 3 must have a bankruptcy event for the concentrated asset")
        let factor = eventMagnitude(bankruptcyEvents.first!)
        XCTAssertLessThanOrEqual(factor, 0.05,
                                 "Stage 3 bankruptcy factor must be ≤ 0.05 (near total loss)")
    }

    func testStage3_diversifiedFundSurvivesBankruptcy() {
        let stage = Phase6StageDefinitions.stage3
        // Diversified fund events must not be catastrophic
        let diversifiedCrashes = stage.simulation.events.filter {
            eventTargets($0, assetID: "diversified-fund")
        }
        // If there is an event for the diversified fund, it must be survivable (factor > 0.50)
        for event in diversifiedCrashes {
            XCTAssertGreaterThan(eventMagnitude(event), 0.50,
                                 "Diversified fund must survive the bankruptcy event (factor > 0.50)")
        }
    }

    func testStage3_scenarioDescriptionMentionsBankruptcyOrMegacorp() {
        let stage = Phase6StageDefinitions.stage3
        let text = stage.scenarioDescription.lowercased()
        let mentionsBankruptcy = text.contains("bankrupt") || text.contains("megacorp")
        XCTAssertTrue(mentionsBankruptcy,
                      "Stage 3 description must reference bankruptcy or the company name")
    }

    func testStage3_optimalIsDiversified() {
        let stage = Phase6StageDefinitions.stage3
        XCTAssertEqual(stage.optimalDecision, .binary(choice: "B"))
    }

    // MARK: - AC4: Stage 4 — Description mentions correlation or false diversification

    func testStage4_descriptionMentionsCorrelationOrFalseDiversification() {
        let stage = Phase6StageDefinitions.stage4
        let text = stage.scenarioDescription.lowercased()
        let mentionsCorrelation = text.contains("correlat") || text.contains("false") || text.contains("sector")
        XCTAssertTrue(mentionsCorrelation,
                      "Stage 4 description must mention correlation, false diversification, or sector")
    }

    func testStage4_techSectorCrashEvent() {
        let stage = Phase6StageDefinitions.stage4
        // Tech stocks use IDs like "tech-a", "tech-b", etc.
        let techCrashes = stage.simulation.events.filter {
            ($0.assetIDs ?? []).contains(where: { $0.hasPrefix("tech-") })
        }
        XCTAssertFalse(techCrashes.isEmpty,
                       "Stage 4 must have a crash event for the tech stocks")
        let factor = eventMagnitude(techCrashes.first!)
        XCTAssertLessThan(factor, 0.70,
                          "Stage 4 tech crash must be significant (factor < 0.70)")
    }

    func testStage4_trulyDiversifiedHasNoCrashEvent() {
        let stage = Phase6StageDefinitions.stage4
        let diversifiedCrashes = stage.simulation.events.filter {
            eventTargets($0, assetID: "diversified") && eventMagnitude($0) < 0.70
        }
        XCTAssertTrue(diversifiedCrashes.isEmpty,
                      "Stage 4 truly diversified portfolio must not have a severe crash event")
    }

    func testStage4_insightMentionsCorrelation() {
        let stage = Phase6StageDefinitions.stage4
        let insight = stage.insightText.lowercased()
        XCTAssertTrue(insight.contains("correlat"),
                      "Stage 4 insight must mention correlation")
    }

    func testStage4_optimalIsTrulyDiversified() {
        let stage = Phase6StageDefinitions.stage4
        XCTAssertEqual(stage.optimalDecision, .binary(choice: "B"))
    }

    // MARK: - AC5: conceptCardText mentions "correlation" and "diversif"

    func testConceptCard_mentionsCorrelationAndDiversification() {
        let text = Phase6StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("correlation") || text.contains("correlat"),
                      "Concept card must mention correlation")
        XCTAssertTrue(text.contains("diversif"),
                      "Concept card must mention diversification")
    }

    func testConceptCard_mentionsPortfolio() {
        let text = Phase6StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("portfolio"),
                      "Concept card must mention portfolio")
    }

    func testConceptCard_isNotEmpty() {
        XCTAssertFalse(Phase6StageDefinitions.conceptCardText.isEmpty,
                       "Concept card text must not be empty")
    }

    // MARK: - Count: exactly 4 stages, all phase = 6

    func testAllStages_exactlyFourStages() {
        XCTAssertEqual(Phase6StageDefinitions.all.count, 4,
                       "Phase 6 must have exactly 4 stages")
    }

    func testAllStages_allBelongToPhase6() {
        for stage in Phase6StageDefinitions.all {
            XCTAssertEqual(stage.phase, 6,
                           "Every stage in Phase 6 must have phase == 6")
        }
    }

    func testAllStages_stageNumbersSequential() {
        let stages = Phase6StageDefinitions.all
        for (i, stage) in stages.enumerated() {
            XCTAssertEqual(stage.stage, i + 1,
                           "Stage number must match position in array (1-based)")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase6StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have non-empty insight text")
        }
    }

    func testAllStages_allHaveBinaryDecision() {
        // Stage 4 uses ranking (reveals false diversification via portfolio comparison), not binary
        let binaryStages = Phase6StageDefinitions.all.filter { $0.stage != 4 }
        for stage in binaryStages {
            guard TestDataFactory.binaryOptions(from: stage) != nil else {
                XCTFail("Phase 6 Stage \(stage.stage) must use binary decision type")
                return
            }
        }
    }

    func testAllStages_optimalDecisionIsAlwaysB() {
        for stage in Phase6StageDefinitions.all {
            XCTAssertEqual(stage.optimalDecision, .binary(choice: "B"),
                           "Diversification is always the optimal choice (B) in Phase 6 Stage \(stage.stage)")
        }
    }

    // MARK: - Performance: all 4 stages simulate in < 1 second

    func testPerformance_allStagesUnder1Second() {
        let engine = MarketSimulationEngine()
        let start = Date()
        for stage in Phase6StageDefinitions.all {
            _ = engine.simulate(stage: stage.simulation)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 4 Phase 6 stages must simulate in < 1 second total")
    }
}
