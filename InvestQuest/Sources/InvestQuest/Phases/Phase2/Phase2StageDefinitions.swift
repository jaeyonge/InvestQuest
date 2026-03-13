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
        phase: 2, stage: 1,
        scenarioTitle: "The Fruit Stand",
        scenarioDescription: """
        Kim's Fruit Stand generates:
        • Revenue: ₩50M/year
        • Costs: ₩30M/year
        • Profit: ₩20M/year

        The asking price is ₩140M.
        A fair value estimate is roughly 10× annual profit.

        Is the asking price a good deal?
        """,
        decisionType: .binary(optionA: "Buy (Good Deal)", optionB: "Pass (Overpriced)"),
        simulationConfig: StageConfig(
            seed: 201,
            assetCount: 1,
            timePeriods: 5,
            volatility: 0.1,
            drift: 0.05,           // value investor wins by buying undervalued
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "buy-undervalued"
            )
        ),
        optimalDecision: .binary(choice: "A"),   // asking 140M, value = 200M → undervalued
        timeoutSeconds: 30,
        insightText: "The asking price was ₩140M but the intrinsic value (10× profit) was ₩200M. You were buying at a 30% discount. That's the core skill: price vs. value.",
        hintText: "Calculate: 10 × annual profit = estimated intrinsic value. Compare to asking price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Rank multiple businesses by value (AC1, AC2)

    static let stage2 = StageDefinition(
        phase: 2, stage: 2,
        scenarioTitle: "Business Ranking",
        scenarioDescription: """
        Rank these four businesses from best value to worst:
        • Kim's Fruit Stand: Profit ₩20M, Price ₩140M
        • Park's Bakery: Profit ₩20M, Price ₩180M
        • Classic Books: Profit ₩2M, Price ₩15M
        • Trendy Café: Profit ₩5M, Price ₩150M

        Best deal = lowest price-to-value ratio.
        """,
        decisionType: .multiAssetRanking(
            assets: ["Kim's Fruit Stand", "Park's Bakery", "Classic Books", "Trendy Café"]
        ),
        simulationConfig: StageConfig(
            seed: 202,
            assetCount: 4,
            timePeriods: 5,
            volatility: 0.12,
            drift: 0.05,
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.65,
                description: "rank-by-price-to-value"
            )
        ),
        optimalDecision: .ranking(["Kim's Fruit Stand", "Classic Books", "Park's Bakery", "Trendy Café"]),
        timeoutSeconds: 30,
        insightText: "Kim's Fruit Stand (P/E 7) was the best deal; Trendy Café (P/E 30) was the worst. Same metric — price-to-earnings — ranked them all.",
        hintText: "Divide price by profit for each. Lower = better value.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Sentiment distorts price (AC3, AC4)

    static let stage3 = StageDefinition(
        phase: 2, stage: 3,
        scenarioTitle: "Hype vs. Fear",
        scenarioDescription: """
        Two businesses. Same fundamentals. Different market sentiment.

        • TechBoom Inc: Profit ₩30M, Price ₩900M — 🔥 Extreme Hype
        • StableGrocery: Profit ₩30M, Price ₩120M — 😨 Panic Selling

        Both have the same intrinsic value (₩300M). Sentiment has distorted prices.
        Which do you buy?
        """,
        decisionType: .binary(optionA: "TechBoom Inc", optionB: "StableGrocery"),
        simulationConfig: StageConfig(
            seed: 203,
            assetCount: 2,
            timePeriods: 8,
            volatility: 0.25,
            drift: 0.06,
            eventInjections: [
                // TechBoom corrects downward (hype fades)
                StageConfig.EventInjection(period: 4, assetIndex: 0, magnitudeFactor: 0.5),
                // StableGrocery recovers (fear fades)
                StageConfig.EventInjection(period: 4, assetIndex: 1, magnitudeFactor: 1.6)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.75,
                description: "buy-fear-not-hype"
            )
        ),
        optimalDecision: .binary(choice: "B"),  // StableGrocery — undervalued due to fear
        timeoutSeconds: 30,
        insightText: "StableGrocery was trading at 40% of intrinsic value due to fear. TechBoom was at 300% due to hype. Sentiment distorts price — but value reverts.",
        hintText: "Which one is trading far below its fundamental value?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Hidden fundamentals — uncertainty (AC5)

    static let stage4 = StageDefinition(
        phase: 2, stage: 4,
        scenarioTitle: "Incomplete Information",
        scenarioDescription: """
        You're evaluating TechX Corp.
        • Revenue: ₩200M/year
        • Costs: [HIDDEN]
        • Profit: [HIDDEN]
        • Sentiment: 📈 Mild Optimism
        • Market Price: ₩300M

        You can only see revenue. Make your best estimate of fair value.
        """,
        decisionType: .binary(optionA: "Buy (Looks Cheap)", optionB: "Pass (Too Uncertain)"),
        simulationConfig: StageConfig(
            seed: 204,
            assetCount: 1,
            timePeriods: 6,
            volatility: 0.30,      // higher variance due to uncertainty
            drift: 0.03,
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.60,
                description: "pass-when-uncertain"
            )
        ),
        optimalDecision: .binary(choice: "B"),  // pass when fundamentals hidden
        timeoutSeconds: 30,
        insightText: "When you can't see costs or profit, you can't estimate value. Passing is a valid decision — and often the wisest one when information is incomplete.",
        hintText: "If costs are unknown, profit is unknown. If profit is unknown, value is unknown.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 5: Buy and hold through fluctuations (AC6)

    static let stage5 = StageDefinition(
        phase: 2, stage: 5,
        scenarioTitle: "Patience Pays",
        scenarioDescription: """
        You identified Park's Bakery as undervalued (₩180M, value ₩200M).
        You buy. Now hold through 10 years of market noise.
        The price will fluctuate — sometimes below what you paid.
        Will you hold or sell when it dips?
        """,
        decisionType: .binary(optionA: "Hold (Stay the Course)", optionB: "Sell (Cut Losses)"),
        simulationConfig: StageConfig(
            seed: 205,
            assetCount: 1,
            timePeriods: 10,
            volatility: 0.20,
            drift: 0.08,           // fundamentals-driven growth
            eventInjections: [
                // Mid-point dip to tempt selling
                StageConfig.EventInjection(period: 4, assetIndex: 0, magnitudeFactor: 0.75),
                // Recovery confirms value
                StageConfig.EventInjection(period: 7, assetIndex: 0, magnitudeFactor: 1.3)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.75,
                description: "hold-through-dip"
            )
        ),
        optimalDecision: .binary(choice: "A"),  // hold
        timeoutSeconds: 30,
        insightText: "Short-term price movements are noise. Long-term, value wins. Buying below intrinsic value and holding is the complete strategy.",
        hintText: "The fundamentals haven't changed. Only the price did.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4, stage5]
}
