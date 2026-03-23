import Foundation

/// All 4 stage definitions for Phase 3: Risk and Return.
///
/// Concept: higher potential returns come with higher risk.
/// No asset offers guaranteed high returns — that promise is always a trap.
enum Phase3StageDefinitions {

    // MARK: - Post-phase concept card (AC6)

    static let conceptCardText = """
    Risk and return are inseparable. \
    Every investment that offers higher potential return carries higher risk — \
    the possibility of larger losses. Safe assets produce steady, modest returns. \
    Risky assets can deliver large gains or large losses. \
    There are no guaranteed high returns. \
    Anyone promising guaranteed high returns is either wrong or lying. \
    The skill is choosing the right level of risk for your situation, \
    not chasing the highest possible return.
    """

    // MARK: - Stage 1: Transparent probability distributions, 10x simulation replay (AC1, AC2)

    static let stage1 = StageDefinition(
        address: StageAddress(phase: 3, stage: 1),
        scenario: .risk(RiskScenario(
            title: "See the Risk",
            description: """
            Three assets. Same starting price. Very different risk profiles.

            • Safe Asset: narrow outcome range — low volatility (5%), low drift (3%)
            • Medium Asset: moderate range — medium volatility (15%), medium drift (7%)
            • Risky Asset: wide outcome range — high volatility (35%), medium drift (7%)

            The probability distributions are shown visually. \
            Safe has a tight bell curve. Risky has a wide, flat one.

            Allocate ₩10,000,000 across the three assets.
            Run the simulation 10 times to see how outcomes vary.
            """,
            distributions: ["Narrow", "Balanced", "Wide tail"]
        )),
        decision: .allocation(
            assets: [
                DecisionAsset(id: "Safe Asset", label: "Safe Asset"),
                DecisionAsset(id: "Medium Asset", label: "Medium Asset"),
                DecisionAsset(id: "Risky Asset", label: "Risky Asset")
            ],
            totalBudget: 10_000_000,
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 301,
            assets: [
                SimAssetConfig(
                    id: "Safe Asset",
                    label: "Safe Asset",
                    drift: 0.03,
                    volatility: 0.05,
                    lessonRole: .neutral,
                    kind: .bond
                ),
                SimAssetConfig(
                    id: "Medium Asset",
                    label: "Medium Asset",
                    drift: 0.07,
                    volatility: 0.15,
                    lessonRole: .neutral,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Risky Asset",
                    label: "Risky Asset",
                    drift: 0.07,
                    volatility: 0.35,
                    lessonRole: .neutral,
                    kind: .equity
                )
            ],
            periodCount: 10,
            replayCount: 10,
            events: [],
            lessonBias: 0
        ),
        scoring: .correctness,
        optimalDecision: .allocation([
            "Safe Asset": 0.34,
            "Medium Asset": 0.33,
            "Risky Asset": 0.33
        ]),
        insightText: "Safe assets have narrow outcome ranges — you rarely win big or lose big. Risky assets have wide ranges — big wins and big losses are both possible. Running 10 simulations makes the variance difference visible.",
        hintText: "Look at how wide the outcome range is for each asset. Wider = more risk.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Allocate budget across risk levels, observe smoothing (AC3)

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 3, stage: 2),
        scenario: .risk(RiskScenario(
            title: "Smooth the Ride",
            description: """
            You have ₩10,000,000 to allocate across three risk levels:

            • Safe Asset: low risk, low reward
            • Medium Asset: moderate risk, moderate reward
            • Risky Asset: high risk, high potential reward

            Observe how mixing risk levels smooths overall portfolio outcomes.
            """,
            distributions: ["Narrow", "Balanced", "Wide tail"]
        )),
        decision: .allocation(
            assets: [
                DecisionAsset(id: "Safe Asset", label: "Safe Asset"),
                DecisionAsset(id: "Medium Asset", label: "Medium Asset"),
                DecisionAsset(id: "Risky Asset", label: "Risky Asset")
            ],
            totalBudget: 10_000_000,
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 302,
            assets: [
                SimAssetConfig(
                    id: "Safe Asset",
                    label: "Safe Asset",
                    drift: 0.07,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .bond
                ),
                SimAssetConfig(
                    id: "Medium Asset",
                    label: "Medium Asset",
                    drift: 0.07,
                    volatility: 0.20,
                    lessonRole: .preferred,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "Risky Asset",
                    label: "Risky Asset",
                    drift: 0.07,
                    volatility: 0.20,
                    lessonRole: .penalized,
                    kind: .equity
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [],
            lessonBias: 0.15            // correctStrategyWeight 0.65 - 0.5
        ),
        scoring: .portfolio,
        optimalDecision: .allocation([
            "Safe Asset": 0.3,
            "Medium Asset": 0.4,
            "Risky Asset": 0.3
        ]),
        insightText: "Mixing assets with different risk levels reduces the extremes. A portfolio is smoother than any single asset within it — this is the foundation of risk management.",
        hintText: "Try spreading your allocation. Watch what happens to the total portfolio swing.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Hidden risk — infer from past performance patterns (AC4)

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 3, stage: 3),
        scenario: .risk(RiskScenario(
            title: "Hidden Danger",
            description: """
            Three funds with nearly identical past returns over 7 periods.
            Which is the safest choice?

            • Alpha Fund: steady historical performance
            • Beta Fund: steady historical performance
            • Gamma Fund: steady historical performance — but look closely at the pattern

            Past returns look identical. But one fund has hidden tail risk. \
            A rare catastrophic event can occur. Rank them from safest to riskiest.
            """,
            distributions: ["Narrow", "Balanced", "Wide tail"]
        )),
        decision: .ranking(
            assets: [
                DecisionAsset(id: "Alpha Fund", label: "Alpha Fund"),
                DecisionAsset(id: "Beta Fund", label: "Beta Fund"),
                DecisionAsset(id: "Gamma Fund", label: "Gamma Fund")
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 303,
            assets: [
                SimAssetConfig(
                    id: "Alpha Fund",
                    label: "Alpha Fund",
                    drift: 0.06,
                    volatility: 0.25,
                    lessonRole: .neutral,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "Beta Fund",
                    label: "Beta Fund",
                    drift: 0.06,
                    volatility: 0.25,
                    lessonRole: .neutral,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "Gamma Fund",
                    label: "Gamma Fund",
                    drift: 0.06,
                    volatility: 0.25,
                    lessonRole: .neutral,
                    kind: .fund
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // Gamma Fund tail risk event in period 7 — near-catastrophic loss
                SimulationEvent(period: 7, assetIDs: ["Gamma Fund"], kind: .bankruptcy(0.30))
            ],
            lessonBias: 0.15            // correctStrategyWeight 0.65 - 0.5
        ),
        scoring: .rankingDistance,
        optimalDecision: .ranking(["Alpha Fund", "Beta Fund", "Gamma Fund"]),
        insightText: "Past returns that look identical can hide very different risk profiles. Tail risk — rare but catastrophic — doesn't show up in average performance. Gamma's crash at period 7 was the signal buried in the pattern.",
        hintText: "Look at the variance in each fund's returns, not just the average.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Scam/bubble trap — "guaranteed 50% returns" (AC5)

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 3, stage: 4),
        scenario: .risk(RiskScenario(
            title: "Too Good to Be True",
            description: """
            Two investment options:

            • Guaranteed 50% Fund: promises 50% annual returns. No risk. Guaranteed.
            • Index Fund: tracks the market. Modest returns. Boring. No promises.

            The Guaranteed 50% Fund looks spectacular for the first 4 periods.
            Then something happens.

            Which do you choose?
            """,
            distributions: ["Narrow", "Balanced", "Wide tail"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Guaranteed 50% Fund", strategy: .directAsset("scam")),
                DecisionOption(id: "B", label: "Index Fund", strategy: .directAsset("index"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 304,
            assets: [
                SimAssetConfig(
                    id: "scam",
                    label: "Guaranteed 50% Fund",
                    drift: 0.05,
                    volatility: 0.02,
                    lessonRole: .penalized,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "index",
                    label: "Index Fund",
                    drift: 0.05,
                    volatility: 0.02,
                    lessonRole: .preferred,
                    kind: .fund
                )
            ],
            periodCount: 6,
            replayCount: 1,
            events: [
                // The "guaranteed" fund collapses in period 5 — near-total loss
                SimulationEvent(period: 5, assetIDs: ["scam"], kind: .bankruptcy(0.05))
            ],
            lessonBias: 0.30            // correctStrategyWeight 0.80 - 0.5
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),   // Index Fund — avoid the scam
        insightText: "No investment can guarantee 50% returns. High guaranteed returns are the signature of fraud or a bubble. The 'Guaranteed 50% Fund' lost 95% in one period. The boring index fund survived.",
        hintText: "If something sounds too good to be true, it usually is. What happens when 'guaranteed' promises fail?",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
