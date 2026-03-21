import XCTest
@testable import InvestQuest

final class Phase5Tests: XCTestCase {

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

    // MARK: - AC1: Stage 1 — single asset with drop event after peak; optimal = sell before drop

    func testStage1_singleAssetWithDropEvent() {
        let stage = Phase5StageDefinitions.stage1
        XCTAssertEqual(stage.phase, 5)
        XCTAssertEqual(stage.stage, 1)
        XCTAssertEqual(stage.simulation.assets.count, 1, "Stage 1 has a single asset")
        XCTAssertEqual(stage.simulation.periodCount, 15)
        XCTAssertEqual(stage.simulation.seed, 501)
    }

    func testStage1_hasDropEventAfterPeak() {
        let stage = Phase5StageDefinitions.stage1
        let events = stage.simulation.events
        XCTAssertGreaterThan(events.count, 0, "Stage 1 must have at least one event injection")
        let dropEvent = events.first { eventMagnitude($0) < 1.0 }
        XCTAssertNotNil(dropEvent, "Stage 1 must have a drop event (magnitude < 1.0)")
        if let drop = dropEvent {
            XCTAssertLessThan(eventMagnitude(drop), 0.70,
                              "Stage 1 drop event must be significant (factor < 0.70)")
            XCTAssertGreaterThan(drop.period, 5,
                                 "Drop must occur after the asset has had time to rise (period > 5)")
        }
    }

    func testStage1_optimalDecision_isSell() {
        let stage = Phase5StageDefinitions.stage1
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 1 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Sell Now — exit before the drop")
    }

    func testStage1_decisionType_isBinary() {
        let stage = Phase5StageDefinitions.stage1
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 1 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("sell") || b.lowercased().contains("sell"),
                      "Stage 1 binary options must include a sell option")
    }

    func testStage1_positiveDrift_thenDrop() {
        let stage = Phase5StageDefinitions.stage1
        XCTAssertGreaterThan(stage.simulation.assets.first?.drift ?? 0, 0,
                             "Asset must have positive drift (rises before the drop)")
        let hasDropEvent = stage.simulation.events.contains {
            eventTargets($0, assetID: "core") && eventMagnitude($0) < 1.0
        }
        XCTAssertTrue(hasDropEvent, "Core asset must have a drop event injection")
    }

    // MARK: - AC2: Stage 2 — 5 assets, mix of winners/losers, disposition effect in insightText

    func testStage2_fiveAssets() {
        let stage = Phase5StageDefinitions.stage2
        XCTAssertEqual(stage.simulation.assets.count, 5, "Stage 2 must have 5 assets")
        XCTAssertEqual(stage.simulation.seed, 502)
    }

    func testStage2_multiAssetRankingDecisionType() {
        let stage = Phase5StageDefinitions.stage2
        guard let assets = TestDataFactory.rankingAssets(from: stage) else {
            XCTFail("Stage 2 must use multiAssetRanking decision type"); return
        }
        XCTAssertEqual(assets.count, 5, "Stage 2 ranking must include all 5 assets")
    }

    func testStage2_hasWinnersAndLosers() {
        let stage = Phase5StageDefinitions.stage2
        let events = stage.simulation.events
        let winners = events.filter { eventMagnitude($0) > 1.0 }
        let losers = events.filter { eventMagnitude($0) < 1.0 }
        XCTAssertGreaterThanOrEqual(winners.count, 2, "Stage 2 must have at least 2 winner events")
        XCTAssertGreaterThanOrEqual(losers.count, 2, "Stage 2 must have at least 2 loser events")
    }

    func testStage2_optimalDecision_sellLosersFirst() {
        let stage = Phase5StageDefinitions.stage2
        guard case .ranking(let order) = stage.optimalDecision else {
            XCTFail("Stage 2 optimal decision must be ranking"); return
        }
        XCTAssertEqual(order.count, 5, "Ranking must include all 5 assets")
        // Losers should appear first in the ranking (sell first)
        let firstSold = order.first!
        XCTAssertTrue(firstSold.lowercased().contains("loser"),
                      "First asset to sell must be a loser — cut losses first")
        // Winners should appear last
        let lastSold = order.last!
        XCTAssertTrue(lastSold.lowercased().contains("winner"),
                      "Last asset to sell must be a winner — let winners run")
    }

    func testStage2_insightText_mentionsDispositionEffect() {
        let stage = Phase5StageDefinitions.stage2
        let text = stage.insightText.lowercased()
        XCTAssertTrue(text.contains("disposition effect") || text.contains("disposition"),
                      "Stage 2 insight must mention the disposition effect")
    }

    func testStage2_scenarioDescription_mentionsWinnersAndLosers() {
        let stage = Phase5StageDefinitions.stage2
        let desc = stage.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("winner"), "Stage 2 description must mention winners")
        XCTAssertTrue(desc.contains("loser"), "Stage 2 description must mention losers")
    }

    // MARK: - AC3: Stage 3 — binary choice with/without stop-loss; stop-loss asset is protected

    func testStage3_binaryChoice_stopLossVsNone() {
        let stage = Phase5StageDefinitions.stage3
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 3 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("stop") || b.lowercased().contains("stop"),
                      "Stage 3 must offer a stop-loss option")
    }

    func testStage3_optimalDecision_isStopLoss() {
        let stage = Phase5StageDefinitions.stage3
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 3 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is to use the stop-loss")
    }

    func testStage3_stopLossAssetIsProtected() {
        let stage = Phase5StageDefinitions.stage3
        let events = stage.simulation.events
        // Asset A (with stop-loss) must have a smaller magnitude drop than asset B (without)
        let assetAEvent = events.first { eventTargets($0, assetID: "A") }
        let assetBEvent = events.first { eventTargets($0, assetID: "B") }
        XCTAssertNotNil(assetAEvent, "Asset A (with stop-loss) must have an event injection")
        XCTAssertNotNil(assetBEvent, "Asset B (without stop-loss) must have an event injection")
        if let a0 = assetAEvent, let a1 = assetBEvent {
            XCTAssertGreaterThan(eventMagnitude(a0), eventMagnitude(a1),
                                 "Stop-loss asset (A) must suffer less than unprotected asset (B)")
            XCTAssertLessThan(eventMagnitude(a1), 0.50,
                              "Without stop-loss, asset must experience catastrophic drop (< 50%)")
        }
    }

    func testStage3_twoAssets() {
        let stage = Phase5StageDefinitions.stage3
        XCTAssertEqual(stage.simulation.assets.count, 2)
        XCTAssertEqual(stage.simulation.seed, 503)
    }

    func testStage3_scenarioDescription_mentionsStopLoss() {
        let stage = Phase5StageDefinitions.stage3
        let desc = stage.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("stop-loss") || desc.contains("stop loss"),
                      "Stage 3 description must explain the stop-loss mechanic")
    }

    // MARK: - AC4: Stage 4 — -40% drop event, ambiguous partial recovery

    func testStage4_hasSevereDropEvent() {
        let stage = Phase5StageDefinitions.stage4
        let events = stage.simulation.events
        let severeDrops = events.filter { eventMagnitude($0) <= 0.60 }
        XCTAssertGreaterThan(severeDrops.count, 0,
                             "Stage 4 must have a severe drop event (factor ≤ 0.60, i.e., -40%)")
        if let drop = severeDrops.first {
            XCTAssertEqual(eventMagnitude(drop), 0.60, accuracy: 0.01,
                           "Stage 4 drop must be approximately -40% (factor = 0.60)")
        }
    }

    func testStage4_hasPartialRecoveryEvent() {
        let stage = Phase5StageDefinitions.stage4
        let events = stage.simulation.events
        let recoveryEvents = events.filter { eventMagnitude($0) > 1.0 }
        XCTAssertGreaterThan(recoveryEvents.count, 0,
                             "Stage 4 must have a partial recovery event (ambiguous signal)")
        if let recovery = recoveryEvents.first {
            // Recovery is partial — not enough to fully recover, so factor should be < 1.5
            XCTAssertLessThan(eventMagnitude(recovery), 1.50,
                              "Recovery must be partial/ambiguous, not a full recovery")
        }
    }

    func testStage4_optimalDecision_isSellAcceptLoss() {
        let stage = Phase5StageDefinitions.stage4
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 4 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Sell (Accept Loss) — recovery doesn't fully materialize on average")
    }

    func testStage4_singleAsset_longerHorizon() {
        let stage = Phase5StageDefinitions.stage4
        XCTAssertEqual(stage.simulation.assets.count, 1)
        XCTAssertGreaterThanOrEqual(stage.simulation.periodCount, 18,
                                    "Stage 4 must have a longer time horizon to show recovery ambiguity")
        XCTAssertEqual(stage.simulation.seed, 504)
    }

    func testStage4_scenarioDescription_mentionsLoss() {
        let stage = Phase5StageDefinitions.stage4
        let desc = stage.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("loss") || desc.contains("drop") || desc.contains("-40"),
                      "Stage 4 description must reference the loss/drop scenario")
    }

    // MARK: - AC5: conceptCardText mentions disposition effect or loss aversion

    func testConceptCard_mentionsDispositionEffect() {
        let text = Phase5StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("disposition effect") || text.contains("loss aversion"),
                      "Concept card must mention disposition effect or loss aversion")
    }

    func testConceptCard_mentionsCutLosses() {
        let text = Phase5StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("cut") && (text.contains("loss") || text.contains("losses")),
                      "Concept card must advise to cut losses")
    }

    func testConceptCard_mentionsLetWinnersRun() {
        let text = Phase5StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("winner") || text.contains("winners"),
                      "Concept card must mention letting winners run")
    }

    func testConceptCard_isNotEmpty() {
        XCTAssertFalse(Phase5StageDefinitions.conceptCardText.isEmpty)
    }

    // MARK: - Stage count: exactly 4 stages, all phase = 5

    func testAllStages_exactlyFour() {
        XCTAssertEqual(Phase5StageDefinitions.all.count, 4,
                       "Phase 5 must have exactly 4 stages")
    }

    func testAllStages_phaseAndSequence() {
        for (i, stage) in Phase5StageDefinitions.all.enumerated() {
            XCTAssertEqual(stage.phase, 5, "All stages must belong to phase 5")
            XCTAssertEqual(stage.stage, i + 1, "Stage number must match position")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase5StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have insight text")
        }
    }

    func testAllStages_allHaveHintText() {
        for stage in Phase5StageDefinitions.all {
            XCTAssertFalse(stage.hintText.isEmpty,
                           "Stage \(stage.stage) must have hint text")
        }
    }

    // MARK: - Performance: all 4 stages simulate in < 1 second

    func testPerformance_allStagesUnder1Second() {
        let engine = MarketSimulationEngine()
        let start = Date()
        for stage in Phase5StageDefinitions.all {
            _ = engine.simulate(stage: stage.simulation)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 4 Phase 5 stages must simulate in < 1 second total")
    }
}
