import XCTest
@testable import InvestQuest

@MainActor
final class StageViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeDefinition(
        timeoutSeconds: Double = 0,
        decisionType: DecisionType = .binary(optionA: "Invest", optionB: "Hold Cash"),
        optimalDecision: PlayerDecision = .binary(choice: "A")
    ) -> StageDefinition {
        // Build a DecisionSpec from the DecisionType
        let decision: DecisionSpec
        let assets = [
            SimAssetConfig(id: "A", label: "Invest", drift: 0.07, volatility: 0.2, lessonRole: .preferred),
            SimAssetConfig(id: "B", label: "Hold Cash", drift: 0.07, volatility: 0.2, lessonRole: .penalized)
        ]

        switch decisionType {
        case .binary(let optionA, let optionB):
            decision = .binary(
                options: [
                    DecisionOption(id: "A", label: optionA, strategy: .directAsset("A")),
                    DecisionOption(id: "B", label: optionB, strategy: .directAsset("B"))
                ],
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .allocationSlider(let assetNames, let totalBudget):
            decision = .allocation(
                assets: assetNames.map { DecisionAsset(id: $0, label: $0) },
                totalBudget: totalBudget,
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .multiAssetRanking(let assetNames):
            decision = .ranking(
                assets: assetNames.map { DecisionAsset(id: $0, label: $0) },
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .timed(let underlying, let timeout):
            switch underlying {
            case .binary(let optionA, let optionB):
                decision = .binary(
                    options: [
                        DecisionOption(id: "A", label: optionA, strategy: .directAsset("A")),
                        DecisionOption(id: "B", label: optionB, strategy: .directAsset("B"))
                    ],
                    timeoutSeconds: timeout,
                    defaultDecision: .holdCash
                )
            case .allocationSlider(let assetNames, let totalBudget):
                decision = .allocation(
                    assets: assetNames.map { DecisionAsset(id: $0, label: $0) },
                    totalBudget: totalBudget,
                    timeoutSeconds: timeout,
                    defaultDecision: .holdCash
                )
            }
        }

        return StageDefinition(
            address: StageAddress(phase: 1, stage: 1),
            scenario: .inflation(InflationScenario(
                title: "Test Stage",
                description: "This is a test scenario with full description.",
                inflationRates: [0.03],
                goods: []
            )),
            decision: decision,
            simulation: StageSimulation(
                seed: 42,
                assets: assets,
                periodCount: 10,
                replayCount: 1,
                events: [],
                lessonBias: 0.15
            ),
            scoring: .correctness,
            optimalDecision: optimalDecision,
            insightText: "This is the insight text explaining the concept.",
            hintText: "Hint: consider the long-term trend.",
            conceptExplanation: "Full explanation: inflation erodes purchasing power."
        )
    }

    private func makeViewModel(timeoutSeconds: Double = 0) -> StageViewModel {
        StageViewModel(definition: makeDefinition(timeoutSeconds: timeoutSeconds))
    }

    // MARK: - AC1: Briefing screen shows scenario data

    func testInitialState_isBriefing() {
        let vm = makeViewModel()
        if case .briefing = vm.flowState { /* pass */ } else {
            XCTFail("Initial state must be .briefing")
        }
    }

    func testBriefing_scenarioDescriptionAvailable() {
        let def = makeDefinition()
        XCTAssertFalse(def.scenarioTitle.isEmpty)
        XCTAssertFalse(def.scenarioDescription.isEmpty)
        XCTAssertGreaterThan(def.scenarioDescription.count, 10)
    }

    func testAdvanceFromBriefing_transitionsToDecision() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        if case .decision = vm.flowState { /* pass */ } else {
            XCTFail("After advancing from briefing, state must be .decision")
        }
    }

    // MARK: - AC2: Decision types supported

    func testDecisionType_binarySupported() {
        let def = makeDefinition(decisionType: .binary(optionA: "Buy", optionB: "Skip"))
        if case .binary(let a, let b) = def.decisionType {
            XCTAssertEqual(a, "Buy")
            XCTAssertEqual(b, "Skip")
        } else {
            XCTFail("Binary decision type must be preserved")
        }
    }

    func testDecisionType_allocationSliderSupported() {
        let def = makeDefinition(decisionType: .allocationSlider(
            assets: ["Cash", "Stocks", "Bonds"], totalBudget: 10_000_000))
        if case .allocationSlider(let assets, let budget) = def.decisionType {
            XCTAssertEqual(assets.count, 3)
            XCTAssertEqual(budget, 10_000_000)
        } else {
            XCTFail("Allocation slider type must be preserved")
        }
    }

    func testDecisionType_multiAssetRankingSupported() {
        let def = makeDefinition(decisionType: .multiAssetRanking(
            assets: ["Tech", "Bonds", "Gold"]))
        if case .multiAssetRanking(let assets) = def.decisionType {
            XCTAssertEqual(assets.count, 3)
        } else {
            XCTFail("Ranking type must be preserved")
        }
    }

    func testDecisionType_timedSupported() {
        let def = makeDefinition(
            timeoutSeconds: 30,
            decisionType: .timed(
                underlying: .binary(optionA: "Yes", optionB: "No"),
                timeoutSeconds: 30)
        )
        if case .timed(_, let t) = def.decisionType {
            XCTAssertEqual(t, 30)
        } else {
            XCTFail("Timed type must be preserved")
        }
    }

    // MARK: - AC3: Simulation view has price/portfolio state

    func testSubmitDecision_transitionsToSimulation() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        if case .simulation = vm.flowState { /* pass */ } else {
            XCTFail("After decision submitted, state must be .simulation")
        }
    }

    func testSimulation_priceHistoriesPopulated() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        XCTAssertEqual(vm.simulationPrices.count, 2, "2 assets should produce 2 price histories")
        XCTAssertEqual(vm.simulationPrices[0].count, 11, "10 periods + t=0 = 11 data points")
    }

    func testSimulation_portfolioValuesPopulated() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        XCTAssertFalse(vm.portfolioValues.isEmpty, "Portfolio values must be populated after decision")
        XCTAssertEqual(vm.portfolioValues.count, vm.simulationPrices[0].count)
    }

    func testSimulation_advancePeriod() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        XCTAssertEqual(vm.currentPeriod, 0)
        vm.advanceSimulationPeriod()
        XCTAssertEqual(vm.currentPeriod, 1)
    }

    func testSimulation_finishTransitionsToResult() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        vm.finishSimulation()
        if case .result = vm.flowState { /* pass */ } else {
            XCTFail("After finishing simulation, state must be .result")
        }
    }

    // MARK: - AC4: Result screen

    func testResult_containsStarRating() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        vm.finishSimulation()

        guard case .result(let outcome) = vm.flowState else {
            XCTFail("Expected .result state"); return
        }
        XCTAssertGreaterThanOrEqual(outcome.starRating, 1)
        XCTAssertLessThanOrEqual(outcome.starRating, 3)
    }

    func testResult_containsPortfolioAndOptimalValues() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        vm.finishSimulation()

        guard case .result(let outcome) = vm.flowState else {
            XCTFail("Expected .result state"); return
        }
        XCTAssertGreaterThan(outcome.portfolioFinalValue, 0)
        XCTAssertGreaterThan(outcome.optimalFinalValue, 0)
    }

    func testResult_scoreRange() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        vm.finishSimulation()

        guard case .result(let outcome) = vm.flowState else {
            XCTFail("Expected .result state"); return
        }
        XCTAssertGreaterThanOrEqual(outcome.score, 0)
        XCTAssertLessThanOrEqual(outcome.score, 100)
    }

    func testStarRating_thresholds() {
        XCTAssertEqual(StageOutcome.starRating(for: 80), 3)
        XCTAssertEqual(StageOutcome.starRating(for: 100), 3)
        XCTAssertEqual(StageOutcome.starRating(for: 50), 2)
        XCTAssertEqual(StageOutcome.starRating(for: 79), 2)
        XCTAssertEqual(StageOutcome.starRating(for: 0), 1)
        XCTAssertEqual(StageOutcome.starRating(for: 49), 1)
    }

    // MARK: - AC5: Insight card

    func testInsight_shownAfterResult() {
        let vm = makeViewModel()
        vm.advanceFromBriefing()
        vm.submitDecision(.binary(choice: "A"))
        vm.finishSimulation()
        vm.advanceFromResult()

        guard case .insight = vm.flowState else {
            XCTFail("After advancing from result, state must be .insight")
            return
        }
    }

    func testInsight_textAvailable() {
        let def = makeDefinition()
        XCTAssertFalse(def.insightText.isEmpty, "Insight text must not be empty")
    }

    // MARK: - AC6: Timeout → hold cash

    func testTimeout_holdCashDefaultAfterTimeout() async {
        let vm = StageViewModel(
            definition: makeDefinition(timeoutSeconds: 0.3),
            engine: MarketSimulationEngine()
        )
        vm.advanceFromBriefing()
        // Allow for CI/simulator scheduling jitter around the async timer loop.
        for _ in 0..<20 {
            if case .simulation = vm.flowState {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        guard case .simulation = vm.flowState else {
            if case .briefing = vm.flowState {
                XCTFail("Timeout did not trigger; still in briefing")
            } else if case .decision = vm.flowState {
                XCTFail("Timeout did not trigger; still in decision")
            }
            return
        }
        // If we're in simulation, check that holdCash was the submitted decision
        XCTAssertEqual(vm.pendingDecision, .holdCash,
                       "Timeout must default to holdCash decision")
    }

    // MARK: - AC7: Failure hints

    func testHints_noHintBelow3Failures() {
        let vm = makeViewModel()
        XCTAssertNil(vm.hintForCurrentFailures, "No hint before any failures")
    }

    func testHints_hintAfter3Failures() {
        let vm = makeViewModel()
        // Simulate 3 failed attempts; replay between attempts
        for _ in 0..<3 {
            vm.advanceFromBriefing()
            vm.submitDecision(.holdCash)    // holdCash = low score → failure
            vm.finishSimulation()
            if case .result = vm.flowState { vm.advanceFromResult() }
            vm.replayStage()
        }
        XCTAssertNotNil(vm.hintForCurrentFailures,
                        "Hint must appear after 3 failures")
        XCTAssertEqual(vm.hintForCurrentFailures,
                       makeDefinition().hintText)
    }

    func testHints_fullExplanationAfter5Failures() {
        let vm = makeViewModel()
        for _ in 0..<5 {
            vm.advanceFromBriefing()
            vm.submitDecision(.holdCash)
            vm.finishSimulation()
            if case .result = vm.flowState { vm.advanceFromResult() }
            vm.replayStage()
        }
        XCTAssertEqual(vm.hintForCurrentFailures,
                       makeDefinition().conceptExplanation,
                       "Full explanation must appear after 5 failures")
    }
}
