import XCTest
@testable import InvestQuest

final class Phase2Tests: XCTestCase {

    // MARK: - AC1 & AC2: Business fundamentals and separate market price

    func testStage1_fruitStandFundamentalsPresent() {
        let stage = Phase2StageDefinitions.stage1
        XCTAssertTrue(stage.scenarioDescription.contains("Revenue"),
                      "Stage 1 must show revenue")
        XCTAssertTrue(stage.scenarioDescription.contains("Profit"),
                      "Stage 1 must show profit")
        XCTAssertTrue(stage.scenarioDescription.contains("Costs"),
                      "Stage 1 must show costs")
    }

    func testStage1_marketPriceSeparateFromValue() {
        let stage = Phase2StageDefinitions.stage1
        // Asking price (140M) visible in description, separate from calculated value (200M)
        XCTAssertTrue(stage.scenarioDescription.contains("140"),
                      "Market price must be displayed separately in description")
    }

    func testBusinessFundamentals_intrinsicValue_is10xProfit() {
        let biz = BusinessFundamentals(
            id: "test", businessName: "Test Co",
            revenue: 100_000_000, costs: 60_000_000, profit: 40_000_000,
            isHidden: false, hiddenFields: []
        )
        XCTAssertEqual(biz.intrinsicValueEstimate, 400_000_000, accuracy: 1,
                       "Intrinsic value must be 10× annual profit")
    }

    func testOpportunity_fruitStandIsUndervalued() {
        let opp = Phase2OpportunityFactory.fruitStand()
        XCTAssertFalse(opp.isBuyingAboveValue,
                       "Fruit stand must be undervalued (market price < intrinsic)")
        XCTAssertLessThan(opp.marketPrice, opp.fundamentals.intrinsicValueEstimate)
    }

    func testOpportunity_overpricedCafeIsOvervalued() {
        let opp = Phase2OpportunityFactory.overpriced()
        XCTAssertTrue(opp.isBuyingAboveValue,
                      "Trendy Café must be overvalued (market price > intrinsic)")
    }

    // MARK: - AC3: Scoring rewards buying below estimated value

    func testStage1_optimalDecision_isBuy() {
        let stage = Phase2StageDefinitions.stage1
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 1 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Buy — fruit stand is undervalued")
    }

    func testStage3_optimalDecision_isUndervaluedOption() {
        let stage = Phase2StageDefinitions.stage3
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 3 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is StableGrocery — undervalued due to fear")
    }

    // MARK: - AC4: Stage 3+ has sentiment indicators

    func testStage3_sentimentIndicatorPresent() {
        let stage = Phase2StageDefinitions.stage3
        XCTAssertTrue(stage.scenarioDescription.contains("Hype") ||
                      stage.scenarioDescription.contains("hype") ||
                      stage.scenarioDescription.contains("🔥"),
                      "Stage 3 must show hype sentiment indicator")
        XCTAssertTrue(stage.scenarioDescription.contains("Fear") ||
                      stage.scenarioDescription.contains("fear") ||
                      stage.scenarioDescription.contains("😨"),
                      "Stage 3 must show fear sentiment indicator")
    }

    func testSentimentIndicator_distortionMultipliers() {
        XCTAssertEqual(SentimentIndicator.hype.priceDistortionMultiplier, 2.5, accuracy: 0.01)
        XCTAssertEqual(SentimentIndicator.fear.priceDistortionMultiplier, 0.4, accuracy: 0.01)
        XCTAssertEqual(SentimentIndicator.neutral.priceDistortionMultiplier, 1.0, accuracy: 0.01)
    }

    func testStage4_sentimentPresent() {
        let stage = Phase2StageDefinitions.stage4
        XCTAssertTrue(stage.scenarioDescription.contains("Optimism") ||
                      stage.scenarioDescription.contains("📈"),
                      "Stage 4 must show sentiment")
    }

    func testStage5_sentimentImpliedInNarrative() {
        // Stage 5 mentions price fluctuations — sentiment-driven noise
        let stage = Phase2StageDefinitions.stage5
        XCTAssertTrue(stage.scenarioDescription.contains("fluctuate") ||
                      stage.scenarioDescription.contains("noise") ||
                      stage.scenarioDescription.contains("dip"))
    }

    // MARK: - AC5: Stage 4 hides some fundamentals

    func testStage4_hiddenFundamentals() {
        let stage = Phase2StageDefinitions.stage4
        XCTAssertTrue(stage.scenarioDescription.contains("HIDDEN"),
                      "Stage 4 must explicitly show [HIDDEN] fields in description")
    }

    func testHiddenInfo_fieldsAreHidden() {
        let opp = Phase2OpportunityFactory.hiddenInfo()
        XCTAssertNil(opp.fundamentals.displayCosts(),
                     "Costs must be nil when hidden")
        XCTAssertNil(opp.fundamentals.displayProfit(),
                     "Profit must be nil when hidden")
        XCTAssertNotNil(opp.fundamentals.displayRevenue(),
                        "Revenue is visible — only costs and profit are hidden")
    }

    func testStage4_optimalDecision_isPass() {
        let stage = Phase2StageDefinitions.stage4
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 4 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "B", "Optimal is Pass when fundamentals are hidden")
    }

    // MARK: - AC6: Stage 5 has time element (multi-round hold)

    func testStage5_timePeriods_multiRound() {
        let stage = Phase2StageDefinitions.stage5
        XCTAssertGreaterThanOrEqual(stage.simulationConfig.timePeriods, 8,
                                    "Stage 5 must span multiple rounds (≥8)")
    }

    func testStage5_hasMidPointDip() {
        let stage = Phase2StageDefinitions.stage5
        XCTAssertGreaterThan(stage.simulationConfig.eventInjections.count, 0,
                             "Stage 5 must inject a mid-point dip to tempt selling")
    }

    func testStage5_optimalDecision_isHold() {
        let stage = Phase2StageDefinitions.stage5
        guard case .binary(let choice) = stage.optimalDecision else {
            XCTFail("Stage 5 optimal decision must be binary"); return
        }
        XCTAssertEqual(choice, "A", "Optimal is Hold (stay the course)")
    }

    // MARK: - AC7: Concept card explains price vs. value

    func testConceptCard_explainsPriceVsValue() {
        let text = Phase2StageDefinitions.conceptCardText.lowercased()
        XCTAssertTrue(text.contains("price"), "Concept card must mention price")
        XCTAssertTrue(text.contains("value"), "Concept card must mention value")
        XCTAssertTrue(text.contains("intrinsic") || text.contains("fundamental"),
                      "Concept card must explain intrinsic/fundamental value")
    }

    // MARK: - Stage count and structure

    func testAllStages_count() {
        XCTAssertEqual(Phase2StageDefinitions.all.count, 5,
                       "Phase 2 must have exactly 5 stages")
    }

    func testAllStages_phaseAndSequence() {
        for (i, stage) in Phase2StageDefinitions.all.enumerated() {
            XCTAssertEqual(stage.phase, 2)
            XCTAssertEqual(stage.stage, i + 1)
        }
    }

    // MARK: - Performance

    func testPerformance_allStagesUnder1Second() {
        let engine = MarketSimulationEngine()
        let start = Date()
        for stage in Phase2StageDefinitions.all {
            _ = engine.simulate(config: stage.simulationConfig)
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 1.0)
    }
}
