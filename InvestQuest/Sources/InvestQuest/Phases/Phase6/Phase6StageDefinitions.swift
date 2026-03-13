import Foundation

/// All 4 stage definitions for Phase 6: Diversification.
///
/// Concept: spreading investments reduces single-failure impact.
/// Correlated assets provide false diversification; real diversification
/// requires different asset classes that don't move in lockstep.
enum Phase6StageDefinitions {

    // MARK: - Post-phase concept card (AC: conceptCardText)

    static let conceptCardText = """
    Diversification means spreading your investments so that \
    a single failure cannot wipe out your portfolio. \
    When one asset crashes, others can absorb the blow.

    But not all diversification is real. \
    Correlation matters: assets that move together crash together. \
    Owning 5 tech stocks is not diversification — \
    they are highly correlated and all fall in the same sector downturn.

    True portfolio construction combines asset classes with low or negative \
    correlation: stocks, bonds, real estate, commodities. \
    When one falls, another often holds or rises.

    Diversification does not eliminate risk, but it reduces the impact \
    of any single failure on your overall portfolio.
    """

    // MARK: - Stage 1: All-in vs Split (AC1)
    // ₩10M budget, one attractive asset vs split across 5 assets.
    // All-in asset has a crash event at period 7; split asset does not.

    static let stage1 = StageDefinition(
        phase: 6, stage: 1,
        scenarioTitle: "All In or Spread Out?",
        scenarioDescription: """
        You have ₩10,000,000 to invest.
        Asset A looks very attractive — high growth so far.
        Option A: Put everything into that one asset.
        Option B: Split evenly across 5 different assets.
        One unexpected crash could change everything. Choose wisely.
        """,
        decisionType: .binary(
            optionA: "All In on Best Asset",
            optionB: "Split Across 5 Assets"
        ),
        simulationConfig: StageConfig(
            seed: 601,
            assetCount: 2,       // asset 0 = All In; asset 1 = Split (diversified)
            timePeriods: 10,
            volatility: 0.30,
            drift: 0.06,
            eventInjections: [
                // All-in asset crashes at period 7
                StageConfig.EventInjection(period: 7, assetIndex: 0, magnitudeFactor: 0.20)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.75,
                description: "split"
            )
        ),
        optimalDecision: .binary(choice: "B"),
        timeoutSeconds: 30,
        insightText: "The all-in asset looked great — until it crashed. Putting everything in one place means a single failure destroys your entire portfolio. Spreading across assets limits the damage any one event can cause.",
        hintText: "What happens to your money if the best-looking asset suddenly drops 80%?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: 20x simulation showing variance reduction (AC2)
    // Concentrated vs Diversified — replay makes variance reduction visible.

    static let stage2 = StageDefinition(
        phase: 6, stage: 2,
        scenarioTitle: "The Variance Experiment",
        scenarioDescription: """
        Run 20 simulations and watch the outcomes.
        Strategy A: Concentrated (all in 1 asset) — high highs, catastrophic lows.
        Strategy B: Diversified (10 assets) — more consistent, less dramatic swings.
        Variance across simulations reveals the true risk of each strategy.
        Which do you choose?
        """,
        decisionType: .binary(
            optionA: "Concentrated (1 asset)",
            optionB: "Diversified (10 assets)"
        ),
        simulationConfig: StageConfig(
            seed: 602,
            assetCount: 2,       // asset 0 = Concentrated; asset 1 = Diversified
            timePeriods: 10,
            volatility: 0.25,
            drift: 0.06,
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.70,
                description: "diversified"
            )
        ),
        optimalDecision: .binary(choice: "B"),
        timeoutSeconds: 30,
        insightText: "Across 20 simulations, the diversified portfolio showed far less variance — fewer catastrophic losses without sacrificing expected return. Diversification is free risk reduction.",
        hintText: "Look at the worst outcomes for each strategy across all 20 simulations.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Bankruptcy event — dramatic and memorable (AC3)
    // MegaCorp goes bankrupt (near-total loss). Diversified fund survives.

    static let stage3 = StageDefinition(
        phase: 6, stage: 3,
        scenarioTitle: "MegaCorp Goes Bankrupt",
        scenarioDescription: """
        MegaCorp has delivered 20% returns for 5 years straight.
        Investors are piling in. The future looks bright.
        Option A: All In on MegaCorp
        Option B: Diversified Fund (MegaCorp is 5% of the fund)
        What could go wrong?
        """,
        decisionType: .binary(
            optionA: "All In on MegaCorp",
            optionB: "Diversified Fund"
        ),
        simulationConfig: StageConfig(
            seed: 603,
            assetCount: 2,       // asset 0 = MegaCorp (concentrated); asset 1 = Diversified Fund
            timePeriods: 8,
            volatility: 0.15,
            drift: 0.05,
            eventInjections: [
                // MegaCorp bankruptcy at period 6 — near total loss
                StageConfig.EventInjection(period: 6, assetIndex: 0, magnitudeFactor: 0.01),
                // Diversified fund takes a small hit (MegaCorp was 5% of fund)
                StageConfig.EventInjection(period: 6, assetIndex: 1, magnitudeFactor: 0.85)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.90,
                description: "diversified-fund"
            )
        ),
        optimalDecision: .binary(choice: "B"),
        timeoutSeconds: 30,
        insightText: "MegaCorp went bankrupt. The concentrated portfolio lost everything. The diversified fund lost only 15% — MegaCorp was just 5% of its holdings. The fund survived. The concentrated bet did not.",
        hintText: "Even the best-performing companies can fail completely. What protects you when they do?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: False diversification — 5 correlated tech stocks (AC4)
    // 5 tech stocks are correlated — they crash together.
    // Truly diversified portfolio (stocks + bonds + real estate) survives.

    static let stage4 = StageDefinition(
        phase: 6, stage: 4,
        scenarioTitle: "The Correlation Trap",
        scenarioDescription: """
        You own 5 different tech stocks. That's diversified, right?
        Option A: 5 Tech Stocks (different companies, same sector)
        Option B: Stocks + Bonds + Real Estate (different asset classes)
        A sector-wide crash is coming. Which portfolio is truly protected?
        """,
        decisionType: .binary(
            optionA: "5 Tech Stocks",
            optionB: "Stocks + Bonds + Real Estate"
        ),
        simulationConfig: StageConfig(
            seed: 604,
            assetCount: 2,       // asset 0 = 5 correlated tech stocks; asset 1 = truly diversified
            timePeriods: 8,
            volatility: 0.20,
            drift: 0.06,
            eventInjections: [
                // Tech sector crash at period 5 — all 5 stocks fall together (false diversification)
                StageConfig.EventInjection(period: 5, assetIndex: 0, magnitudeFactor: 0.50)
                // asset 1 (truly diversified) has no crash — bonds and real estate hold
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "truly-diversified"
            )
        ),
        optimalDecision: .binary(choice: "B"),
        timeoutSeconds: 30,
        insightText: "5 tech stocks are correlated — they crash together. Real diversification requires different asset classes that don't move in lockstep. When the tech sector fell 50%, bonds and real estate held steady.",
        hintText: "Do all 5 stocks move in the same direction when tech news hits? That tells you how correlated they are.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
