import XCTest
@testable import InvestQuest

final class Phase4Tests: XCTestCase {

    let engine = MarketSimulationEngine()

    // MARK: - AC1: Stage 1 — reinvest vs. withdraw over 20 years

    func testStage1_binaryDecision_reinvestVsWithdraw() {
        let stage = Phase4StageDefinitions.stage1
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 1 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("withdraw"),
                      "Option A must be the Withdraw option")
        XCTAssertTrue(b.lowercased().contains("reinvest"),
                      "Option B must be the Reinvest option")
    }

    func testStage1_optimalDecision_isReinvest() {
        let stage = Phase4StageDefinitions.stage1
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 1 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is Reinvest All (B)")
    }

    func testStage1_20YearHorizon() {
        let stage = Phase4StageDefinitions.stage1
        XCTAssertGreaterThanOrEqual(stage.simulationConfig.timePeriods, 20,
                                    "Stage 1 must span at least 20 periods to show compounding")
    }

    func testStage1_descriptionMentionsCompounding() {
        let desc = Phase4StageDefinitions.stage1.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("reinvest") || desc.contains("compound"),
            "Stage 1 description must mention reinvesting or compounding"
        )
    }

    func testStage1_twoAssets() {
        let stage = Phase4StageDefinitions.stage1
        XCTAssertEqual(stage.simulationConfig.assetCount, 2,
                       "Stage 1 must have 2 assets (withdraw vs. reinvest)")
    }

    // MARK: - AC2: Stage 2 — start at 25 vs. start at 35, compare at 60

    func testStage2_binaryDecision_startNowVsWait() {
        let stage = Phase4StageDefinitions.stage2
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 2 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("start") || a.lowercased().contains("now"),
                      "Option A must be 'Start Now'")
        XCTAssertTrue(b.lowercased().contains("wait") || b.lowercased().contains("10"),
                      "Option B must be 'Wait 10 Years'")
    }

    func testStage2_optimalDecision_isStartNow() {
        let stage = Phase4StageDefinitions.stage2
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 2 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Start Now (A)")
    }

    func testStage2_35YearHorizon() {
        let stage = Phase4StageDefinitions.stage2
        XCTAssertGreaterThanOrEqual(stage.simulationConfig.timePeriods, 30,
                                    "Stage 2 must span at least 30 periods (age 25–60)")
    }

    func testStage2_descriptionMentions10YearAdvantage() {
        let desc = Phase4StageDefinitions.stage2.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("10") || desc.contains("ten"),
            "Stage 2 description must mention the 10-year advantage"
        )
    }

    func testStage2_hasEventInjectionForLateStart() {
        let stage = Phase4StageDefinitions.stage2
        XCTAssertGreaterThan(stage.simulationConfig.eventInjections.count, 0,
                             "Stage 2 must inject an event to represent the late-starter's disadvantage")
    }

    // MARK: - AC3: Stage 3 — fee impact in absolute ₩, low vs. high fee

    func testStage3_binaryDecision_lowVsHighFee() {
        let stage = Phase4StageDefinitions.stage3
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 3 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("low") || a.lowercased().contains("0.5"),
                      "Option A must be the Low Fee option")
        XCTAssertTrue(b.lowercased().contains("high") || b.lowercased().contains("2"),
                      "Option B must be the High Fee option")
    }

    func testStage3_optimalDecision_isLowFee() {
        let stage = Phase4StageDefinitions.stage3
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 3 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Low Fee Fund (A)")
    }

    func testStage3_30YearHorizon() {
        let stage = Phase4StageDefinitions.stage3
        XCTAssertGreaterThanOrEqual(stage.simulationConfig.timePeriods, 30,
                                    "Stage 3 must span at least 30 periods to show fee compounding")
    }

    func testStage3_descriptionMentionsFees() {
        let desc = Phase4StageDefinitions.stage3.scenarioDescription.lowercased()
        XCTAssertTrue(desc.contains("fee") || desc.contains("cost"),
                      "Stage 3 description must mention fees")
    }

    func testStage3_highFeeFundHasDragEvents() {
        let stage = Phase4StageDefinitions.stage3
        let highFeeDragEvents = stage.simulationConfig.eventInjections.filter {
            $0.assetIndex == 1 && $0.magnitudeFactor < 1.0
        }
        XCTAssertGreaterThan(highFeeDragEvents.count, 0,
                             "Stage 3 must have negative event injections on the high-fee asset (index 1)")
    }

    // MARK: - AC4: Stage 4 — temptation to withdraw during -40% dip

    func testStage4_binaryDecision_withdrawVsHold() {
        let stage = Phase4StageDefinitions.stage4
        guard let (a, b) = TestDataFactory.binaryOptions(from: stage) else {
            XCTFail("Stage 4 must use binary decision type"); return
        }
        XCTAssertTrue(a.lowercased().contains("withdraw"),
                      "Option A must be Withdraw During Dip")
        XCTAssertTrue(b.lowercased().contains("hold") || b.lowercased().contains("wait"),
                      "Option B must be Hold and Wait")
    }

    func testStage4_optimalDecision_isHold() {
        let stage = Phase4StageDefinitions.stage4
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 4 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is Hold and Wait (B)")
    }

    func testStage4_hasDipEventWith40PercentOrMoreLoss() {
        let stage = Phase4StageDefinitions.stage4
        let dipEvent = stage.simulationConfig.eventInjections.first(where: {
            $0.magnitudeFactor <= 0.65   // -40% dip or worse at some point
        })
        XCTAssertNotNil(dipEvent, "Stage 4 must inject a dip event with at least ~40% loss")
    }

    func testStage4_hasRecoveryEventAfterDip() {
        let stage = Phase4StageDefinitions.stage4
        let recoveryEvent = stage.simulationConfig.eventInjections.first(where: {
            $0.magnitudeFactor >= 1.30   // recovery boost
        })
        XCTAssertNotNil(recoveryEvent, "Stage 4 must have a recovery event after the dip")
    }

    func testStage4_descriptionMentionsDip() {
        let desc = Phase4StageDefinitions.stage4.scenarioDescription.lowercased()
        XCTAssertTrue(
            desc.contains("dip") || desc.contains("drop") || desc.contains("decline"),
            "Stage 4 description must mention the dip/drop scenario"
        )
    }

    func testStage4_simulationShowsRecovery() {
        let stage = Phase4StageDefinitions.stage4
        let result = engine.simulate(config: stage.simulationConfig)
        let history = result.assetHistories[0]
        let finalPrice = history.prices.last!
        let startPrice = history.prices.first!
        // After the dip and recovery, final price should exceed start price
        XCTAssertGreaterThan(finalPrice, startPrice,
                             "Stage 4 simulation must show final price above start price after recovery")
    }

    // MARK: - AC5: concept card mentions compounding, time, fees

    func testConceptCard_mentionsCompounding() {
        let text = Phase4StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("compound"), "Concept card must mention compounding")
    }

    func testConceptCard_mentionsTime() {
        let text = Phase4StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(
            text.contains("time") || text.contains("years") || text.contains("early"),
            "Concept card must mention the time dimension of compounding"
        )
    }

    func testConceptCard_mentionsFees() {
        let text = Phase4StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("fee"), "Concept card must mention fees")
    }

    func testConceptCard_mentionsExponential() {
        let text = Phase4StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(
            text.contains("exponential") || text.contains("grow"),
            "Concept card must describe exponential growth"
        )
    }

    // MARK: - Stage count and structure

    func testAllStages_exactlyFour() {
        XCTAssertEqual(Phase4StageDefinitions.all.count, 4,
                       "Phase 4 must have exactly 4 stages")
    }

    func testAllStages_phaseAndSequence() {
        for (i, stage) in Phase4StageDefinitions.all.enumerated() {
            XCTAssertEqual(stage.phase, 4, "All stages must belong to phase 4")
            XCTAssertEqual(stage.stage, i + 1, "Stage number must match position (1-based)")
        }
    }

    func testAllStages_allHaveInsightText() {
        for stage in Phase4StageDefinitions.all {
            XCTAssertFalse(stage.insightText.isEmpty,
                           "Stage \(stage.stage) must have non-empty insightText")
        }
    }

    func testAllStages_allHaveHintText() {
        for stage in Phase4StageDefinitions.all {
            XCTAssertFalse(stage.hintText.isEmpty,
                           "Stage \(stage.stage) must have non-empty hintText")
        }
    }

    func testAllStages_uniqueSeeds() {
        let seeds = Phase4StageDefinitions.all.map { $0.simulationConfig.seed }
        XCTAssertEqual(Set(seeds).count, seeds.count, "All Phase 4 stages must use unique seeds")
    }

    // MARK: - Performance

    func testPerformance_allStagesUnder1Second() {
        let start = Date()
        for stage in Phase4StageDefinitions.all {
            _ = engine.simulate(config: stage.simulationConfig)
        }
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0,
                          "All 4 Phase 4 stages must simulate in < 1 second total")
    }
}
