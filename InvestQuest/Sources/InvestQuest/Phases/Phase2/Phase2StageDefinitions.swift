import Foundation

/// All 5 stage definitions for Phase 2: Price vs. Value.
enum Phase2StageDefinitions {

    // MARK: - Post-phase concept card (AC7)

    static let conceptCardText = """
    Price is what you pay. Value is what you get. \
    The market price of an asset is set by supply, demand, and emotion — not by fundamentals. \
    A skilled investor estimates intrinsic value independently, then only buys when \
    the market price is below that value. When everyone is greedy, prices are above value. \
    When everyone is fearful, prices may fall below value — creating opportunities.
    """

    // MARK: - Stage 1: Fruit stand fundamentals (AC1, AC2)

    static let stage1 = StageDefinition(
        address: StageAddress(phase: 2, stage: 1),
        scenario: .valuation(ValuationScenario(
            title: "The Fruit Stand",
            description: """
            Kim's Fruit Stand generates:
            • Revenue: ₩50M/year
            • Costs: ₩30M/year
            • Profit: ₩20M/year

            The asking price is ₩140M.
            A fair value estimate is roughly 10× annual profit.

            Is the asking price a good deal?
            """,
            opportunities: [Phase2OpportunityFactory.fruitStand()]
        )),
        decision: .valuation(
            options: [
                DecisionOption(id: "buy", label: "Buy (Good Deal)", strategy: .directAsset("asset0")),
                DecisionOption(id: "pass", label: "Pass (Overpriced)", strategy: .cash)
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 201,
            assets: [
                SimAssetConfig(
                    id: "asset0",
                    label: "Kim's Fruit Stand",
                    drift: 0.05,
                    volatility: 0.10,
                    lessonRole: .preferred,
                    kind: .business
                )
            ],
            periodCount: 5,
            replayCount: 1,
            events: [],
            lessonBias: 0.20
        ),
        scoring: .valuationError(targetValue: 200_000_000),
        optimalDecision: .binary(choice: "A"),   // asking 140M, value = 200M → undervalued
        insightText: "The asking price was ₩140M but the intrinsic value (10× profit) was ₩200M. You were buying at a 30% discount. That's the core skill: price vs. value.",
        hintText: "Calculate: 10 × annual profit = estimated intrinsic value. Compare to asking price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Rank multiple businesses by value (AC1, AC2)

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 2, stage: 2),
        scenario: .valuation(ValuationScenario(
            title: "Business Ranking",
            description: """
            Rank these four businesses from best value to worst:
            • Kim's Fruit Stand: Profit ₩20M, Price ₩140M
            • Park's Bakery: Profit ₩20M, Price ₩180M
            • Classic Books: Profit ₩2M, Price ₩15M
            • Trendy Café: Profit ₩5M, Price ₩150M

            Best deal = lowest price-to-value ratio.
            """,
            opportunities: Phase2OpportunityFactory.rankingBusinesses()
        )),
        decision: .ranking(
            assets: [
                DecisionAsset(id: "Kim's Fruit Stand", label: "Kim's Fruit Stand"),
                DecisionAsset(id: "Park's Bakery", label: "Park's Bakery"),
                DecisionAsset(id: "Classic Books", label: "Classic Books"),
                DecisionAsset(id: "Trendy Café", label: "Trendy Café")
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 202,
            assets: [
                SimAssetConfig(id: "Kim's Fruit Stand", label: "Kim's Fruit Stand",
                               drift: 0.05, volatility: 0.12, lessonRole: .preferred, kind: .business),
                SimAssetConfig(id: "Park's Bakery", label: "Park's Bakery",
                               drift: 0.05, volatility: 0.12, lessonRole: .neutral, kind: .business),
                SimAssetConfig(id: "Classic Books", label: "Classic Books",
                               drift: 0.05, volatility: 0.12, lessonRole: .neutral, kind: .business),
                SimAssetConfig(id: "Trendy Café", label: "Trendy Café",
                               drift: 0.05, volatility: 0.12, lessonRole: .penalized, kind: .business)
            ],
            periodCount: 5,
            replayCount: 1,
            events: [],
            lessonBias: 0.15
        ),
        scoring: .rankingDistance,
        optimalDecision: .ranking(["Kim's Fruit Stand", "Classic Books", "Park's Bakery", "Trendy Café"]),
        insightText: "Kim's Fruit Stand (P/E 7) was the best deal; Trendy Café (P/E 30) was the worst. Same metric — price-to-earnings — ranked them all.",
        hintText: "Divide price by profit for each. Lower = better value.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Sentiment distorts price (AC3, AC4)

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 2, stage: 3),
        scenario: .valuation(ValuationScenario(
            title: "Hype vs. Fear",
            description: """
            Two businesses. Same fundamentals. Different market sentiment.

            • TechBoom Inc: Profit ₩30M, Price ₩900M — 🔥 Extreme Hype
            • StableGrocery: Profit ₩30M, Price ₩120M — 😨 Panic Selling

            Both have the same intrinsic value (₩300M). Sentiment has distorted prices.
            Which do you buy?
            """,
            opportunities: [Phase2OpportunityFactory.techBoom(), Phase2OpportunityFactory.stableGrocery()]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "TechBoom Inc", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "StableGrocery", strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 203,
            assets: [
                SimAssetConfig(id: "A", label: "TechBoom Inc",
                               drift: 0.05, volatility: 0.25, lessonRole: .penalized, kind: .sector),
                SimAssetConfig(id: "B", label: "StableGrocery",
                               drift: 0.05, volatility: 0.25, lessonRole: .preferred, kind: .business)
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                SimulationEvent(
                    id: "techboom-correction",
                    period: 4,
                    assetIDs: ["A"],
                    kind: .multiplier(0.5),
                    narrative: "Hype fades — TechBoom corrects sharply"
                ),
                SimulationEvent(
                    id: "stable-recovery",
                    period: 4,
                    assetIDs: ["B"],
                    kind: .multiplier(1.6),
                    narrative: "Fear fades — StableGrocery recovers"
                )
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),  // StableGrocery — undervalued due to fear
        insightText: "StableGrocery was trading at 40% of intrinsic value due to fear. TechBoom was at 300% due to hype. Sentiment distorts price — but value reverts.",
        hintText: "Which one is trading far below its fundamental value?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Hidden fundamentals — uncertainty (AC5)

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 2, stage: 4),
        scenario: .valuation(ValuationScenario(
            title: "Incomplete Information",
            description: """
            You're evaluating TechX Corp.
            • Revenue: ₩200M/year
            • Costs: [HIDDEN]
            • Profit: [HIDDEN]
            • Sentiment: 📈 Mild Optimism
            • Market Price: ₩300M

            You can only see revenue. Make your best estimate of fair value.
            """,
            opportunities: [Phase2OpportunityFactory.hiddenInfo()]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Buy (Looks Cheap)", strategy: .directAsset("asset0")),
                DecisionOption(id: "B", label: "Pass (Too Uncertain)", strategy: .cash)
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 204,
            assets: [
                SimAssetConfig(
                    id: "asset0",
                    label: "TechX Corp",
                    drift: 0.03,
                    volatility: 0.30,
                    lessonRole: .neutral,
                    kind: .sector
                )
            ],
            periodCount: 6,
            replayCount: 1,
            events: [],
            lessonBias: 0.10
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),  // pass when fundamentals hidden
        insightText: "When you can't see costs or profit, you can't estimate value. Passing is a valid decision — and often the wisest one when information is incomplete.",
        hintText: "If costs are unknown, profit is unknown. If profit is unknown, value is unknown.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 5: Buy and hold through fluctuations (AC6)

    static let stage5 = StageDefinition(
        address: StageAddress(phase: 2, stage: 5),
        scenario: .valuation(ValuationScenario(
            title: "Patience Pays",
            description: """
            You identified Park's Bakery as undervalued (₩180M, value ₩200M).
            You buy. Now hold through 10 years of market noise.
            The price will fluctuate — sometimes below what you paid.
            Will you hold or sell when it dips?
            """,
            opportunities: [Phase2OpportunityFactory.parkBakery()]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Hold (Stay the Course)", strategy: .directAsset("asset0")),
                DecisionOption(id: "B", label: "Sell (Cut Losses)", strategy: .cash)
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 205,
            assets: [
                SimAssetConfig(
                    id: "asset0",
                    label: "Park's Bakery",
                    drift: 0.08,
                    volatility: 0.20,
                    lessonRole: .preferred,
                    kind: .business
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [
                SimulationEvent(
                    id: "mid-dip",
                    period: 4,
                    assetIDs: ["asset0"],
                    kind: .multiplier(0.75),
                    narrative: "Mid-point dip to tempt selling"
                ),
                SimulationEvent(
                    id: "value-recovery",
                    period: 7,
                    assetIDs: ["asset0"],
                    kind: .multiplier(1.3),
                    narrative: "Recovery confirms fundamental value"
                )
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "A"),  // hold
        insightText: "Short-term price movements are noise. Long-term, value wins. Buying below intrinsic value and holding is the complete strategy.",
        hintText: "The fundamentals haven't changed. Only the price did.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4, stage5]
}
