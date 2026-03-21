import XCTest
@testable import InvestQuest

final class Phase7Tests: XCTestCase {

    let engine = MarketSimulationEngine()

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

    // MARK: - AC1: Stage 1 — time-pressure / timed decision

    func testStage1_timedDecision() {
        let stage = Phase7StageDefinitions.stage1
        guard case .timed(let underlying, let timeout) = stage.decisionType else {
            XCTFail("Stage 1 must use timed decision type"); return
        }
        XCTAssertGreaterThan(timeout, 0, "Timed decision must have a positive timeout")
        // Underlying must be binary
        guard case .binary = underlying else {
            XCTFail("Underlying decision in Stage 1 must be binary"); return
        }
    }

    func testStage1_timeoutIsShort() {
        let stage = Phase7StageDefinitions.stage1
        guard case .timed(_, let timeout) = stage.decisionType else {
            XCTFail("Stage 1 must use timed decision type"); return
        }
        XCTAssertLessThanOrEqual(timeout, 10,
                                  "Stage 1 timer must be ≤10 seconds to create genuine pressure")
    }

    func testStage1_optimalDecision_isWaitAndResearch() {
        let stage = Phase7StageDefinitions.stage1
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 1 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is Wait and Research (B), not the rushed buy")
    }

    func testStage1_timeoutSecondsField_matchesTimedDecision() {
        let stage = Phase7StageDefinitions.stage1
        XCTAssertGreaterThan(stage.timeoutSeconds, 0,
                              "Stage 1 timeoutSeconds field must be > 0")
        XCTAssertLessThanOrEqual(stage.timeoutSeconds, 10,
                                  "Stage 1 timeoutSeconds must be ≤10 for genuine pressure")
    }

    func testStage1_descriptionMentionsUrgencyOrPressure() {
        let desc = Phase7StageDefinitions.stage1.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("limit") || desc.contains("urgent") || desc.contains("now") ||
            desc.contains("countdown") || desc.contains("seconds"),
            "Stage 1 description must convey time pressure"
        )
    }

    func testStage1_hotAssetCrashesAfterHype() {
        let stage = Phase7StageDefinitions.stage1
        // Asset A (buy-now) should have a negative event
        let crashEvent = stage.simulation.events.first(where: {
            eventTargets($0, assetID: "A") && eventMagnitude($0) < 0.80
        })
        XCTAssertNotNil(crashEvent, "Stage 1 must have a crash event on the 'Buy Now' asset (A)")
    }

    // MARK: - AC2: Stage 2 — FOMO leaderboard, hot tip is a trap

    func testStage2_binaryDecision_cryptoVsIndexFund() {
        let stage = Phase7StageDefinitions.stage2
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 2 must use binary decision type"); return
        }
        XCTAssertFalse(a.isEmpty, "Option A must not be empty")
        XCTAssertFalse(b.isEmpty, "Option B must not be empty")
        // One option should reference the leaderboard/hot asset, the other stable/index
        let combined = "\(a) \(b)".lowercased()
        XCTAssertTrue(
            combined.contains("index") || combined.contains("boring") || combined.contains("fund"),
            "Stage 2 must include a stable index fund option"
        )
    }

    func testStage2_optimalDecision_isIndexFund() {
        let stage = Phase7StageDefinitions.stage2
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 2 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is the stable Index Fund (B), not the leaderboard trap")
    }

    func testStage2_leaderboardAssetSpikesThenCollapses() {
        let stage = Phase7StageDefinitions.stage2
        // Must have a spike event followed by a collapse on the hot asset (fomo)
        let spikeEvent = stage.simulation.events.first(where: {
            eventTargets($0, assetID: "fomo") && eventMagnitude($0) >= 2.0
        })
        let collapseEvent = stage.simulation.events.first(where: {
            eventTargets($0, assetID: "fomo") && eventMagnitude($0) <= 0.20
        })
        XCTAssertNotNil(spikeEvent, "Stage 2 hot asset must spike (magnitude ≥ 2.0)")
        XCTAssertNotNil(collapseEvent, "Stage 2 hot asset must collapse (magnitude ≤ 0.20)")
    }

    func testStage2_descriptionMentionsFOMOOrLeaderboard() {
        let desc = Phase7StageDefinitions.stage2.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("leaderboard") || desc.contains("fomo") || desc.contains("missing out") ||
            desc.contains("everyone"),
            "Stage 2 description must evoke FOMO or leaderboard dynamics"
        )
    }

    func testStage2_simulationShowsLeaderboardAssetCollapses() {
        let stage = Phase7StageDefinitions.stage2
        let result = engine.simulate(stage: stage.simulation)
        let hotAsset = result.assetHistories[0]
        let finalPrice = hotAsset.prices.last!
        let startPrice = hotAsset.prices.first!
        // Hot asset should end below start price after collapse
        XCTAssertLessThan(finalPrice, startPrice,
                          "Stage 2 hot leaderboard asset must end below its starting price")
    }

    // MARK: - AC3: Stage 3 — anchoring bias

    func testStage3_binaryDecision_anchoredBuyVsPass() {
        let stage = Phase7StageDefinitions.stage3
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 3 must use binary decision type"); return
        }
        let combined = "\(a) \(b)".lowercased()
        XCTAssertTrue(
            combined.contains("buy") || combined.contains("anchor"),
            "Stage 3 must have a buy/anchored option"
        )
        XCTAssertTrue(
            combined.contains("pass") || combined.contains("intrinsic") || combined.contains("value"),
            "Stage 3 must have a pass/value option"
        )
    }

    func testStage3_optimalDecision_isPass() {
        let stage = Phase7StageDefinitions.stage3
        guard case .valuation(_, let actionID) = stage.optimalDecision else {
            XCTFail("Stage 3 optimal decision must be valuation"); return
        }
        XCTAssertEqual(actionID, "pass", "Optimal is Pass — asset is still massively overvalued vs intrinsic value")
    }

    func testStage3_descriptionMentionsAnchorPrice() {
        let desc = Phase7StageDefinitions.stage3.scenarioDescription
        // Should mention a high historical price and a lower current price
        XCTAssertTrue(
            desc.contains("₩") || desc.contains("500") || desc.contains("200"),
            "Stage 3 description must anchor user to a historical high price"
        )
    }

    func testStage3_descriptionMentionsIntrinsicValue() {
        let desc = Phase7StageDefinitions.stage3.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("intrinsic") || desc.contains("value") || desc.contains("profit"),
            "Stage 3 description must provide fundamental/intrinsic value data"
        )
    }

    func testStage3_hasFurtherDeclineEvent() {
        let stage = Phase7StageDefinitions.stage3
        let declineEvent = stage.simulation.events.first(where: {
            eventMagnitude($0) < 1.0
        })
        XCTAssertNotNil(declineEvent,
                        "Stage 3 must have a further decline event (market correcting to fundamental value)")
    }

    // MARK: - AC4: Stage 4 — personalized behavioral review using actual user data

    func testStage4_binaryDecision_reviewVsSkip() {
        let stage = Phase7StageDefinitions.stage4
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 4 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("review") || a.lowercased().contains("my"),
                      "Option A must be the 'Review My Biases' option")
        XCTAssertTrue(b.lowercased().contains("skip"),
                      "Option B must be the 'Skip Review' option")
    }

    func testStage4_optimalDecision_isReview() {
        let stage = Phase7StageDefinitions.stage4
        guard case .review(let actionID) = stage.optimalDecision else {
            XCTFail("Stage 4 optimal decision must be review"); return
        }
        XCTAssertEqual(actionID, "review", "Optimal is Review My Decisions")
    }

    func testStage4_descriptionMentionsAllFourBiases() {
        let desc = Phase7StageDefinitions.stage4.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("anchor"), "Stage 4 must mention anchoring bias")
        XCTAssertTrue(
            desc.contains("loss") || desc.contains("aversion"),
            "Stage 4 must mention loss aversion"
        )
        XCTAssertTrue(
            desc.contains("herd") || desc.contains("crowd"),
            "Stage 4 must mention herd behavior"
        )
        XCTAssertTrue(
            desc.contains("recency") || desc.contains("recent"),
            "Stage 4 must mention recency bias"
        )
    }

    func testStage4_timeoutIsZero_noTimePressure() {
        let stage = Phase7StageDefinitions.stage4
        XCTAssertEqual(stage.timeoutSeconds, 0,
                       "Stage 4 behavioral review must have no time pressure (timeoutSeconds = 0)")
    }

    // MARK: - AC5 / AC6: concept card names specific biases

    func testConceptCard_namesAnchoring() {
        let text = Phase7StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("anchor"), "Concept card must name anchoring bias")
    }

    func testConceptCard_namesLossAversion() {
        let text = Phase7StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("loss aversion") || text.contains("loss"),
                      "Concept card must name loss aversion")
    }

    func testConceptCard_namesHerdBehavior() {
        let text = Phase7StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("herd"), "Concept card must name herd behavior")
    }

    func testConceptCard_namesRecencyBias() {
        let text = Phase7StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("recency"), "Concept card must name recency bias")
    }

    func testConceptCard_mentionsRecognizingBiases() {
        let text = Phase7StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(
            text.contains("recogni") || text.contains("aware") || text.contains("override"),
            "Concept card must address recognizing / overriding biases"
        )
    }

    // MARK: - Stage count and structure

    func testAllStages_exactlyFour() {
        XCTAssertEqual(Phase7StageDefinitions.all.count, 4,
                       "Phase 7 must have exactly 4 stages")
    }

    func testAllStages_phaseAndSequence() {
        for (i, stage) in Phase7StageDefinitions.all.enumerated() {
            XCTAssertEqual(stage.phase, 7, "All stages must belong to phase 7")
            XCTAssertEqual(stage.stage, i + 1, "Stage number must match position (1-based)")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase7StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have non-empty insightText")
        }
    }

    func testAllStages_allHaveHintText() {
        for stage in Phase7StageDefinitions.all {
            XCTAssertFalse(stage.hintText.isEmpty,
                           "Stage \(stage.stage) must have non-empty hintText")
        }
    }

    func testAllStages_uniqueSeeds() {
        let seeds = Phase7StageDefinitions.all.map { $0.simulation.seed }
        XCTAssertEqual(Set(seeds).count, seeds.count, "All Phase 7 stages must use unique seeds")
    }

    // MARK: - Performance

    func testPerformance_allStagesUnder1Second() {
        let start = Date()
        for stage in Phase7StageDefinitions.all {
            _ = engine.simulate(stage: stage.simulation)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 4 Phase 7 stages must simulate in < 1 second total")
    }
}
