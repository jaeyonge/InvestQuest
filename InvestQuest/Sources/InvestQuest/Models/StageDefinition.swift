import Foundation

// MARK: - Decision Types

/// The interaction types a Decision Screen can present.
enum DecisionType: Equatable {
    case binary(optionA: String, optionB: String)
    case allocationSlider(assets: [String], totalBudget: Double)
    case multiAssetRanking(assets: [String])
    case timed(underlying: TimedDecisionKind, timeoutSeconds: Double)

    enum TimedDecisionKind: Equatable {
        case binary(optionA: String, optionB: String)
        case allocationSlider(assets: [String], totalBudget: Double)
    }
}

// MARK: - Player Decision

/// The player's submitted response for a given DecisionType.
enum PlayerDecision: Equatable {
    case binary(choice: String)               // "A" or "B"
    case allocation([String: Double])         // asset name → fraction (sum ≤ 1.0)
    case ranking([String])                    // ordered asset names
    case holdCash                             // timeout default
}

// MARK: - Stage Definition

/// Static description of a single gameplay stage.
struct StageDefinition {
    let phase: Int
    let stage: Int
    let scenarioTitle: String
    let scenarioDescription: String
    let decisionType: DecisionType
    let simulationConfig: StageConfig
    let optimalDecision: PlayerDecision
    let timeoutSeconds: Double               // 0 = no timeout
    let insightText: String
    let hintText: String                     // shown after 3 failures
    let conceptExplanation: String           // shown after 5 failures
}

// MARK: - Stage Result

struct StageOutcome {
    let playerDecision: PlayerDecision
    let portfolioFinalValue: Double
    let optimalFinalValue: Double
    let score: Int                           // 0–100
    let starRating: Int                      // 1–3

    static func starRating(for score: Int) -> Int {
        switch score {
        case 80...100: return 3
        case 50..<80:  return 2
        default:       return 1
        }
    }

    static func score(portfolioFinal: Double, optimalFinal: Double, startValue: Double) -> Int {
        guard optimalFinal > startValue else { return 50 }
        let playerReturn  = (portfolioFinal - startValue) / startValue
        let optimalReturn = (optimalFinal - startValue) / startValue
        guard optimalReturn != 0 else { return 50 }
        let ratio = playerReturn / optimalReturn
        return min(100, max(0, Int(ratio * 100)))
    }
}
