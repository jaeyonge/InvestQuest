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
        address: StageAddress(phase: 6, stage: 1),
        scenario: .diversification(DiversificationScenario(
            title: "All In or Spread Out?",
            description: """
            You have ₩10,000,000 to invest.
            Asset A looks very attractive — high growth so far.
            Option A: Put everything into that one asset.
            Option B: Split evenly across 5 different assets.
            One unexpected crash could change everything. Choose wisely.
            """,
            sectorNotes: []
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "All In on Best Asset", strategy: .directAsset("all-in")),
                DecisionOption(id: "B", label: "Split Across 5 Assets", strategy: .directAsset("split"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 601,
            assets: [
                SimAssetConfig(
                    id: "all-in",
                    label: "All In on Best Asset",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.30,
                    lessonRole: .penalized,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "split",
                    label: "Split Across 5 Assets",
                    startingValue: 100.0,
                    drift: 0.07,
                    volatility: 0.30,
                    lessonRole: .preferred,
                    kind: .diversified
                )
            ],
            periodCount: 10,
            replayCount: 1,
            events: [
                SimulationEvent(
                    period: 7,
                    assetIDs: ["all-in"],
                    kind: .multiplier(0.20)
                )
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),
        insightText: "The all-in asset looked great — until it crashed. Putting everything in one place means a single failure destroys your entire portfolio. Spreading across assets limits the damage any one event can cause.",
        hintText: "What happens to your money if the best-looking asset suddenly drops 80%?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: 20x simulation showing variance reduction (AC2)
    // Concentrated vs Diversified — replay makes variance reduction visible.

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 6, stage: 2),
        scenario: .diversification(DiversificationScenario(
            title: "The Variance Experiment",
            description: """
            Run 20 simulations and watch the outcomes.
            Strategy A: Concentrated (all in 1 asset) — high highs, catastrophic lows.
            Strategy B: Diversified (10 assets) — more consistent, less dramatic swings.
            Variance across simulations reveals the true risk of each strategy.
            Which do you choose?
            """,
            sectorNotes: []
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Concentrated (1 asset)", strategy: .directAsset("concentrated")),
                DecisionOption(id: "B", label: "Diversified (10 assets)", strategy: .directAsset("diversified"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 602,
            assets: [
                SimAssetConfig(
                    id: "concentrated",
                    label: "Concentrated (1 asset)",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.25,
                    lessonRole: .penalized,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "diversified",
                    label: "Diversified (10 assets)",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.25,
                    lessonRole: .preferred,
                    kind: .diversified
                )
            ],
            periodCount: 10,
            replayCount: 20,
            events: [],
            lessonBias: 0.20
        ),
        scoring: .portfolio,
        optimalDecision: .binary(choice: "B"),
        insightText: "Across 20 simulations, the diversified portfolio showed far less variance — fewer catastrophic losses without sacrificing expected return. Diversification is free risk reduction.",
        hintText: "Look at the worst outcomes for each strategy across all 20 simulations.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Bankruptcy event — dramatic and memorable (AC3)
    // MegaCorp goes bankrupt (near-total loss). Diversified fund survives.

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 6, stage: 3),
        scenario: .diversification(DiversificationScenario(
            title: "MegaCorp Goes Bankrupt",
            description: """
            MegaCorp has delivered 20% returns for 5 years straight.
            Investors are piling in. The future looks bright.
            Option A: All In on MegaCorp
            Option B: Diversified Fund (MegaCorp is 5% of the fund)
            What could go wrong?
            """,
            sectorNotes: []
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "All In on MegaCorp", strategy: .directAsset("concentrated")),
                DecisionOption(id: "B", label: "Diversified Fund", strategy: .directAsset("diversified-fund"))
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 603,
            assets: [
                SimAssetConfig(
                    id: "concentrated",
                    label: "All In on MegaCorp",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.15,
                    lessonRole: .penalized,
                    kind: .equity
                ),
                SimAssetConfig(
                    id: "diversified-fund",
                    label: "Diversified Fund",
                    startingValue: 100.0,
                    drift: 0.05,
                    volatility: 0.15,
                    lessonRole: .preferred,
                    kind: .fund
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // MegaCorp bankruptcy at period 6 — near total loss
                SimulationEvent(
                    period: 6,
                    assetIDs: ["concentrated"],
                    kind: .bankruptcy(0.02)
                ),
                // Diversified fund takes a small hit (MegaCorp was 5% of fund)
                SimulationEvent(
                    period: 6,
                    assetIDs: ["diversified-fund"],
                    kind: .multiplier(0.85)
                )
            ],
            lessonBias: 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),
        insightText: "MegaCorp went bankrupt. The concentrated portfolio lost everything. The diversified fund lost only 15% — MegaCorp was just 5% of its holdings. The fund survived. The concentrated bet did not.",
        hintText: "Even the best-performing companies can fail completely. What protects you when they do?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: False diversification — 5 correlated tech stocks (AC4)
    // 5 tech stocks are correlated — they crash together.
    // Truly diversified portfolio (stocks + bonds + real estate) survives.

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 6, stage: 4),
        scenario: .diversification(DiversificationScenario(
            title: "The Correlation Trap",
            description: """
            You own 5 different tech stocks. That's diversified, right?
            Option A: 5 Tech Stocks (different companies, same sector)
            Option B: Stocks + Bonds + Real Estate (different asset classes)
            A sector-wide crash is coming. Which portfolio is truly protected?
            """,
            sectorNotes: ["tech", "multi-class"]
        )),
        decision: .ranking(
            assets: [
                DecisionAsset(id: "tech-a", label: "TechCorp A"),
                DecisionAsset(id: "tech-b", label: "TechCorp B"),
                DecisionAsset(id: "tech-c", label: "TechCorp C"),
                DecisionAsset(id: "tech-d", label: "TechCorp D"),
                DecisionAsset(id: "tech-e", label: "TechCorp E"),
                DecisionAsset(id: "bond", label: "Government Bond")
            ],
            timeoutSeconds: 30,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 604,
            assets: [
                // First tech asset gets +0.08 volatility offset per legacy table (6,4,0)
                SimAssetConfig(
                    id: "tech-a",
                    label: "TechCorp A",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.28,
                    correlationGroup: "tech",
                    correlationStrength: 0.85,
                    lessonRole: .penalized,
                    kind: .sector
                ),
                SimAssetConfig(
                    id: "tech-b",
                    label: "TechCorp B",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.20,
                    correlationGroup: "tech",
                    correlationStrength: 0.85,
                    lessonRole: .penalized,
                    kind: .sector
                ),
                SimAssetConfig(
                    id: "tech-c",
                    label: "TechCorp C",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.20,
                    correlationGroup: "tech",
                    correlationStrength: 0.85,
                    lessonRole: .penalized,
                    kind: .sector
                ),
                SimAssetConfig(
                    id: "tech-d",
                    label: "TechCorp D",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.20,
                    correlationGroup: "tech",
                    correlationStrength: 0.85,
                    lessonRole: .penalized,
                    kind: .sector
                ),
                SimAssetConfig(
                    id: "tech-e",
                    label: "TechCorp E",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.20,
                    correlationGroup: "tech",
                    correlationStrength: 0.85,
                    lessonRole: .penalized,
                    kind: .sector
                ),
                SimAssetConfig(
                    id: "bond",
                    label: "Government Bond",
                    startingValue: 100.0,
                    drift: 0.06,
                    volatility: 0.20,
                    correlationGroup: nil,
                    correlationStrength: 0.1,
                    lessonRole: .preferred,
                    kind: .bond
                )
            ],
            periodCount: 8,
            replayCount: 1,
            events: [
                // Tech sector crash at period 5 — all 5 stocks fall together (false diversification)
                SimulationEvent(
                    period: 5,
                    assetIDs: ["tech-a", "tech-b", "tech-c", "tech-d", "tech-e"],
                    kind: .multiplier(0.50)
                )
                // bond (truly diversified) has no crash — holds steady
            ],
            lessonBias: 0.25
        ),
        scoring: .rankingDistance,
        optimalDecision: .binary(choice: "B"),
        insightText: "5 tech stocks are correlated — they crash together. Real diversification requires different asset classes that don't move in lockstep. When the tech sector fell 50%, bonds and real estate held steady.",
        hintText: "Do all 5 stocks move in the same direction when tech news hits? That tells you how correlated they are.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
