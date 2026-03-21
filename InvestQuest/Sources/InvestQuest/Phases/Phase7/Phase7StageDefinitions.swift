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
        address: StageAddress(phase: 7, stage: 1),
        scenario: .behavioral(BehavioralScenario(
            title: "Flash Sale!",
            description: """
            ⚡ LIMITED TIME OFFER ⚡
            You have 5 seconds to decide.
            MegaStock is up 40% today. Everyone is buying.
            The countdown has started. ACT NOW or miss out!

            (Note: Rushed decisions under pressure are rarely optimal.)
            """,
            biasCues: ["Urgency", "Herd Behavior", "Recency Bias"],
            isReviewStage: false
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Buy Now!", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "Wait and Research", strategy: .cash)
            ],
            timeoutSeconds: 5,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 701,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "Buy Now!",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.25,
                    lessonRole: .penalized,
                    kind: .behavioral
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Wait and Research",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.25,
                    lessonRole: .preferred,
                    kind: .behavioral
                )
            ],
            periodCount: 6,
            replayCount: 1,
            events: [
                // "Hot" asset crashes after the hype
                SimulationEvent(period: 3, assetIDs: ["A"], kind: .multiplier(0.55)),
                // "Wait" asset has steady growth
                SimulationEvent(period: 3, assetIDs: ["B"], kind: .multiplier(1.05))
            ],
            lessonBias: 0.20
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),
        insightText: "Time pressure induces recency bias and herd thinking. The 5-second timer made 'Buy Now' feel urgent — but the asset crashed shortly after. Research beats reaction.",
        hintText: "Urgency is a sales tactic. What do you actually know about this asset?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: FOMO leaderboard — hot tip is a trap (AC2)

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 7, stage: 2),
        scenario: .behavioral(BehavioralScenario(
            title: "The Leaderboard",
            description: """
            🏆 Today's Leaderboard:
            #1: CryptoMoon — up 312% this month! Others are getting rich.
            #2: TechRocket — up 180% this month! "Hot tip from insiders"
            #3: Boring Index Fund — up 0.8% this month

            Everyone around you is buying CryptoMoon. Are you missing out?
            """,
            biasCues: ["FOMO", "Herd Behavior"],
            isReviewStage: false
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Buy CryptoMoon (Top Leaderboard!)", strategy: .directAsset("fomo")),
                DecisionOption(id: "B", label: "Boring Index Fund", strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 702,
            assets: [
                SimAssetConfig(
                    id: "fomo",
                    label: "CryptoMoon",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.30,
                    lessonRole: .penalized,
                    kind: .behavioral
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Boring Index Fund",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.30,
                    lessonRole: .preferred,
                    kind: .fund
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // CryptoMoon: massive spike then total collapse
                SimulationEvent(period: 3, assetIDs: ["fomo"], kind: .multiplier(2.5)),
                SimulationEvent(period: 6, assetIDs: ["fomo"], kind: .bankruptcy(0.10)),
                // Index Fund: steady
                SimulationEvent(period: 4, assetIDs: ["B"], kind: .multiplier(1.02))
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),
        insightText: "CryptoMoon was already past its peak when it hit the leaderboard. The leaderboard shows past winners — you're always buying yesterday's news. FOMO is expensive.",
        hintText: "Leaderboards show past returns. Past returns don't predict future returns.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Anchoring bias (AC3)

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 7, stage: 3),
        scenario: .behavioral(BehavioralScenario(
            title: "The Anchored Mind",
            description: """
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
            biasCues: ["Anchoring"],
            isReviewStage: false
        )),
        decision: .valuation(
            options: [
                DecisionOption(id: "buy", label: "Buy (Anchored: was ₩500M, now ₩200M!)", strategy: .directAsset("asset0")),
                DecisionOption(id: "pass", label: "Pass (₩200M is still 6× intrinsic value)", strategy: .cash)
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 703,
            assets: [
                SimAssetConfig(
                    id: "asset0",
                    label: "Seoul Property Fund",
                    startingValue: 100.0,
                    drift: 0.03,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .fund
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // Further decline as market corrects to fundamental value
                SimulationEvent(period: 4, assetIDs: ["asset0"], kind: .multiplier(0.75))
            ],
            lessonBias: 0.20
        ),
        scoring: .valuationError(targetValue: 30_000_000),
        optimalDecision: .valuation(estimatedValue: 30_000_000, actionID: "pass"),
        insightText: "₩200M feels cheap vs ₩500M — but intrinsic value is only ₩30M. The ₩500M peak was never justified. Anchoring to an irrelevant past price is a cognitive trap.",
        hintText: "Ignore the historical peak. Calculate intrinsic value. Compare to current price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Personalized behavioral review (AC4, AC6)

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 7, stage: 4),
        scenario: .behavioral(BehavioralScenario(
            title: "Your Behavioral Profile",
            description: """
            Based on your decisions across Phases 1–6, we identified patterns:

            📌 [Anchoring Detected] — You bought assets trading above intrinsic value.
            📌 [Loss Aversion Detected] — You held losing positions longer than winners.
            📌 [Herd Behavior Detected] — Your decisions correlated with sentiment indicators.
            📌 [Recency Bias Detected] — You over-weighted recent price movements.

            This is not a failure. These are universal human patterns.
            The review overlay shows where emotions overrode logic.
            Are you ready to see your complete behavioral profile?
            """,
            biasCues: ["Anchoring", "Loss Aversion", "Herd Behavior", "Recency Bias"],
            isReviewStage: true
        )),
        decision: .review(
            options: [
                DecisionOption(id: "review", label: "Review My Decisions", strategy: .cash),
                DecisionOption(id: "skip", label: "Skip Review", strategy: .cash)
            ],
            timeoutSeconds: nil,
            defaultDecision: .review(actionID: "review")
        ),
        simulation: StageSimulation(
            seed: 704,
            assets: [
                SimAssetConfig(
                    id: "core",
                    label: "Behavioral Review",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.10,
                    lessonRole: .neutral,
                    kind: .behavioral
                )
            ],
            periodCount: 5,
            replayCount: 1,
            events: [],
            lessonBias: 0.25
        ),
        scoring: .reviewCompletion,
        optimalDecision: .review(actionID: "review"),
        insightText: "Anchoring, loss aversion, herd behavior, recency bias — these four patterns appeared in your gameplay. Recognising them is the most valuable skill you can build as an investor.",
        hintText: "Reviewing your mistakes is how you improve.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
