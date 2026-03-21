import Foundation

/// All 4 stage definitions for Phase 4: Compounding.
///
/// Concept: small consistent gains accumulate exponentially over time.
/// Assets are encoded as two separate simulation tracks representing
/// different strategies (reinvest vs. withdraw, early vs. late start, etc.).
enum Phase4StageDefinitions {

    // MARK: - Post-phase concept card (AC5 / US-P4-001)

    static let conceptCardText = """
    Compounding is the process where your gains generate their own gains. \
    Over time, this creates exponential growth — not linear. \
    Starting early matters enormously: 10 extra years of compounding can \
    be worth more than doubling your contributions later. \
    Fees compound too — a 2% annual fee vs 0.5% costs hundreds of millions \
    of ₩ in absolute terms over 30 years. \
    Breaking compounding by withdrawing during a dip is one of the most \
    expensive mistakes an investor can make.
    """

    // MARK: - Stage 1: Withdraw vs. Reinvest over 20 years (AC1 / US-P4-001)

    static let stage1 = StageDefinition(
        address: StageAddress(phase: 4, stage: 1),
        scenario: .compounding(CompoundingScenario(
            title: "The Power of Reinvesting",
            description: """
            You have ₩10,000,000 invested in a fund earning ~8% per year.
            • Option A: Withdraw Profits — take gains out each year
            • Option B: Reinvest All — let gains compound for 20 years

            Both start with the same amount. What do you choose?
            """,
            comparisonHighlights: ["Reinvest vs withdraw", "20-year horizon", "Exponential vs linear growth"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Withdraw Profits", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "Reinvest All",     strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 401,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "Withdraw Profits",
                    drift: 0.08,
                    volatility: 0.10,
                    lessonRole: .penalized,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Reinvest All",
                    drift: 0.10,      // base 0.08 + 0.02 compounding advantage
                    volatility: 0.10,
                    lessonRole: .preferred,
                    kind: .fund
                )
            ],
            periodCount: 20,
            replayCount: 1,
            events: [],
            lessonBias: 0.25   // correctStrategyWeight 0.85 → 0.85 - 0.5 = 0.35, capped at 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),   // reinvest
        insightText: "Reinvesting turned ₩100 into far more than withdrawing over 20 years. Each year's gains became the base for next year's growth — that's compounding.",
        hintText: "Which option lets your gains generate their own gains?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Start at 25 vs. Start at 35, compare at 60 (AC2 / US-P4-001)

    static let stage2 = StageDefinition(
        address: StageAddress(phase: 4, stage: 2),
        scenario: .compounding(CompoundingScenario(
            title: "The 10-Year Head Start",
            description: """
            Two investors both retire at 60. Both earn 7% per year.
            • Option A: Start Now (age 25) — 35 years of compounding
            • Option B: Wait 10 Years (age 35) — 25 years of compounding

            Same annual contribution. Who ends up with more at age 60?
            """,
            comparisonHighlights: ["Early vs late start", "35 vs 25 years", "10-year head start value"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Start Now",         strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "Wait 10 Years",     strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 402,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "Start Now (age 25)",
                    drift: 0.07,
                    volatility: 0.12,
                    lessonRole: .preferred,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Wait 10 Years (age 35)",
                    drift: 0.04,      // base 0.07 - 0.03 late-start penalty
                    volatility: 0.12,
                    lessonRole: .penalized,
                    kind: .fund
                )
            ],
            periodCount: 35,    // full horizon from age 25 to 60
            replayCount: 1,
            events: [
                // Simulate the late starter's lost decade: asset B gets a large
                // negative shock at period 1 to represent missing 10 years of compounding
                SimulationEvent(
                    period: 1,
                    assetIDs: ["B"],
                    kind: .multiplier(0.70)
                )
            ],
            lessonBias: 0.25   // correctStrategyWeight 0.90 → 0.90 - 0.5 = 0.40, capped at 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "A"),   // start now
        insightText: "The 10-year head start advantage is worth more than doubling contributions later. Time is the most powerful input to compounding — and it can't be bought back.",
        hintText: "Compounding needs time. Every year you wait shrinks the base that grows.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Fee impact — 0.5% vs. 2% over 30 years (AC3 / US-P4-001)

    static let stage3 = StageDefinition(
        address: StageAddress(phase: 4, stage: 3),
        scenario: .compounding(CompoundingScenario(
            title: "The Fee Drain",
            description: """
            Two funds. Same gross return of 7% per year. Different fees.
            • Option A: Low Fee Fund — 0.5% annual fee (net return ≈ 6.5%)
            • Option B: High Fee Fund — 2.0% annual fee (net return ≈ 5.0%)

            Over 30 years on ₩10,000,000, the fee difference costs you tens of millions of ₩.
            Which fund do you choose?
            """,
            comparisonHighlights: ["Low fee vs high fee", "0.5% vs 2.0% annual fee", "30-year compounding drag"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Low Fee Fund",  strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "High Fee Fund", strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 403,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "Low Fee Fund (0.5%)",
                    drift: 0.065,     // 7% gross - 0.5% fee = 6.5% net
                    volatility: 0.12,
                    annualFee: 0.005,
                    lessonRole: .preferred,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "B",
                    label: "High Fee Fund (2.0%)",
                    drift: 0.05,      // base 0.065 - 0.015 fee drag = 0.05
                    volatility: 0.12,
                    annualFee: 0.02,
                    lessonRole: .penalized,
                    kind: .fund
                )
            ],
            periodCount: 30,
            replayCount: 1,
            events: [
                // High-fee fund (asset B) takes compounding drag hits each decade
                SimulationEvent(period: 1,  assetIDs: ["B"], kind: .multiplier(0.985)),
                SimulationEvent(period: 10, assetIDs: ["B"], kind: .multiplier(0.970)),
                SimulationEvent(period: 20, assetIDs: ["B"], kind: .multiplier(0.955))
            ],
            lessonBias: 0.25   // correctStrategyWeight 0.80 → 0.80 - 0.5 = 0.30, capped at 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "A"),   // low fee
        insightText: "Over 30 years, the 1.5% fee difference compounds into tens of millions of ₩ lost — not just in fees paid, but in the growth those fees could have generated. Fees compound too.",
        hintText: "A 2% fee vs 0.5% means 1.5% less compounding every single year for 30 years.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Temptation to withdraw during a dip (AC4 / US-P4-001)

    static let stage4 = StageDefinition(
        address: StageAddress(phase: 4, stage: 4),
        scenario: .compounding(CompoundingScenario(
            title: "The Dip Test",
            description: """
            Your long-term investment drops 40% at year 8.
            Analysts are split: some say it will recover, others say sell now.
            • Option A: Withdraw During Dip — exit and cut your losses
            • Option B: Hold and Wait — stay invested through the downturn

            History shows holding through dips usually wins — but it's hard in the moment.
            """,
            comparisonHighlights: ["Withdraw vs hold through dip", "40% drawdown recovery", "Breaking compounding chain"]
        )),
        decision: .binary(
            options: [
                DecisionOption(id: "A", label: "Withdraw During Dip", strategy: .directAsset("A")),
                DecisionOption(id: "B", label: "Hold and Wait",        strategy: .directAsset("B"))
            ],
            timeoutSeconds: nil,
            defaultDecision: .holdCash
        ),
        simulation: StageSimulation(
            seed: 404,
            assets: [
                SimAssetConfig(
                    id: "A",
                    label: "Withdraw During Dip",
                    drift: 0.08,
                    volatility: 0.15,
                    lessonRole: .penalized,
                    kind: .fund
                ),
                SimAssetConfig(
                    id: "B",
                    label: "Hold and Wait",
                    drift: 0.08,
                    volatility: 0.15,
                    lessonRole: .preferred,
                    kind: .fund
                )
            ],
            periodCount: 20,
            replayCount: 1,
            events: [
                // Big dip at period 8 — the temptation moment
                SimulationEvent(period: 8,  assetIDs: nil, kind: .multiplier(0.60)),
                // Recovery and continued growth from period 12
                SimulationEvent(period: 12, assetIDs: nil, kind: .multiplier(1.85))
            ],
            lessonBias: 0.25   // correctStrategyWeight 0.80 → 0.80 - 0.5 = 0.30, capped at 0.25
        ),
        scoring: .correctness,
        optimalDecision: .binary(choice: "B"),   // hold
        insightText: "The -40% dip recovered fully by year 12 and went on to strong gains. Withdrawing during the dip locked in the loss and broke the compounding chain permanently.",
        hintText: "If the fundamentals haven't changed, a dip is not a reason to stop compounding.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
