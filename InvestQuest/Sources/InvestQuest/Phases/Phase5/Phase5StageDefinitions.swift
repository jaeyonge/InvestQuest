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
        address: StageAddress(phase: 5, stage: 1),
        scenario: .exit(ExitScenario(
            title: "The Right Moment to Sell",
            description: """
            You hold one asset. It has been rising — but markets don't rise forever.
            A sharp event is coming that will erase most of the gains.
            Watch the price movement and decide: sell now to lock in gains,
            or hold on hoping for more upside?
            """,
            prompts: ["Cut losses early", "Let winners run", "Use rules before emotion"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Sell Now", strategy: .directAsset("core")),
                DecisionOption(id: "B", label: "Hold On", strategy: .cash)
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 501,
            assets: [
                SimAssetConfig(
                    id: "core",
                    label: "Asset",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.20,
                    lessonRole: .preferred,
                    kind: .equity
                )
            ],
            periodCount: 15,
            replayCount: 1,
            events: [
                // Big drop after peak — period 10
                SimulationEvent(period: 10, assetIDs: ["core"], kind: .multiplier(0.65))
            ],
            lessonBias: 0.25
        ),
        scoring: .portfolio,
        optimalDecision: .binary(choice: "A"),  // Sell before the drop
        insightText: "The asset peaked and then dropped 35% in a single event. Selling while ahead — even before the top — beats holding through a crash and waiting to recover.",
        hintText: "Once an asset has risen significantly, the question is no longer 'will it go higher?' but 'how much can I lose if it doesn't?'",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Portfolio of 5, disposition effect reveal (AC2)

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 5, stage: 2),
        scenario: .exit(ExitScenario(
            title: "Winners and Losers",
            description: """
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
            prompts: ["Cut losses early", "Let winners run", "Use rules before emotion"]
        )),
        decision: .ranking(
            assets: [
                DecisionAsset(id: "Asset A (Winner)", label: "Asset A (Winner)"),
                DecisionAsset(id: "Asset B (Winner)", label: "Asset B (Winner)"),
                DecisionAsset(id: "Asset C (Loser)", label: "Asset C (Loser)"),
                DecisionAsset(id: "Asset D (Loser)", label: "Asset D (Loser)"),
                DecisionAsset(id: "Asset E (Loser)", label: "Asset E (Loser)")
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 502,
            assets: [
                SimAssetConfig(
                    id: "Asset A (Winner)",
                    label: "Asset A (Winner)",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .preferred,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Asset B (Winner)",
                    label: "Asset B (Winner)",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .preferred,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Asset C (Loser)",
                    label: "Asset C (Loser)",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Asset D (Loser)",
                    label: "Asset D (Loser)",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Asset E (Loser)",
                    label: "Asset E (Loser)",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .equity
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // Winners continue rising
                SimulationEvent(period: 4, assetIDs: ["Asset A (Winner)"], kind: .multiplier(1.5)),
                SimulationEvent(period: 4, assetIDs: ["Asset B (Winner)"], kind: .multiplier(1.4)),
                // Losers continue falling
                SimulationEvent(period: 4, assetIDs: ["Asset C (Loser)"], kind: .multiplier(0.6)),
                SimulationEvent(period: 4, assetIDs: ["Asset D (Loser)"], kind: .multiplier(0.7)),
                SimulationEvent(period: 4, assetIDs: ["Asset E (Loser)"], kind: .multiplier(0.8))
            ],
            lessonBias: 0.20
        ),
        scoring: .rankingDistance,
        optimalDecision: .ranking([
            "Asset C (Loser)",
            "Asset D (Loser)",
            "Asset E (Loser)",
            "Asset A (Winner)",
            "Asset B (Winner)"
        ]),  // Sell losers first — cut losses, let winners run
        insightText: "Most people instinctively sell winners and hold losers — this is the disposition effect. Rational exit discipline is the opposite: cut your losers early, let your winners run.",
        hintText: "Which assets show no sign of recovery? Holding a loser hoping to 'get back to even' is a trap.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Stop-loss mechanic (AC3)

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 5, stage: 3),
        scenario: .exit(ExitScenario(
            title: "The Stop-Loss Shield",
            description: """
            You are comparing two identical investments — only one has a stop-loss rule.
            A catastrophic event strikes at period 6.

            • With Stop-Loss (−15% trigger): Position automatically exits when down 15%
            • Without Stop-Loss: Position remains open through any loss

            Which approach do you take before the simulation runs?
            """,
            prompts: ["Cut losses early", "Let winners run", "Use rules before emotion"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Set Stop-Loss", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "No Stop-Loss", strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 503,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "With Stop-Loss",
                    startingValue: 100.0,
                    drift: 0.03,
                    volatility: 0.25,
                    lessonRole: .preferred,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "B",
                    label: "No Stop-Loss",
                    startingValue: 100.0,
                    drift: 0.03,
                    volatility: 0.25,
                    lessonRole: .penalized,
                    kind: .equity
                )
            ],
            periodCount: 12,
            replayCount: 1,
            events: [
                // Stop-loss asset: limited loss — stop-loss triggers, exits at -15%
                SimulationEvent(period: 6, assetIDs: ["A"], kind: .multiplier(0.85)),
                // No stop-loss asset: catastrophic fall — down ~70% in one event
                SimulationEvent(period: 6, assetIDs: ["B"], kind: .multiplier(0.30))
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "A"),  // Set the stop-loss
        insightText: "Without a stop-loss, a single catastrophic event wiped out 70% of the position. The stop-loss exited at -15% — painful, but survivable. Pre-set rules remove emotion from the exit decision.",
        hintText: "A stop-loss is a pre-commitment to cut losses at a defined level. It removes the temptation to hold through a crash.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: -40% drop with possible recovery (AC4)

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 5, stage: 4),
        scenario: .exit(ExitScenario(
            title: "The -40% Dilemma",
            description: """
            Your position has dropped -40%. There are mixed signals about recovery.
            A partial rebound appeared — but is it a real recovery or a dead cat bounce?

            The money you originally invested is gone from the current price.
            The question is not where the price was — it's where it's going.

            Do you sell and accept the loss, or hold hoping for full recovery?
            """,
            prompts: ["Cut losses early", "Let winners run", "Use rules before emotion"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Sell Now (Accept Loss)", strategy: .cash),
                DecisionOption(id: "B", label: "Hold for Recovery", strategy: .directAsset("core"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 504,
            assets: [
                SimAssetConfig(
                    id: "core",
                    label: "Asset",
                    startingValue: 100.0,
                    drift: 0.04,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .equity
                )
            ],
            periodCount: 20,
            replayCount: 1,
            events: [
                // Severe drop at period 8 — -40%
                SimulationEvent(period: 8, assetIDs: nil, kind: .multiplier(0.60)),
                // Partial, ambiguous recovery — not enough to fully recover
                SimulationEvent(period: 14, assetIDs: nil, kind: .multiplier(1.20))
            ],
            lessonBias: 0.15
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "A"),  // Sell — on average, recovery doesn't fully materialize
        insightText: "The sunk cost fallacy says 'I can't sell — I'd be locking in a loss.' But the loss already happened. On average, holding through a -40% drop hoping for full recovery loses more than accepting the loss and redeploying capital.",
        hintText: "The price you paid is irrelevant to what the asset will do next. Ignore what you paid — focus only on future expected returns vs. current price.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
