import Foundation

/// All 4 stage definitions for Phase 7: You Are Not Rational (Behavioural Biases).
///
/// Concept: cognitive biases systematically distort investment decisions.
/// Named biases: anchoring, loss aversion, herd behavior, recency bias.
enum Phase7StageDefinitions {

    // MARK: - Post-phase concept card (AC5, AC6)

    static let conceptCardText = """
    Your brain is not wired for investing. Four biases systematically distort your decisions:

    Anchoring: You fixate on an irrelevant reference price (e.g. "it was ₩500M, so ₩200M feels cheap") \
    even when it no longer reflects current value.

    Loss Aversion: Losses feel 2–3× more painful than equivalent gains feel good. \
    This makes you hold losers too long and cut winners too early.

    Herd Behavior: You follow the crowd — buying when everyone buys, selling when everyone panics — \
    because social proof feels safer than independent analysis.

    Recency Bias: You over-weight recent events. A recent crash makes you too cautious; \
    a recent boom makes you too optimistic.

    Recognising these biases is the first step to overriding them.
    """

    // MARK: - Stage 1: Time-pressure rapid-fire decisions (AC1)

    static let stage1 = StageDefinition(
        phase: 7, stage: 1,
        scenarioTitle: "Flash Sale!",
        scenarioDescription: """
        ⚡ LIMITED TIME OFFER ⚡
        You have 5 seconds to decide.
        MegaStock is up 40% today. Everyone is buying.
        The countdown has started. ACT NOW or miss out!

        (Note: Rushed decisions under pressure are rarely optimal.)
        """,
        decisionType: .timed(
            underlying: .binary(optionA: "Buy Now!", optionB: "Wait and Research"),
            timeoutSeconds: 5
        ),
        simulationConfig: StageConfig(
            seed: 701,
            assetCount: 2,
            timePeriods: 6,
            volatility: 0.25,
            drift: 0.04,
            eventInjections: [
                // "Hot" asset crashes after the hype
                StageConfig.EventInjection(period: 3, assetIndex: 0, magnitudeFactor: 0.55),
                // "Wait" asset has steady growth
                StageConfig.EventInjection(period: 3, assetIndex: 1, magnitudeFactor: 1.05)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "wait-and-research"
            )
        ),
        optimalDecision: .binary(choice: "B"),   // Wait and Research
        timeoutSeconds: 5,
        insightText: "Time pressure induces recency bias and herd thinking. The 5-second timer made 'Buy Now' feel urgent — but the asset crashed shortly after. Research beats reaction.",
        hintText: "Urgency is a sales tactic. What do you actually know about this asset?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: FOMO leaderboard — hot tip is a trap (AC2)

    static let stage2 = StageDefinition(
        phase: 7, stage: 2,
        scenarioTitle: "The Leaderboard",
        scenarioDescription: """
        🏆 Today's Leaderboard:
        #1: CryptoMoon — up 312% this month! Others are getting rich.
        #2: TechRocket — up 180% this month! "Hot tip from insiders"
        #3: Boring Index Fund — up 0.8% this month

        Everyone around you is buying CryptoMoon. Are you missing out?
        """,
        decisionType: .binary(optionA: "Buy CryptoMoon (Top Leaderboard!)", optionB: "Boring Index Fund"),
        simulationConfig: StageConfig(
            seed: 702,
            assetCount: 2,
            timePeriods: 8,
            volatility: 0.30,
            drift: 0.05,
            eventInjections: [
                // CryptoMoon: massive spike then total collapse
                StageConfig.EventInjection(period: 3, assetIndex: 0, magnitudeFactor: 2.5),
                StageConfig.EventInjection(period: 6, assetIndex: 0, magnitudeFactor: 0.10),
                // Index Fund: steady
                StageConfig.EventInjection(period: 4, assetIndex: 1, magnitudeFactor: 1.02)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "index-fund"
            )
        ),
        optimalDecision: .binary(choice: "B"),   // Index Fund
        timeoutSeconds: 30,
        insightText: "CryptoMoon was already past its peak when it hit the leaderboard. The leaderboard shows past winners — you're always buying yesterday's news. FOMO is expensive.",
        hintText: "Leaderboards show past returns. Past returns don't predict future returns.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Anchoring bias (AC3)

    static let stage3 = StageDefinition(
        phase: 7, stage: 3,
        scenarioTitle: "The Anchored Mind",
        scenarioDescription: """
        Seoul Property Fund peaked at ₩500M per unit 2 years ago.
        After a market correction, it now trades at ₩200M.

        New analysis shows:
        • Revenue: ₩15M/year
        • Costs: ₩12M/year
        • Profit: ₩3M/year
        • Intrinsic value (10× profit): ₩30M

        "It was ₩500M — at ₩200M it must be a bargain!"
        Is it?
        """,
        decisionType: .binary(optionA: "Buy (Anchored: was ₩500M, now ₩200M!)", optionB: "Pass (₩200M is still 6× intrinsic value)"),
        simulationConfig: StageConfig(
            seed: 703,
            assetCount: 1,
            timePeriods: 8,
            volatility: 0.20,
            drift: 0.03,
            eventInjections: [
                // Further decline as market corrects to fundamental value
                StageConfig.EventInjection(period: 4, assetIndex: 0, magnitudeFactor: 0.75)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "pass-overpriced"
            )
        ),
        optimalDecision: .binary(choice: "B"),   // Pass — still massively overvalued
        timeoutSeconds: 30,
        insightText: "₩200M feels cheap vs ₩500M — but intrinsic value is only ₩30M. The ₩500M peak was never justified. Anchoring to an irrelevant past price is a cognitive trap.",
        hintText: "Ignore the historical peak. Calculate intrinsic value. Compare to current price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Personalized behavioral review (AC4, AC6)

    static let stage4 = StageDefinition(
        phase: 7, stage: 4,
        scenarioTitle: "Your Behavioral Profile",
        scenarioDescription: """
        Based on your decisions across Phases 1–6, we identified patterns:

        📌 [Anchoring Detected] — You bought assets trading above intrinsic value.
        📌 [Loss Aversion Detected] — You held losing positions longer than winners.
        📌 [Herd Behavior Detected] — Your decisions correlated with sentiment indicators.
        📌 [Recency Bias Detected] — You over-weighted recent price movements.

        This is not a failure. These are universal human patterns.
        The review overlay shows where emotions overrode logic.
        Are you ready to see your complete behavioral profile?
        """,
        decisionType: .binary(optionA: "Review My Biases", optionB: "Skip Review"),
        simulationConfig: StageConfig(
            seed: 704,
            assetCount: 1,
            timePeriods: 5,
            volatility: 0.10,
            drift: 0.05,
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.90,
                description: "review"
            )
        ),
        optimalDecision: .binary(choice: "A"),   // Review
        timeoutSeconds: 0,
        insightText: "Anchoring, loss aversion, herd behavior, recency bias — these four patterns appeared in your gameplay. Recognising them is the most valuable skill you can build as an investor.",
        hintText: "Reviewing your mistakes is how you improve.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
