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
        phase: 4, stage: 1,
        scenarioTitle: "The Power of Reinvesting",
        scenarioDescription: """
        You have ₩10,000,000 invested in a fund earning ~8% per year.
        • Option A: Withdraw Profits — take gains out each year
        • Option B: Reinvest All — let gains compound for 20 years

        Both start with the same amount. What do you choose?
        """,
        decisionType: .binary(optionA: "Withdraw Profits", optionB: "Reinvest All"),
        simulationConfig: StageConfig(
            seed: 401,
            assetCount: 2,
            timePeriods: 20,
            volatility: 0.10,
            drift: 0.08,         // Reinvest track: full 8% drift (exponential compounding)
            eventInjections: [],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.85,
                description: "reinvest-all"
            )
        ),
        optimalDecision: .binary(choice: "B"),   // reinvest
        timeoutSeconds: 30,
        insightText: "Reinvesting turned ₩100 into far more than withdrawing over 20 years. Each year's gains became the base for next year's growth — that's compounding.",
        hintText: "Which option lets your gains generate their own gains?",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 2: Start at 25 vs. Start at 35, compare at 60 (AC2 / US-P4-001)

    static let stage2 = StageDefinition(
        phase: 4, stage: 2,
        scenarioTitle: "The 10-Year Head Start",
        scenarioDescription: """
        Two investors both retire at 60. Both earn 7% per year.
        • Option A: Start Now (age 25) — 35 years of compounding
        • Option B: Wait 10 Years (age 35) — 25 years of compounding

        Same annual contribution. Who ends up with more at age 60?
        """,
        decisionType: .binary(optionA: "Start Now", optionB: "Wait 10 Years"),
        simulationConfig: StageConfig(
            seed: 402,
            assetCount: 2,
            timePeriods: 35,     // full horizon from age 25 to 60
            volatility: 0.12,
            drift: 0.07,
            eventInjections: [
                // Simulate the late starter's lost decade: asset 1 gets a large
                // negative shock at period 1 to represent missing 10 years of compounding
                StageConfig.EventInjection(period: 1, assetIndex: 1, magnitudeFactor: 0.70)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.90,
                description: "start-now"
            )
        ),
        optimalDecision: .binary(choice: "A"),   // start now
        timeoutSeconds: 30,
        insightText: "The 10-year head start advantage is worth more than doubling contributions later. Time is the most powerful input to compounding — and it can't be bought back.",
        hintText: "Compounding needs time. Every year you wait shrinks the base that grows.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 3: Fee impact — 0.5% vs. 2% over 30 years (AC3 / US-P4-001)

    static let stage3 = StageDefinition(
        phase: 4, stage: 3,
        scenarioTitle: "The Fee Drain",
        scenarioDescription: """
        Two funds. Same gross return of 7% per year. Different fees.
        • Option A: Low Fee Fund — 0.5% annual fee (net return ≈ 6.5%)
        • Option B: High Fee Fund — 2.0% annual fee (net return ≈ 5.0%)

        Over 30 years on ₩10,000,000, the fee difference costs you tens of millions of ₩.
        Which fund do you choose?
        """,
        decisionType: .binary(optionA: "Low Fee Fund", optionB: "High Fee Fund"),
        simulationConfig: StageConfig(
            seed: 403,
            assetCount: 2,
            timePeriods: 30,
            volatility: 0.12,
            drift: 0.065,        // Asset 0 (low fee): 7% gross - 0.5% fee = 6.5% net
            // Asset 1 (high fee): represented via lower effective drift encoded via seed
            // Both assets share the global drift; high-fee drag encoded via event at period 1
            eventInjections: [
                // High-fee fund (asset 1) takes an immediate drag hit each decade
                StageConfig.EventInjection(period: 1,  assetIndex: 1, magnitudeFactor: 0.985),
                StageConfig.EventInjection(period: 10, assetIndex: 1, magnitudeFactor: 0.970),
                StageConfig.EventInjection(period: 20, assetIndex: 1, magnitudeFactor: 0.955)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "low-fee"
            )
        ),
        optimalDecision: .binary(choice: "A"),   // low fee
        timeoutSeconds: 30,
        insightText: "Over 30 years, the 1.5% fee difference compounds into tens of millions of ₩ lost — not just in fees paid, but in the growth those fees could have generated. Fees compound too.",
        hintText: "A 2% fee vs 0.5% means 1.5% less compounding every single year for 30 years.",
        conceptExplanation: conceptCardText
    )

    // MARK: - Stage 4: Temptation to withdraw during a dip (AC4 / US-P4-001)

    static let stage4 = StageDefinition(
        phase: 4, stage: 4,
        scenarioTitle: "The Dip Test",
        scenarioDescription: """
        Your long-term investment drops 40% at year 8.
        Analysts are split: some say it will recover, others say sell now.
        • Option A: Withdraw During Dip — exit and cut your losses
        • Option B: Hold and Wait — stay invested through the downturn

        History shows holding through dips usually wins — but it's hard in the moment.
        """,
        decisionType: .binary(optionA: "Withdraw During Dip", optionB: "Hold and Wait"),
        simulationConfig: StageConfig(
            seed: 404,
            assetCount: 1,
            timePeriods: 20,
            volatility: 0.15,
            drift: 0.08,
            eventInjections: [
                // Big dip at period 8 — the temptation moment
                StageConfig.EventInjection(period: 8,  assetIndex: 0, magnitudeFactor: 0.60),
                // Recovery and continued growth from period 12
                StageConfig.EventInjection(period: 12, assetIndex: 0, magnitudeFactor: 1.85)
            ],
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.80,
                description: "hold-through-dip"
            )
        ),
        optimalDecision: .binary(choice: "B"),   // hold
        timeoutSeconds: 30,
        insightText: "The -40% dip recovered fully by year 12 and went on to strong gains. Withdrawing during the dip locked in the loss and broke the compounding chain permanently.",
        hintText: "If the fundamentals haven't changed, a dip is not a reason to stop compounding.",
        conceptExplanation: conceptCardText
    )

    // MARK: - All stages

    static let all: [StageDefinition] = [stage1, stage2, stage3, stage4]
}
