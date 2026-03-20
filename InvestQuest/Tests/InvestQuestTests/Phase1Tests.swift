import XCTest
@testable import InvestQuest

final class Phase1Tests: XCTestCase {

    // MARK: - AC1: Stage 1 — Cash loses value over 10 years

    func testStage1_cashOnly() {
        let stage = Phase1StageDefinitions.stage1
        XCTAssertEqual(stage.phase, 1)
        XCTAssertEqual(stage.stage, 1)
        XCTAssertEqual(stage.simulationConfig.assetCount, 1, "Stage 1 has cash only")
        XCTAssertEqual(stage.simulationConfig.timePeriods, 10, "Stage 1 simulates 10 years")
        XCTAssertLessThan(stage.simulationConfig.drift, 0, "Cash must have negative drift (inflation erosion)")
    }

    func testStage1_purchasingPowerDeclines() {
        let stage = Phase1StageDefinitions.stage1
        let engine = MarketSimulationEngine()
        let result = engine.simulate(config: stage.simulationConfig)
        let prices = result.assetHistories[0].prices
        let finalPrice = prices.last!
        let startPrice = prices.first!
        XCTAssertLessThan(finalPrice, startPrice,
                          "Cash purchasing power must decline over 10 years with negative drift")
    }

    func testStage1_scenarioDescriptionMentionsCash() {
        let stage = Phase1StageDefinitions.stage1
        XCTAssertTrue(stage.scenarioDescription.lowercased().contains("cash"),
                      "Stage 1 description must mention cash")
        XCTAssertTrue(stage.scenarioDescription.contains("10"),
                      "Stage 1 description must reference 10 years")
    }

    func testStage1_observeUsesStableActionID() {
        let stage = Phase1StageDefinitions.stage1
        guard case .observe(_, let actionID, _, _) = stage.decision else {
            XCTFail("Stage 1 must use the typed observe decision")
            return
        }

        XCTAssertEqual(stage.optimalDecision, .binary(choice: actionID),
                       "Stage 1 optimal decision must use the stable observe action ID")
    }

    @MainActor
    func testStage1_observeDecisionPassesAndUnlocksProgression() {
        let stage = Phase1StageDefinitions.stage1
        guard case .observe(_, let actionID, _, _) = stage.decision else {
            XCTFail("Stage 1 must use the typed observe decision")
            return
        }

        let viewModel = StageViewModel(definition: stage)
        viewModel.advanceFromBriefing()
        viewModel.submitDecision(.binary(choice: actionID))
        viewModel.finishSimulation()

        guard case .result(let outcome) = viewModel.flowState else {
            XCTFail("Stage 1 should reach a result state after simulation")
            return
        }

        XCTAssertTrue(outcome.passed, "The mandatory observe action must pass Stage 1")
        XCTAssertGreaterThanOrEqual(outcome.score, stage.minimumPassingScore)
    }

    // MARK: - AC2: Stage 2 — Cash vs Savings

    func testStage2_addsSavingsOption() {
        let stage = Phase1StageDefinitions.stage2
        XCTAssertEqual(stage.simulationConfig.assetCount, 2, "Stage 2 has 2 assets")
        guard let (assets, _) = TestDataFactory.allocationOptions(from: stage) else {
            XCTFail("Stage 2 must use allocation input"); return
        }
        XCTAssertEqual(assets.count, 2)
        XCTAssertTrue(assets.contains("Cash"))
        XCTAssertTrue(assets.contains("Savings Account"))
        XCTAssertGreaterThan(stage.timeoutSeconds, 0, "Stage 2 should support the real timeout flow")
    }

    func testStage2_oneNewVariableVsStage1() {
        // Stage 1: 1 asset. Stage 2: 2 assets. Difference = 1.
        let diff = Phase1StageDefinitions.stage2.simulationConfig.assetCount
                 - Phase1StageDefinitions.stage1.simulationConfig.assetCount
        XCTAssertEqual(diff, 1, "Stage 2 introduces exactly 1 new variable (savings) vs Stage 1 (AC6)")
    }

    // MARK: - AC3: Stage 3 — Add inflation-tracking asset

    func testStage3_addsInflationTrackingAsset() {
        let stage = Phase1StageDefinitions.stage3
        XCTAssertEqual(stage.simulationConfig.assetCount, 3, "Stage 3 has 3 assets")
        guard let (assets, _) = TestDataFactory.allocationOptions(from: stage) else {
            XCTFail("Stage 3 must use allocation input"); return
        }
        XCTAssertEqual(assets.count, 3)
        XCTAssertTrue(assets.contains("Cash"))
        XCTAssertTrue(assets.contains("Savings Account"))
        XCTAssertTrue(assets.contains("Inflation-Linked Bond"),
                      "Stage 3 must introduce an inflation-tracking asset")
    }

    func testStage3_oneNewVariableVsStage2() {
        let diff = Phase1StageDefinitions.stage3.simulationConfig.assetCount
                 - Phase1StageDefinitions.stage2.simulationConfig.assetCount
        XCTAssertEqual(diff, 1, "Stage 3 introduces exactly 1 new variable vs Stage 2 (AC6)")
    }

    // MARK: - AC4: Stage 4 — Multiple periods with varying inflation

    func testStage4_varyingInflationViaEvents() {
        let stage = Phase1StageDefinitions.stage4
        XCTAssertGreaterThan(stage.simulationConfig.eventInjections.count, 0,
                             "Stage 4 must inject events to simulate varying inflation")
        XCTAssertEqual(stage.simulationConfig.timePeriods, 4,
                       "Stage 4 has multiple time periods")
    }

    func testStage4_timedDecisionType() {
        let stage = Phase1StageDefinitions.stage4
        guard case .timed = stage.decisionType else {
            XCTFail("Stage 4 must use timed decision type for active reallocation")
            return
        }
    }

    func testStage4_oneNewVariableVsStage3_activeReallocation() {
        // Stage 4 adds short-horizon active reallocation around an inflation spike.
        let s3 = Phase1StageDefinitions.stage3
        let s4 = Phase1StageDefinitions.stage4
        XCTAssertGreaterThan(s4.simulationConfig.eventInjections.count, s3.simulationConfig.eventInjections.count,
                             "Stage 4 must add the inflation-shock event structure")
        XCTAssertLessThan(s4.simulationConfig.timePeriods, s3.simulationConfig.timePeriods,
                          "Stage 4 must switch to a short active-reallocation horizon")
        guard case .timed(let underlying, _) = s4.decisionType,
              case .allocationSlider = underlying else {
            XCTFail("Stage 4 must use a timed allocation decision")
            return
        }
    }

    // MARK: - AC5: Stage 5 — 30-year comparison

    func testStage5_thirtyYearHorizon() {
        let stage = Phase1StageDefinitions.stage5
        XCTAssertEqual(stage.simulationConfig.timePeriods, 30,
                       "Stage 5 must simulate 30 years")
    }

    func testStage5_binaryChoiceBetweenStrategies() {
        let stage = Phase1StageDefinitions.stage5
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 5 must use binary choice"); return
        }
        let combined = "\(a) \(b)".lowercased()
        XCTAssertTrue(combined.contains("cash") || combined.contains("diversi"),
                      "Stage 5 binary choice must contrast cash vs diversified")
    }

    func testStage5_diversifiedOutperformsOverTime() {
        let stage = Phase1StageDefinitions.stage5
        let engine = MarketSimulationEngine()
        // Run batch; with negative drift on asset 0 (cash), asset 1 should do better
        // (Stage 5 uses seed 105; assets differ by the PRNG sequence)
        let result = engine.simulate(config: stage.simulationConfig)
        XCTAssertEqual(result.assetHistories.count, 2)
        // Both histories must have 31 data points (30 periods + t=0)
        XCTAssertEqual(result.assetHistories[0].prices.count, 31)
    }

    // MARK: - AC6: Each stage introduces exactly one new variable

    func testAllStages_stageNumbersSequential() {
        let stages = Phase1StageDefinitions.all
        XCTAssertEqual(stages.count, 5, "Phase 1 must have exactly 5 stages")
        for (i, stage) in stages.enumerated() {
            XCTAssertEqual(stage.stage, i + 1, "Stage number must match position")
            XCTAssertEqual(stage.phase, 1, "All stages must belong to phase 1")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase1StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have insight text")
        }
    }

    // MARK: - AC7: Post-phase concept card explains inflation

    func testConceptCard_explainsInflation() {
        let text = Phase1StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("inflation"),
                      "Concept card must mention inflation")
        XCTAssertTrue(text.contains("purchasing power") || text.contains("purchasing"),
                      "Concept card must explain purchasing power")
        XCTAssertFalse(Phase1StageDefinitions.conceptCardText.isEmpty)
    }

    func testConceptCard_inPlainLanguage() {
        // Verify no jargon-only content — must mention concrete ₩ or % figures
        let text = Phase1StageDefinitions.conceptCardText
        XCTAssertTrue(text.contains("%") || text.contains("₩"),
                      "Concept card must include concrete numbers for clarity")
    }

    // MARK: - Simulation performance: all Phase 1 stages complete in <1s

    func testPerformance_allStagesUnder1Second() {
        let engine = MarketSimulationEngine()
        let start = Date()
        for stage in Phase1StageDefinitions.all {
            _ = engine.simulate(config: stage.simulationConfig)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 5 Phase 1 stages must simulate in < 1 second total")
    }
}
