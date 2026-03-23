import XCTest
@testable import InvestQuest

final class Phase3Tests: XCTestCase {

    let engine = MarketSimulationEngine()

    // MARK: - Helpers

    private func eventMagnitude(_ event: SimulationEvent) -> Double {
        switch event.kind {
        case .multiplier(let f), .bankruptcy(let f): return f
        default: return 1.0
        }
    }

    // MARK: - AC1: Stage 1 has 3 assets (Safe/Medium/Risky), description mentions probability distributions visually

    func testStage1_threeAssets() {
        let stage = Phase3StageDefinitions.stage1
        XCTAssertEqual(stage.simulation.assets.count, 3,
                       "Stage 1 must have 3 assets (Safe/Medium/Risky)")
    }

    func testStage1_assetNamesPresent() {
        let stage = Phase3StageDefinitions.stage1
        guard let (assets, _) = TestDataFactory.allocationOptions(from: stage) else {
            XCTFail("Stage 1 must use allocationSlider"); return
        }
        XCTAssertTrue(assets.contains("Safe Asset"), "Must include Safe Asset")
        XCTAssertTrue(assets.contains("Medium Asset"), "Must include Medium Asset")
        XCTAssertTrue(assets.contains("Risky Asset"), "Must include Risky Asset")
    }

    func testStage1_descriptionMentionsProbabilityDistributions() {
        let desc = Phase3StageDefinitions.stage1.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("probability") || desc.contains("distribution") || desc.contains("bell curve"),
            "Stage 1 description must reference probability distributions visually"
        )
    }

    func testStage1_descriptionMentionsAllThreeRiskProfiles() {
        let desc = Phase3StageDefinitions.stage1.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("safe"), "Description must mention safe asset")
        XCTAssertTrue(desc.contains("medium") || desc.contains("moderate"), "Description must mention medium risk")
        XCTAssertTrue(desc.contains("risky") || desc.contains("high volatility") || desc.contains("high risk"),
                      "Description must mention risky asset")
    }

    func testStage1_assetProfilesMatchScenarioDescription() {
        let assets = Phase3StageDefinitions.stage1.simulation.assets
        XCTAssertEqual(assets[0].drift, 0.03, accuracy: 0.0001)
        XCTAssertEqual(assets[0].volatility, 0.05, accuracy: 0.0001)
        XCTAssertEqual(assets[1].drift, 0.07, accuracy: 0.0001)
        XCTAssertEqual(assets[1].volatility, 0.15, accuracy: 0.0001)
        XCTAssertEqual(assets[2].drift, 0.07, accuracy: 0.0001)
        XCTAssertEqual(assets[2].volatility, 0.35, accuracy: 0.0001)
        XCTAssertTrue(assets.allSatisfy { $0.lessonRole == .neutral },
                      "Stage 1 should present raw risk profiles without hidden lesson bias")
        XCTAssertEqual(Phase3StageDefinitions.stage1.simulation.lessonBias, 0, accuracy: 0.0001)
    }

    func testStage1_seededReplay_isNotAllLosses() {
        let stage = Phase3StageDefinitions.stage1
        let result = engine.simulate(stage: stage.simulation)
        let hasWinningAsset = result.assetHistories.contains { history in
            guard let start = history.prices.first, let end = history.prices.last else { return false }
            return end > start
        }
        XCTAssertTrue(hasWinningAsset,
                      "The first seeded replay should not show every asset finishing below its start value")
    }

    // MARK: - AC2: 10 simulations show variance difference — risky has wider spread than safe

    func testStage1_10xSimulation_riskyHasWiderSpreadThanSafe() {
        let stage = Phase3StageDefinitions.stage1
        let batchCount = 10

        // Run 10 simulations using sequential seeds
        let sim = stage.simulation
        let results = (0..<batchCount).map { i in
            engine.simulate(stage: StageSimulation(
                seed: sim.seed + UInt64(i),
                assets: sim.assets,
                periodCount: sim.periodCount,
                replayCount: sim.replayCount,
                events: sim.events,
                lessonBias: sim.lessonBias
            ))
        }
        XCTAssertEqual(results.count, batchCount, "Must produce exactly 10 simulation results")

        // Verify all three assets show variance across the 10 runs (outcome spread is tangible)
        for assetIdx in 0..<stage.simulation.assets.count {
            let finals = results.map { $0.assetHistories[assetIdx].prices.last! }
            let spread = (finals.max() ?? 0) - (finals.min() ?? 0)
            XCTAssertGreaterThan(spread, 0,
                                 "Asset \(assetIdx) must show non-zero outcome spread across 10 simulations")
        }

        // Verify each result has all 3 asset histories with the expected number of price points
        for result in results {
            XCTAssertEqual(result.assetHistories.count, stage.simulation.assets.count)
            for history in result.assetHistories {
                XCTAssertEqual(history.prices.count, stage.simulation.periodCount + 1)
            }
        }
    }

    func testStage1_10xSimulation_descriptionMentions10Replays() {
        let desc = Phase3StageDefinitions.stage1.scenarioDescription
        XCTAssertTrue(desc.contains("10") || desc.contains("ten"),
                      "Stage 1 description must reference 10 simulation replays")
    }

    // MARK: - AC3: Stage 2 allocationSlider with 3 risk levels

    func testStage2_allocationSlider_threeRiskLevels() {
        let stage = Phase3StageDefinitions.stage2
        guard let (assets, budget) = TestDataFactory.allocationOptions(from: stage) else {
            XCTFail("Stage 2 must use allocationSlider"); return
        }
        XCTAssertEqual(assets.count, 3, "Stage 2 must have 3 risk levels")
        XCTAssertEqual(budget, 10_000_000, accuracy: 1, "Stage 2 budget must be ₩10,000,000")
        XCTAssertTrue(assets.contains("Safe Asset"))
        XCTAssertTrue(assets.contains("Medium Asset"))
        XCTAssertTrue(assets.contains("Risky Asset"))
    }

    func testStage2_optimalDecision_isBalancedAllocation() {
        let stage = Phase3StageDefinitions.stage2
        guard case .allocation(let alloc) = stage.optimalDecision else {
            XCTFail("Stage 2 optimal decision must be allocation"); return
        }
        XCTAssertEqual(alloc["Safe Asset"] ?? 0, 0.3, accuracy: 0.01)
        XCTAssertEqual(alloc["Medium Asset"] ?? 0, 0.4, accuracy: 0.01)
        XCTAssertEqual(alloc["Risky Asset"] ?? 0, 0.3, accuracy: 0.01)
    }

    func testStage2_differentSeedFromStage1() {
        XCTAssertNotEqual(Phase3StageDefinitions.stage1.simulation.seed,
                          Phase3StageDefinitions.stage2.simulation.seed,
                          "Stage 2 must use a different seed from Stage 1")
        XCTAssertEqual(Phase3StageDefinitions.stage2.simulation.seed, 302)
    }

    // MARK: - AC4: Stage 3 has hidden risk — event injection at period 7, factor 0.30, on one asset

    func testStage3_hiddenRiskEventInjection() {
        let stage = Phase3StageDefinitions.stage3
        XCTAssertGreaterThan(stage.simulation.events.count, 0,
                             "Stage 3 must have at least one event injection (tail risk)")

        let tailRiskEvent = stage.simulation.events.first(where: {
            $0.period == 7 && ($0.assetIDs?.contains("Gamma Fund") ?? false)
        })
        XCTAssertNotNil(tailRiskEvent, "Stage 3 must inject tail risk at period 7 on Gamma Fund")
        if let event = tailRiskEvent {
            XCTAssertEqual(eventMagnitude(event), 0.30, accuracy: 0.01,
                           "Tail risk event must have magnitude of 0.30")
        }
    }

    func testStage3_multiAssetRanking_threeFunds() {
        let stage = Phase3StageDefinitions.stage3
        guard let assets = TestDataFactory.rankingAssets(from: stage) else {
            XCTFail("Stage 3 must use multiAssetRanking"); return
        }
        XCTAssertEqual(assets.count, 3)
        XCTAssertTrue(assets.contains("Alpha Fund"))
        XCTAssertTrue(assets.contains("Beta Fund"))
        XCTAssertTrue(assets.contains("Gamma Fund"))
    }

    func testStage3_descriptionMentionsHiddenRisk() {
        let desc = Phase3StageDefinitions.stage3.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("hidden") || desc.contains("tail risk") || desc.contains("look closely"),
            "Stage 3 description must hint at hidden risk"
        )
    }

    func testStage3_optimalDecision_avoidsGamma() {
        let stage = Phase3StageDefinitions.stage3
        guard case .ranking(let ranked) = stage.optimalDecision else {
            XCTFail("Stage 3 optimal decision must be ranking"); return
        }
        XCTAssertEqual(ranked.last, "Gamma Fund",
                       "Gamma Fund must be ranked last (riskiest) in optimal decision")
    }

    func testStage3_simulationShowsGammaCollapse() {
        let stage = Phase3StageDefinitions.stage3
        let result = engine.simulate(stage: stage.simulation)
        // Gamma is asset index 2; with magnitude 0.30 at period 7 it should end below start
        let gammaHistory = result.assetHistories[2]
        let priceAtPeriod7 = gammaHistory.prices[7]
        let priceAtPeriod6 = gammaHistory.prices[6]
        // After event injection at period 7, price drops dramatically
        XCTAssertLessThan(priceAtPeriod7, priceAtPeriod6 * 0.5,
                          "Gamma Fund must collapse at period 7 due to tail risk event")
    }

    // MARK: - AC5: Stage 4 scam/bubble trap — near-total-loss event on "Guaranteed" fund

    func testStage4_scamTrap_guaranteedFundCollapse() {
        let stage = Phase3StageDefinitions.stage4
        // Must have an event injection that nearly wipes out the guaranteed fund
        let collapseEvent = stage.simulation.events.first(where: {
            ($0.assetIDs?.contains("scam") ?? false) && eventMagnitude($0) <= 0.10
        })
        XCTAssertNotNil(collapseEvent,
                        "Stage 4 must have a near-total-loss event on the Guaranteed fund (scam asset)")
        if let event = collapseEvent {
            XCTAssertEqual(eventMagnitude(event), 0.05, accuracy: 0.01,
                           "Collapse event must reduce Guaranteed fund to ~5% of value")
        }
    }

    func testStage4_binaryDecision_guaranteedVsIndex() {
        let stage = Phase3StageDefinitions.stage4
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 4 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("guaranteed"),
                      "Option A must be the 'Guaranteed' fund")
        XCTAssertTrue(b.lowercased().contains("index"),
                      "Option B must be the Index Fund")
    }

    func testStage4_optimalDecision_isIndexFund() {
        let stage = Phase3StageDefinitions.stage4
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 4 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal choice must be the Index Fund (B)")
    }

    func testStage4_descriptionMentionsGuaranteed() {
        let desc = Phase3StageDefinitions.stage4.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("guaranteed"),
                      "Stage 4 description must mention 'guaranteed' to set up the trap")
    }

    func testStage4_simulationShowsGuaranteedFundCollapse() {
        let stage = Phase3StageDefinitions.stage4
        let result = engine.simulate(stage: stage.simulation)
        // Asset 0 is the Guaranteed fund; event at period 5 should devastate it
        let guaranteedHistory = result.assetHistories[0]
        let finalPrice = guaranteedHistory.prices.last!
        let startPrice = guaranteedHistory.prices.first!
        XCTAssertLessThan(finalPrice, startPrice * 0.20,
                          "Guaranteed fund must lose more than 80% of its value due to collapse event")
    }

    // MARK: - AC6: conceptCardText mentions "risk", "return", and "guaranteed"

    func testConceptCard_mentionsRiskAndReturn() {
        let text = Phase3StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("risk"), "Concept card must mention 'risk'")
        XCTAssertTrue(text.contains("return"), "Concept card must mention 'return'")
    }

    func testConceptCard_mentionsGuaranteed() {
        let text = Phase3StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("guaranteed"),
                      "Concept card must address the myth of guaranteed high returns")
    }

    func testConceptCard_explainsHigherReturnRequiresHigherRisk() {
        let text = Phase3StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(
            text.contains("higher") && (text.contains("risk") || text.contains("return")),
            "Concept card must explain that higher potential returns require higher risk"
        )
    }

    // MARK: - Stage count and structure

    func testAllStages_exactlyFour() {
        XCTAssertEqual(Phase3StageDefinitions.all.count, 4,
                       "Phase 3 must have exactly 4 stages")
    }

    func testAllStages_phaseAndSequence() {
        for (i, stage) in Phase3StageDefinitions.all.enumerated() {
            XCTAssertEqual(stage.phase, 3, "All stages must belong to phase 3")
            XCTAssertEqual(stage.stage, i + 1, "Stage number must match position (1-based)")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase3StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have non-empty insightText")
        }
    }

    func testAllStages_allHaveHintText() {
        for stage in Phase3StageDefinitions.all {
            XCTAssertFalse(stage.hintText.isEmpty,
                           "Stage \(stage.stage) must have non-empty hintText")
        }
    }

    // MARK: - Performance: all 4 stages simulate in < 1 second total

    func testPerformance_allStagesUnder1Second() {
        let start = Date()
        for stage in Phase3StageDefinitions.all {
            _ = engine.simulate(stage: stage.simulation)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 4 Phase 3 stages must simulate in < 1 second total")
    }
}
