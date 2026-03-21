import Foundation

/// All 5 stage definitions for Phase 1: Inflation / Cash Loses Value.
///
/// In Phase 1 the simulation price represents **purchasing power** (real value),
/// not a nominal asset price. Positive drift = preserving value; negative = erosion.
enum Phase1StageDefinitions {

    // MARK: - Post-phase concept card (AC7)

    static let conceptCardText = """
    Inflation is the gradual rise in prices over time. \
    When prices rise 3% per year, your cash loses 3% of its purchasing power — \
    even though the number in your bank account stays the same. \
    Holding only cash is not "safe". It is a guaranteed slow loss. \
    The goal is to find assets that grow at least as fast as inflation.
    """

    // MARK: - Stage 1: Observe cash losing value over 10 years (AC1)

    static let stage1 = StageDefinition(
        address: StageAddress(phase: 1, stage: 1),
        scenario: .inflation(InflationScenario(
            title: "The Vanishing 10 Million",
            description: """
            You have ₩10,000,000 in cash.
            Inflation runs at 3% per year.
            Watch what happens to your purchasing power over 10 years.
            You have no choice but to hold cash in Stage 1.
            """,
            inflationRates: [0.03],
            goods: [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
        )),
        decision: .observe(
            label: "Observe",
            actionID: "observe",
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 101,
            assets: [
                SimAssetConfig(
                    id: "core",
                    label: "Cash",
                    startingValue: 100.0,
                    drift: -0.03,
                    volatility: 0.005,
                    lessonRole: .neutral,
                    kind: .cash
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [],
            lessonBias: 0.0
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "observe"),
        insightText: "Your ₩10M lost real value every year — not because you spent it, but because inflation made everything more expensive. Holding cash is a slow loss.",
        hintText: "Watch the purchasing power line. It only goes one direction.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Allocate between Cash and Savings (AC2)
    // New variable: Savings account option

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 1, stage: 2),
        scenario: .inflation(InflationScenario(
            title: "Cash vs. Savings",
            description: """
            You have ₩10,000,000 to allocate.
            Option A: Cash (loses ~3% purchasing power per year)
            Option B: Savings account (earns ~0.5% — barely offsets inflation)
            How do you split your money?
            """,
            inflationRates: [0.03],
            goods: [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
        )),
        decision: .allocation(
            assets: [
                DecisionAsset(id: "Cash", label: "Cash"),
                DecisionAsset(id: "Savings Account", label: "Savings Account")
            ],
            totalBudget: 10_000_000,
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 102,
            assets: [
                SimAssetConfig(
                    id: "Cash",
                    label: "Cash",
                    startingValue: 100.0,
                    drift: -0.03,
                    volatility: 0.005,
                    lessonRole: .penalized,
                    kind: .cash
                ),
                SimAssetConfig(
                    id: "Savings Account",
                    label: "Savings Account",
                    startingValue: 100.0,
                    drift: -0.01,
                    volatility: 0.005,
                    lessonRole: .preferred,
                    kind: .savings
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [],
            lessonBias: 0.15
        ),
        scoring: .portfolio,
        optimalDecision: .allocation(["Cash": 0.0, "Savings Account": 1.0]),
        insightText: "The savings account barely kept up with inflation — but it was still better than pure cash. Moving money to savings is a small but real improvement.",
        hintText: "One option keeps up with inflation slightly better than the other.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Add inflation-tracking asset (AC3)
    // New variable: Inflation-tracking asset

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 1, stage: 3),
        scenario: .inflation(InflationScenario(
            title: "The Inflation Shield",
            description: """
            You have ₩10,000,000 to allocate across three options:
            • Cash: loses purchasing power every year
            • Savings Account: barely keeps up with inflation
            • Inflation-Linked Bond: designed to preserve and grow purchasing power
            How do you allocate?
            """,
            inflationRates: [0.03],
            goods: [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
        )),
        decision: .allocation(
            assets: [
                DecisionAsset(id: "Cash", label: "Cash"),
                DecisionAsset(id: "Savings Account", label: "Savings Account"),
                DecisionAsset(id: "Inflation-Linked Bond", label: "Inflation-Linked Bond")
            ],
            totalBudget: 10_000_000,
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 103,
            assets: [
                SimAssetConfig(
                    id: "Cash",
                    label: "Cash",
                    startingValue: 100.0,
                    drift: -0.03,
                    volatility: 0.005,
                    lessonRole: .penalized,
                    kind: .cash
                ),
                SimAssetConfig(
                    id: "Savings Account",
                    label: "Savings Account",
                    startingValue: 100.0,
                    drift: -0.01,
                    volatility: 0.01,
                    lessonRole: .neutral,
                    kind: .savings
                ),
                SimAssetConfig(
                    id: "Inflation-Linked Bond",
                    label: "Inflation-Linked Bond",
                    startingValue: 100.0,
                    drift: 0.02,
                    volatility: 0.01,
                    lessonRole: .preferred,
                    kind: .bond
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [],
            lessonBias: 0.20
        ),
        scoring: .portfolio,
        optimalDecision: .allocation([
            "Cash": 0.0,
            "Savings Account": 0.2,
            "Inflation-Linked Bond": 0.8
        ]),
        insightText: "The inflation-linked bond preserved and grew your purchasing power while cash kept eroding. Not all assets fight inflation equally.",
        hintText: "Which asset is designed specifically to track inflation?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Varying inflation across time periods (AC4)
    // New variable: Active reallocation across multiple periods

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 1, stage: 4),
        scenario: .inflation(InflationScenario(
            title: "Inflation Rollercoaster",
            description: """
            Inflation is not constant. Over 4 periods:
            • Period 1-2: Low inflation (1%)
            • Period 3: High inflation spike (8%)
            • Period 4: Moderate (4%)
            Reallocate between Cash, Savings, and Inflation-Linked Bond each period.
            """,
            inflationRates: [0.01, 0.01, 0.08, 0.04],
            goods: [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
        )),
        decision: .allocation(
            assets: [
                DecisionAsset(id: "Cash", label: "Cash"),
                DecisionAsset(id: "Savings Account", label: "Savings Account"),
                DecisionAsset(id: "Inflation-Linked Bond", label: "Inflation-Linked Bond")
            ],
            totalBudget: 10_000_000,
            timeoutSeconds: 20,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 104,
            assets: [
                SimAssetConfig(
                    id: "Cash",
                    label: "Cash",
                    startingValue: 100.0,
                    drift: -0.02,
                    volatility: 0.02,
                    lessonRole: .penalized,
                    kind: .cash
                ),
                SimAssetConfig(
                    id: "Savings Account",
                    label: "Savings Account",
                    startingValue: 100.0,
                    drift: 0.00,
                    volatility: 0.02,
                    lessonRole: .neutral,
                    kind: .savings
                ),
                SimAssetConfig(
                    id: "Inflation-Linked Bond",
                    label: "Inflation-Linked Bond",
                    startingValue: 100.0,
                    drift: 0.03,
                    volatility: 0.02,
                    lessonRole: .preferred,
                    kind: .bond
                )
            ],
            periodCount: 4,
            replayCount: 1,
            events: [
                SimulationEvent(period: 3, assetIDs: ["Cash"], kind: .multiplier(0.92)),
                SimulationEvent(period: 3, assetIDs: ["Savings Account"], kind: .multiplier(0.96)),
                SimulationEvent(period: 3, assetIDs: ["Inflation-Linked Bond"], kind: .multiplier(1.04))
            ],
            lessonBias: 0.20
        ),
        scoring: .portfolio,
        optimalDecision: .allocation([
            "Cash": 0.0,
            "Savings Account": 0.1,
            "Inflation-Linked Bond": 0.9
        ]),
        insightText: "Active reallocation — moving into inflation-linked assets before a spike — can protect purchasing power better than any single static allocation.",
        hintText: "Watch what happens to each asset during the high-inflation period.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 5: 30-year cumulative comparison (AC5)
    // New variable: Long time horizon showing compounding erosion

    static let stage5 = StageDefinition(
        address: StageAddress(phase: 1, stage: 5),
        scenario: .inflation(InflationScenario(
            title: "30 Years of Decisions",
            description: """
            The final test: two strategies over 30 years.
            • Strategy A: 100% Cash
            • Strategy B: Diversified (20% Cash, 30% Savings, 50% Inflation-Linked Bond)
            ₩10,000,000 invested. Which do you choose for the long run?
            """,
            inflationRates: [0.03],
            goods: [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "All Cash", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "Diversified", strategy: .directAsset("B"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 105,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "All Cash",
                    startingValue: 100.0,
                    drift: -0.03,
                    volatility: 0.015,
                    lessonRole: .penalized,
                    kind: .cash
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Diversified",
                    startingValue: 100.0,
                    drift: -0.03,
                    volatility: 0.015,
                    lessonRole: .preferred,
                    kind: .diversified
                )
            ],
            periodCount: 30,
            replayCount: 1,
            events: [],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),
        insightText: "Over 30 years, the compounding effect of inflation versus real returns creates an enormous wealth gap. Diversification is not just about risk — it's about surviving time.",
        hintText: "Think about 3% annual erosion compounded over 30 years.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4, stage5]
}
