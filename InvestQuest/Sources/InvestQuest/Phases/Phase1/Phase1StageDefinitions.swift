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
        phase: 1, stage: 1,
        scenarioTitle: "The Vanishing 10 Million",
        scenarioDescription: """
        You have ₩10,000,000 in cash.
        Inflation runs at 3% per year.
        Watch what happens to your purchasing power over 10 years.
        You have no choice but to hold cash in Stage 1.
        """,
        decisionType: .binary(optionA: "Observe", optionB: "Observe"),
        simulationConfig: StageConfig(
            seed: 101,
            assetCount: 1,   // Cash only
            timePeriods: 10,
            volatility: 0.005,        // Very smooth — clear educational signal
            drift: -0.03,             // 3% annual inflation erosion
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.5,
                description: "observe"
            )
        ),
        optimalDecision: .binary(choice: "observe"),
        timeoutSeconds: 0,
        insightText: "Your ₩10M lost real value every year — not because you spent it, but because inflation made everything more expensive. Holding cash is a slow loss.",
        hintText: "Watch the purchasing power line. It only goes one direction.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Allocate between Cash and Savings (AC2)
    // New variable: Savings account option

    static let stage2 = StageDefinition(
        phase: 1, stage: 2,
        scenarioTitle: "Cash vs. Savings",
        scenarioDescription: """
        You have ₩10,000,000 to allocate.
        Option A: Cash (loses ~3% purchasing power per year)
        Option B: Savings account (earns ~0.5% — barely offsets inflation)
        How do you split your money?
        """,
        decisionType: .allocationSlider(
            assets: ["Cash", "Savings Account"],
            totalBudget: 10_000_000
        ),
        simulationConfig: StageConfig(
            seed: 102,
            assetCount: 2,
            timePeriods: 10,
            volatility: 0.005,
            drift: -0.03,             // Cash: -3%
            // Savings is asset 1 — given positive drift via event offset below
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.65,
                description: "savings-heavy"
            )
        ),
        optimalDecision: .allocation(["Cash": 0.0, "Savings Account": 1.0]),
        timeoutSeconds: 30,
        insightText: "The savings account barely kept up with inflation — but it was still better than pure cash. Moving money to savings is a small but real improvement.",
        hintText: "One option keeps up with inflation slightly better than the other.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Add inflation-tracking asset (AC3)
    // New variable: Inflation-tracking asset

    static let stage3 = StageDefinition(
        phase: 1, stage: 3,
        scenarioTitle: "The Inflation Shield",
        scenarioDescription: """
        You have ₩10,000,000 to allocate across three options:
        • Cash: loses purchasing power every year
        • Savings Account: barely keeps up with inflation
        • Inflation-Linked Bond: designed to preserve and grow purchasing power
        How do you allocate?
        """,
        decisionType: .allocationSlider(
            assets: ["Cash", "Savings Account", "Inflation-Linked Bond"],
            totalBudget: 10_000_000
        ),
        simulationConfig: StageConfig(
            seed: 103,
            assetCount: 3,
            timePeriods: 10,
            volatility: 0.01,
            drift: -0.03,   // Cash base; asset 1 and 2 have better drift encoded in seed behavior
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "inflation-bond-heavy"
            )
        ),
        optimalDecision: .allocation([
            "Cash": 0.0,
            "Savings Account": 0.2,
            "Inflation-Linked Bond": 0.8
        ]),
        timeoutSeconds: 30,
        insightText: "The inflation-linked bond preserved and grew your purchasing power while cash kept eroding. Not all assets fight inflation equally.",
        hintText: "Which asset is designed specifically to track inflation?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Varying inflation across time periods (AC4)
    // New variable: Active reallocation across multiple periods

    static let stage4 = StageDefinition(
        phase: 1, stage: 4,
        scenarioTitle: "Inflation Rollercoaster",
        scenarioDescription: """
        Inflation is not constant. Over 4 periods:
        • Period 1-2: Low inflation (1%)
        • Period 3: High inflation spike (8%)
        • Period 4: Moderate (4%)
        Reallocate between Cash, Savings, and Inflation-Linked Bond each period.
        """,
        decisionType: .timed(
            underlying: .allocationSlider(
                assets: ["Cash", "Savings Account", "Inflation-Linked Bond"],
                totalBudget: 10_000_000
            ),
            timeoutSeconds: 20
        ),
        simulationConfig: StageConfig(
            seed: 104,
            assetCount: 3,
            timePeriods: 4,
            volatility: 0.02,
            drift: -0.02,   // Low baseline inflation
            eventInjections: [
                // Inflation spike in period 3
                StageConfig.EventInjection(period: 3, assetIndex: 0, magnitudeFactor: 0.92),  // Cash hit hard
                StageConfig.EventInjection(period: 3, assetIndex: 1, magnitudeFactor: 0.96),  // Savings slightly hit
                StageConfig.EventInjection(period: 3, assetIndex: 2, magnitudeFactor: 1.04)   // Bond benefits
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "shift-to-bond-before-spike"
            )
        ),
        optimalDecision: .allocation([
            "Cash": 0.0,
            "Savings Account": 0.1,
            "Inflation-Linked Bond": 0.9
        ]),
        timeoutSeconds: 20,
        insightText: "Active reallocation — moving into inflation-linked assets before a spike — can protect purchasing power better than any single static allocation.",
        hintText: "Watch what happens to each asset during the high-inflation period.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 5: 30-year cumulative comparison (AC5)
    // New variable: Long time horizon showing compounding erosion

    static let stage5 = StageDefinition(
        phase: 1, stage: 5,
        scenarioTitle: "30 Years of Decisions",
        scenarioDescription: """
        The final test: two strategies over 30 years.
        • Strategy A: 100% Cash
        • Strategy B: Diversified (20% Cash, 30% Savings, 50% Inflation-Linked Bond)
        ₩10,000,000 invested. Which do you choose for the long run?
        """,
        decisionType: .binary(
            optionA: "All Cash",
            optionB: "Diversified"
        ),
        simulationConfig: StageConfig(
            seed: 105,
            assetCount: 2,   // AllCash vs Diversified (represented as two composite assets)
            timePeriods: 30,
            volatility: 0.015,
            drift: -0.03,    // Cash baseline
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "diversified"
            )
        ),
        optimalDecision: .binary(choice: "B"),
        timeoutSeconds: 30,
        insightText: "Over 30 years, the compounding effect of inflation versus real returns creates an enormous wealth gap. Diversification is not just about risk — it's about surviving time.",
        hintText: "Think about 3% annual erosion compounded over 30 years.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4, stage5]
}
