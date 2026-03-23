import Foundation

struct StageAddress: Hashable, Codable, Identifiable {
    let phase: Int
    let stage: Int

    var id: String { "\(phase)-\(stage)" }
}

// MARK: - Decision Types

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

struct DecisionAsset: Codable, Equatable, Identifiable {
    let id: String
    let label: String
}

enum DecisionStrategy: Codable, Equatable {
    case directAsset(String)
    case portfolio([String: Double])
    case cash
}

struct DecisionOption: Codable, Equatable, Identifiable {
    let id: String
    let label: String
    let strategy: DecisionStrategy
}

enum DecisionSpec: Codable, Equatable {
    case observe(label: String, actionID: String, timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case binary(options: [DecisionOption], timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case allocation(assets: [DecisionAsset], totalBudget: Double, timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case ranking(assets: [DecisionAsset], timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case valuation(options: [DecisionOption], timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case stopLoss(options: [DecisionOption], suggestedThreshold: Double, timeoutSeconds: Double?, defaultDecision: PlayerDecision)
    case review(options: [DecisionOption], timeoutSeconds: Double?, defaultDecision: PlayerDecision)

    var timeoutSeconds: Double? {
        switch self {
        case .observe(_, _, let timeoutSeconds, _),
             .binary(_, let timeoutSeconds, _),
             .allocation(_, _, let timeoutSeconds, _),
             .ranking(_, let timeoutSeconds, _),
             .valuation(_, let timeoutSeconds, _),
             .stopLoss(_, _, let timeoutSeconds, _),
             .review(_, let timeoutSeconds, _):
            return timeoutSeconds
        }
    }

    var defaultDecision: PlayerDecision {
        switch self {
        case .observe(_, _, _, let defaultDecision),
             .binary(_, _, let defaultDecision),
             .allocation(_, _, _, let defaultDecision),
             .ranking(_, _, let defaultDecision),
             .valuation(_, _, let defaultDecision),
             .stopLoss(_, _, _, let defaultDecision),
             .review(_, _, let defaultDecision):
            return defaultDecision
        }
    }

    var legacyDecisionType: DecisionType {
        switch self {
        case .observe(let label, _, let timeoutSeconds, _):
            if let timeoutSeconds {
                return .timed(underlying: .binary(optionA: label, optionB: label), timeoutSeconds: timeoutSeconds)
            }
            return .binary(optionA: label, optionB: label)
        case .binary(let options, let timeoutSeconds, _):
            let first = options.first?.label ?? "Option A"
            let second = options.dropFirst().first?.label ?? "Option B"
            if let timeoutSeconds {
                return .timed(underlying: .binary(optionA: first, optionB: second), timeoutSeconds: timeoutSeconds)
            }
            return .binary(optionA: first, optionB: second)
        case .allocation(let assets, let totalBudget, let timeoutSeconds, _):
            let names = assets.map(\.label)
            if let timeoutSeconds {
                return .timed(
                    underlying: .allocationSlider(assets: names, totalBudget: totalBudget),
                    timeoutSeconds: timeoutSeconds
                )
            }
            return .allocationSlider(assets: names, totalBudget: totalBudget)
        case .ranking(let assets, _, _):
            return .multiAssetRanking(assets: assets.map(\.label))
        case .valuation(let options, let timeoutSeconds, _):
            let first = options.first?.label ?? "Buy"
            let second = options.dropFirst().first?.label ?? "Pass"
            if let timeoutSeconds {
                return .timed(underlying: .binary(optionA: first, optionB: second), timeoutSeconds: timeoutSeconds)
            }
            return .binary(optionA: first, optionB: second)
        case .stopLoss(let options, _, let timeoutSeconds, _):
            let first = options.first?.label ?? "Set Stop-Loss"
            let second = options.dropFirst().first?.label ?? "No Stop-Loss"
            if let timeoutSeconds {
                return .timed(underlying: .binary(optionA: first, optionB: second), timeoutSeconds: timeoutSeconds)
            }
            return .binary(optionA: first, optionB: second)
        case .review(let options, let timeoutSeconds, _):
            let first = options.first?.label ?? "Review"
            let second = options.dropFirst().first?.label ?? "Skip"
            if let timeoutSeconds {
                return .timed(underlying: .binary(optionA: first, optionB: second), timeoutSeconds: timeoutSeconds)
            }
            return .binary(optionA: first, optionB: second)
        }
    }

    func option(for id: String) -> DecisionOption? {
        switch self {
        case .binary(let options, _, _),
             .valuation(let options, _, _),
             .stopLoss(let options, _, _, _),
             .review(let options, _, _):
            return options.first { $0.id == id }
        case .observe(let label, let actionID, _, _):
            return DecisionOption(id: actionID, label: label, strategy: .cash)
        case .allocation, .ranking:
            return nil
        }
    }

}

// MARK: - Player Decision

enum PlayerDecision: Equatable, Codable {
    case binary(choice: String)
    case allocation([String: Double])
    case ranking([String])
    case valuation(estimatedValue: Double, actionID: String)
    case stopLoss(threshold: Double, actionID: String)
    case review(actionID: String)
    case holdCash

    private enum CodingKeys: String, CodingKey {
        case kind
        case choice
        case allocation
        case ranking
        case estimatedValue
        case actionID
        case threshold
    }

    private enum Kind: String, Codable {
        case binary
        case allocation
        case ranking
        case valuation
        case stopLoss
        case review
        case holdCash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .binary:
            self = .binary(choice: try container.decode(String.self, forKey: .choice))
        case .allocation:
            self = .allocation(try container.decode([String: Double].self, forKey: .allocation))
        case .ranking:
            self = .ranking(try container.decode([String].self, forKey: .ranking))
        case .valuation:
            self = .valuation(
                estimatedValue: try container.decode(Double.self, forKey: .estimatedValue),
                actionID: try container.decode(String.self, forKey: .actionID)
            )
        case .stopLoss:
            self = .stopLoss(
                threshold: try container.decode(Double.self, forKey: .threshold),
                actionID: try container.decode(String.self, forKey: .actionID)
            )
        case .review:
            self = .review(actionID: try container.decode(String.self, forKey: .actionID))
        case .holdCash:
            self = .holdCash
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .binary(let choice):
            try container.encode(Kind.binary, forKey: .kind)
            try container.encode(choice, forKey: .choice)
        case .allocation(let allocation):
            try container.encode(Kind.allocation, forKey: .kind)
            try container.encode(allocation, forKey: .allocation)
        case .ranking(let ranking):
            try container.encode(Kind.ranking, forKey: .kind)
            try container.encode(ranking, forKey: .ranking)
        case .valuation(let estimatedValue, let actionID):
            try container.encode(Kind.valuation, forKey: .kind)
            try container.encode(estimatedValue, forKey: .estimatedValue)
            try container.encode(actionID, forKey: .actionID)
        case .stopLoss(let threshold, let actionID):
            try container.encode(Kind.stopLoss, forKey: .kind)
            try container.encode(threshold, forKey: .threshold)
            try container.encode(actionID, forKey: .actionID)
        case .review(let actionID):
            try container.encode(Kind.review, forKey: .kind)
            try container.encode(actionID, forKey: .actionID)
        case .holdCash:
            try container.encode(Kind.holdCash, forKey: .kind)
        }
    }
}

// MARK: - Scenario Types

struct InflationGood: Codable, Equatable, Identifiable {
    let id: String
    let label: String
    let startingPrice: Double
    let endingPrice: Double
}

struct InflationScenario: Codable, Equatable {
    let title: String
    let description: String
    let inflationRates: [Double]
    let goods: [InflationGood]
}

struct ValuationScenario: Codable, Equatable {
    let title: String
    let description: String
    let opportunities: [Phase2Opportunity]
}

struct RiskScenario: Codable, Equatable {
    let title: String
    let description: String
    let distributions: [String]
}

struct CompoundingScenario: Codable, Equatable {
    let title: String
    let description: String
    let comparisonHighlights: [String]
}

struct ExitScenario: Codable, Equatable {
    let title: String
    let description: String
    let prompts: [String]
}

struct DiversificationScenario: Codable, Equatable {
    let title: String
    let description: String
    let sectorNotes: [String]
}

struct BehavioralScenario: Codable, Equatable {
    let title: String
    let description: String
    let biasCues: [String]
    let isReviewStage: Bool
}

enum StageScenario: Codable, Equatable {
    case inflation(InflationScenario)
    case valuation(ValuationScenario)
    case risk(RiskScenario)
    case compounding(CompoundingScenario)
    case exit(ExitScenario)
    case diversification(DiversificationScenario)
    case behavioral(BehavioralScenario)

    var title: String {
        switch self {
        case .inflation(let scenario): return scenario.title
        case .valuation(let scenario): return scenario.title
        case .risk(let scenario): return scenario.title
        case .compounding(let scenario): return scenario.title
        case .exit(let scenario): return scenario.title
        case .diversification(let scenario): return scenario.title
        case .behavioral(let scenario): return scenario.title
        }
    }

    var description: String {
        switch self {
        case .inflation(let scenario): return scenario.description
        case .valuation(let scenario): return scenario.description
        case .risk(let scenario): return scenario.description
        case .compounding(let scenario): return scenario.description
        case .exit(let scenario): return scenario.description
        case .diversification(let scenario): return scenario.description
        case .behavioral(let scenario): return scenario.description
        }
    }

}

// MARK: - Scoring

enum StageScoringRule: Codable, Equatable {
    case portfolio
    case correctness
    case rankingDistance
    case valuationError(targetValue: Double)
    case reviewCompletion

}

// MARK: - Stage Definition

struct StageDefinition {
    let address: StageAddress
    let scenario: StageScenario
    let decision: DecisionSpec
    let simulation: StageSimulation
    let scoring: StageScoringRule
    let optimalDecision: PlayerDecision
    let insightText: String
    let hintText: String
    let conceptExplanation: String
    let minimumPassingScore: Int

    var phase: Int { address.phase }
    var stage: Int { address.stage }
    var scenarioTitle: String { scenario.title }
    var scenarioDescription: String { scenario.description }
    var decisionType: DecisionType { decision.legacyDecisionType }
    var timeoutSeconds: Double { decision.timeoutSeconds ?? 0 }

    init(
        address: StageAddress,
        scenario: StageScenario,
        decision: DecisionSpec,
        simulation: StageSimulation,
        scoring: StageScoringRule,
        optimalDecision: PlayerDecision,
        insightText: String,
        hintText: String,
        conceptExplanation: String,
        minimumPassingScore: Int = 60
    ) {
        self.address = address
        self.scenario = scenario
        self.decision = decision
        self.simulation = simulation
        self.scoring = scoring
        self.optimalDecision = optimalDecision
        self.insightText = insightText
        self.hintText = hintText
        self.conceptExplanation = conceptExplanation
        self.minimumPassingScore = minimumPassingScore
    }

}

// MARK: - Stage Result

struct ReplayStats: Equatable, Codable {
    let minimum: Double
    let median: Double
    let maximum: Double
}

struct StageOutcome: Equatable, Codable {
    let playerDecision: PlayerDecision
    let portfolioFinalValue: Double
    let optimalFinalValue: Double
    let score: Int
    let starRating: Int
    let passed: Bool
    let replayStats: ReplayStats?
    let biasTags: [String]

    static func starRating(for score: Int) -> Int {
        switch score {
        case 80...100: return 3
        case 50..<80:  return 2
        default:       return 1
        }
    }

    static func score(portfolioFinal: Double, optimalFinal: Double, startValue: Double) -> Int {
        guard optimalFinal > startValue else { return 50 }
        let playerReturn = (portfolioFinal - startValue) / startValue
        let optimalReturn = (optimalFinal - startValue) / startValue
        guard optimalReturn != 0 else { return 50 }
        let ratio = playerReturn / optimalReturn
        return min(100, max(0, Int(ratio * 100)))
    }
}

enum AllocationMath {

    static func roundedAllocation(_ allocation: [String: Double], assetIDs: [String]) -> [String: Double] {
        roundedPercentages(allocation, assetIDs: assetIDs).mapValues { Double($0) / 100 }
    }

    static func roundedPercentages(_ allocation: [String: Double], assetIDs: [String]) -> [String: Int] {
        let orderedIDs = orderedAssetIDs(assetIDs, extrasFrom: allocation)
        guard !orderedIDs.isEmpty else { return [:] }

        let normalized = normalizedAllocation(allocation, assetIDs: orderedIDs)
        var percentages = orderedIDs.reduce(into: [String: Int]()) { partial, assetID in
            let rawValue = (normalized[assetID] ?? 0) * 100
            partial[assetID] = Int(floor(rawValue))
        }

        let rankedRemainders = orderedIDs.enumerated()
            .map { index, assetID -> (assetID: String, remainder: Double, index: Int) in
                let rawValue = (normalized[assetID] ?? 0) * 100
                return (assetID, rawValue - floor(rawValue), index)
            }
            .sorted { lhs, rhs in
                if abs(lhs.remainder - rhs.remainder) > 0.000_001 {
                    return lhs.remainder > rhs.remainder
                }
                return lhs.index < rhs.index
            }

        var remaining = 100 - percentages.values.reduce(0, +)
        for item in rankedRemainders where remaining > 0 {
            percentages[item.assetID, default: 0] += 1
            remaining -= 1
        }

        return percentages
    }

    static func matches(_ lhs: [String: Double], _ rhs: [String: Double], assetIDs: [String]) -> Bool {
        let orderedIDs = orderedAssetIDs(assetIDs, extrasFrom: lhs.merging(rhs) { current, _ in current })
        return roundedPercentages(lhs, assetIDs: orderedIDs) == roundedPercentages(rhs, assetIDs: orderedIDs)
    }

    private static func normalizedAllocation(_ allocation: [String: Double], assetIDs: [String]) -> [String: Double] {
        let orderedIDs = orderedAssetIDs(assetIDs, extrasFrom: allocation)
        let total = max(
            orderedIDs.reduce(0.0) { partial, assetID in
                partial + max(allocation[assetID] ?? 0, 0)
            },
            0.000_001
        )

        return orderedIDs.reduce(into: [String: Double]()) { partial, assetID in
            partial[assetID] = max(allocation[assetID] ?? 0, 0) / total
        }
    }

    private static func orderedAssetIDs(_ assetIDs: [String], extrasFrom allocation: [String: Double]) -> [String] {
        let extras = allocation.keys
            .filter { !assetIDs.contains($0) }
            .sorted()
        return assetIDs + extras
    }
}
