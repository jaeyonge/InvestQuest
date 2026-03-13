import Foundation

/// All 4 stage definitions for Phase 5: Knowing When to Exit.
///
/// Concept: cut losses early, let winners run.
/// Teaches the disposition effect, loss aversion, sunk cost fallacy, and stop-loss mechanics.
enum Phase5StageDefinitions {

    // MARK: - Post-phase concept card (AC5)

    static let conceptCardText = """
    The disposition effect is one of the most costly investment mistakes: \
    investors instinctively sell their winners and hold their losers. \
    It feels right — locking in a gain, waiting for a loser to recover — \
    but the data shows it destroys returns over time. \
    Loss aversion makes losses feel twice as painful as equivalent gains feel good. \
    This psychological bias causes us to hold losing positions far too long, \
    hoping to "get back to even." \
    The discipline: cut losses early with a pre-set exit rule, \
    and let winners run until the fundamentals change. \
    Don't let emotions override your exit strategy.
    """

    // MARK: - Stage 1: Single asset, decide when to sell (AC1)

    static let stage1 = StageDefinition(
        phase: 5, stage: 1,
        scenarioTitle: "The Right Moment to Sell",
        scenarioDescription: """
        You hold one asset. It has been rising — but markets don't rise forever.
        A sharp event is coming that will erase most of the gains.
        Watch the price movement and decide: sell now to lock in gains,
        or hold on hoping for more upside?
        """,
        decisionType: .binary(optionA: "Sell Now", optionB: "Hold On"),
        simulationConfig: StageConfig(
            seed: 501,
            assetCount: 1,
            timePeriods: 15,
            volatility: 0.20,
            drift: 0.05,
            eventInjections: [
                // Big drop after peak — period 10
                StageConfig.EventInjection(period: 10, assetIndex: 0, magnitudeFactor: 0.65)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.75,
                description: "sell-before-drop"
            )
        ),
        optimalDecision: .binary(choice: "A"),  // Sell before the drop
        timeoutSeconds: 30,
        insightText: "The asset peaked and then dropped 35% in a single event. Selling while ahead — even before the top — beats holding through a crash and waiting to recover.",
        hintText: "Once an asset has risen significantly, the question is no longer 'will it go higher?' but 'how much can I lose if it doesn't?'",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Portfolio of 5, disposition effect reveal (AC2)

    static let stage2 = StageDefinition(
        phase: 5, stage: 2,
        scenarioTitle: "Winners and Losers",
        scenarioDescription: """
        Your portfolio has 5 assets. Some have gained, some have lost.
        You need to sell two positions to raise cash.
        Rank them in the order you would sell — most urgent first.

        • Asset A (Winner): Up significantly since purchase
        • Asset B (Winner): Up moderately since purchase
        • Asset C (Loser): Down 40% since purchase
        • Asset D (Loser): Down 30% since purchase
        • Asset E (Loser): Down 20% since purchase

        Which do you sell first?
        """,
        decisionType: .multiAssetRanking(
            assets: ["Asset A (Winner)", "Asset B (Winner)", "Asset C (Loser)", "Asset D (Loser)", "Asset E (Loser)"]
        ),
        simulationConfig: StageConfig(
            seed: 502,
            assetCount: 5,
            timePeriods: 8,
            volatility: 0.20,
            drift: 0.04,
            eventInjections: [
                // Winners continue rising
                StageConfig.EventInjection(period: 4, assetIndex: 0, magnitudeFactor: 1.5),
                StageConfig.EventInjection(period: 4, assetIndex: 1, magnitudeFactor: 1.4),
                // Losers continue falling
                StageConfig.EventInjection(period: 4, assetIndex: 2, magnitudeFactor: 0.6),
                StageConfig.EventInjection(period: 4, assetIndex: 3, magnitudeFactor: 0.7),
                StageConfig.EventInjection(period: 4, assetIndex: 4, magnitudeFactor: 0.8)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "sell-losers-first"
            )
        ),
        optimalDecision: .ranking([
            "Asset C (Loser)",
            "Asset D (Loser)",
            "Asset E (Loser)",
            "Asset A (Winner)",
            "Asset B (Winner)"
        ]),  // Sell losers first — cut losses, let winners run
        timeoutSeconds: 30,
        insightText: "Most people instinctively sell winners and hold losers — this is the disposition effect. Rational exit discipline is the opposite: cut your losers early, let your winners run.",
        hintText: "Which assets show no sign of recovery? Holding a loser hoping to 'get back to even' is a trap.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Stop-loss mechanic (AC3)

    static let stage3 = StageDefinition(
        phase: 5, stage: 3,
        scenarioTitle: "The Stop-Loss Shield",
        scenarioDescription: """
        You are comparing two identical investments — only one has a stop-loss rule.
        A catastrophic event strikes at period 6.

        • With Stop-Loss (−15% trigger): Position automatically exits when down 15%
        • Without Stop-Loss: Position remains open through any loss

        Which approach do you take before the simulation runs?
        """,
        decisionType: .binary(optionA: "Set Stop-Loss at -15%", optionB: "No Stop-Loss"),
        simulationConfig: StageConfig(
            seed: 503,
            assetCount: 2,
            timePeriods: 12,
            volatility: 0.25,
            drift: 0.03,
            eventInjections: [
                // Stop-loss asset: limited loss — stop-loss triggers, exits at -15%
                StageConfig.EventInjection(period: 6, assetIndex: 0, magnitudeFactor: 0.85),
                // No stop-loss asset: catastrophic fall — down ~70% in one event
                StageConfig.EventInjection(period: 6, assetIndex: 1, magnitudeFactor: 0.30)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "use-stop-loss"
            )
        ),
        optimalDecision: .binary(choice: "A"),  // Set the stop-loss
        timeoutSeconds: 30,
        insightText: "Without a stop-loss, a single catastrophic event wiped out 70% of the position. The stop-loss exited at -15% — painful, but survivable. Pre-set rules remove emotion from the exit decision.",
        hintText: "A stop-loss is a pre-commitment to cut losses at a defined level. It removes the temptation to hold through a crash.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: -40% drop with possible recovery (AC4)

    static let stage4 = StageDefinition(
        phase: 5, stage: 4,
        scenarioTitle: "The -40% Dilemma",
        scenarioDescription: """
        Your position has dropped -40%. There are mixed signals about recovery.
        A partial rebound appeared — but is it a real recovery or a dead cat bounce?

        The money you originally invested is gone from the current price.
        The question is not where the price was — it's where it's going.

        Do you sell and accept the loss, or hold hoping for full recovery?
        """,
        decisionType: .binary(optionA: "Sell Now (Accept Loss)", optionB: "Hold for Recovery"),
        simulationConfig: StageConfig(
            seed: 504,
            assetCount: 1,
            timePeriods: 20,
            volatility: 0.20,
            drift: 0.04,
            eventInjections: [
                // Severe drop at period 8 — -40%
                StageConfig.EventInjection(period: 8, assetIndex: 0, magnitudeFactor: 0.60),
                // Partial, ambiguous recovery — not enough to fully recover
                StageConfig.EventInjection(period: 14, assetIndex: 0, magnitudeFactor: 1.20)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.65,
                description: "sell-accept-loss"
            )
        ),
        optimalDecision: .binary(choice: "A"),  // Sell — on average, recovery doesn't fully materialize
        timeoutSeconds: 30,
        insightText: "The sunk cost fallacy says 'I can't sell — I'd be locking in a loss.' But the loss already happened. On average, holding through a -40% drop hoping for full recovery loses more than accepting the loss and redeploying capital.",
        hintText: "The price you paid is irrelevant to what the asset will do next. Ignore what you paid — focus only on future expected returns vs. current price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
