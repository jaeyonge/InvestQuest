import Foundation

/// Static configuration for each of the 7 phases.
struct PhaseConfig: Identifiable {
    let id: Int                      // 1-based phase number
    let title: String
    let concept: String              // plain-language concept name
    let stageCount: Int
    let minimumScoreToAdvance: Int   // 0–100; score required to unlock next stage
    let teaserDescription: String    // shown as preview before phase is unlocked

    static let all: [PhaseConfig] = [
        PhaseConfig(id: 1, title: "Cash Loses Value",
                    concept: "Inflation",
                    stageCount: 5,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Why does your money buy less every year?"),
        PhaseConfig(id: 2, title: "Price vs. Value",
                    concept: "Valuation",
                    stageCount: 5,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Price is what you pay. Value is what you get."),
        PhaseConfig(id: 3, title: "Risk and Return",
                    concept: "Risk-Return Tradeoff",
                    stageCount: 4,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Higher potential returns come with higher risk."),
        PhaseConfig(id: 4, title: "Compounding",
                    concept: "Compound Growth",
                    stageCount: 4,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Small consistent gains accumulate exponentially."),
        PhaseConfig(id: 5, title: "Knowing When to Exit",
                    concept: "Exit Discipline",
                    stageCount: 4,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Cut losses early, let winners run."),
        PhaseConfig(id: 6, title: "Diversification",
                    concept: "Portfolio Construction",
                    stageCount: 4,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Spreading investments reduces single-failure impact."),
        PhaseConfig(id: 7, title: "You Are Not Rational",
                    concept: "Behavioural Biases",
                    stageCount: 4,
                    minimumScoreToAdvance: 60,
                    teaserDescription: "Cognitive biases systematically distort decisions.")
    ]
}

/// A completed stage record: which phase/stage, score achieved, timestamp.
struct StageResult {
    let phase: Int
    let stage: Int
    let score: Int          // 0–100
    let completedAt: Date
}
