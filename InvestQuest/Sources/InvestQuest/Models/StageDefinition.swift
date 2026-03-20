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

    static func fromLegacy(
        decisionType: DecisionType,
        timeoutSeconds: Double,
        assetIDs: [String],
        assetLabels: [String]
    ) -> DecisionSpec {
        func directAssetStrategy(for index: Int) -> DecisionStrategy {
            guard index < assetIDs.count else { return .cash }
            return .directAsset(assetIDs[index])
        }

        func legacyBinaryOptions(a: String, b: String) -> [DecisionOption] {
            if assetIDs.count == 1, a == b {
                return [
                    DecisionOption(id: "observe", label: a, strategy: directAssetStrategy(for: 0)),
                    DecisionOption(id: "observe.alt", label: b, strategy: directAssetStrategy(for: 0))
                ]
            }

            if assetIDs.count == 1 {
                return [
                    DecisionOption(id: "A", label: a, strategy: directAssetStrategy(for: 0)),
                    DecisionOption(id: "B", label: b, strategy: .cash)
                ]
            }

            return [
                DecisionOption(id: "A", label: a, strategy: directAssetStrategy(for: 0)),
                DecisionOption(id: "B", label: b, strategy: directAssetStrategy(for: 1))
            ]
        }

        switch decisionType {
        case .binary(let optionA, let optionB):
            if optionA == optionB {
                return .observe(
                    label: optionA,
                    actionID: "observe",
                    timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                    defaultDecision: .holdCash
                )
            }

            return .binary(
                options: legacyBinaryOptions(a: optionA, b: optionB),
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .allocationSlider(let assets, let totalBudget):
            return .allocation(
                assets: zip(assetIDs, assets).map { DecisionAsset(id: $0.0, label: $0.1) },
                totalBudget: totalBudget,
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .multiAssetRanking(let assets):
            return .ranking(
                assets: zip(assetIDs, assets).map { DecisionAsset(id: $0.0, label: $0.1) },
                timeoutSeconds: timeoutSeconds > 0 ? timeoutSeconds : nil,
                defaultDecision: .holdCash
            )
        case .timed(let underlying, let timeoutSeconds):
            switch underlying {
            case .binary(let optionA, let optionB):
                return .binary(
                    options: legacyBinaryOptions(a: optionA, b: optionB),
                    timeoutSeconds: timeoutSeconds,
                    defaultDecision: .holdCash
                )
            case .allocationSlider(let assets, let totalBudget):
                return .allocation(
                    assets: zip(assetIDs, assets).map { DecisionAsset(id: $0.0, label: $0.1) },
                    totalBudget: totalBudget,
                    timeoutSeconds: timeoutSeconds,
                    defaultDecision: .holdCash
                )
            }
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

    static func legacy(phase: Int, stage: Int, title: String, description: String) -> StageScenario {
        switch phase {
        case 1:
            let inflationRates: [Double]
            if phase == 1 && stage == 4 {
                inflationRates = [0.01, 0.01, 0.08, 0.04]
            } else {
                inflationRates = [0.03]
            }

            let goods = [
                InflationGood(id: "rice", label: "Rice", startingPrice: 10_000, endingPrice: 13_000),
                InflationGood(id: "coffee", label: "Coffee", startingPrice: 4_000, endingPrice: 5_600),
                InflationGood(id: "rent", label: "Rent", startingPrice: 900_000, endingPrice: 1_250_000)
            ]
            return .inflation(
                InflationScenario(title: title, description: description, inflationRates: inflationRates, goods: goods)
            )
        case 2:
            let opportunities: [Phase2Opportunity]
            switch stage {
            case 1: opportunities = [Phase2OpportunityFactory.fruitStand()]
            case 2: opportunities = Phase2OpportunityFactory.allBusinesses()
            case 3: opportunities = [Phase2OpportunityFactory.overpriced(), Phase2OpportunityFactory.fruitStand()]
            case 4: opportunities = [Phase2OpportunityFactory.hiddenInfo()]
            default: opportunities = [Phase2OpportunityFactory.fruitStand()]
            }
            return .valuation(ValuationScenario(title: title, description: description, opportunities: opportunities))
        case 3:
            return .risk(
                RiskScenario(
                    title: title,
                    description: description,
                    distributions: ["Narrow", "Balanced", "Wide tail"]
                )
            )
        case 4:
            return .compounding(
                CompoundingScenario(
                    title: title,
                    description: description,
                    comparisonHighlights: ["Reinvest vs withdraw", "Early vs late start", "Low fee vs high fee"]
                )
            )
        case 5:
            return .exit(
                ExitScenario(
                    title: title,
                    description: description,
                    prompts: ["Cut losses early", "Let winners run", "Use rules before emotion"]
                )
            )
        case 6:
            return .diversification(
                DiversificationScenario(
                    title: title,
                    description: description,
                    sectorNotes: ["Concentration risk", "Variance smoothing", "Correlation trap"]
                )
            )
        default:
            return .behavioral(
                BehavioralScenario(
                    title: title,
                    description: description,
                    biasCues: ["Urgency", "FOMO", "Anchoring", "Loss aversion"],
                    isReviewStage: phase == 7 && stage == 4
                )
            )
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

    static func infer(phase: Int, stage: Int, decisionType: DecisionType) -> StageScoringRule {
        if phase == 7 && stage == 4 {
            return .reviewCompletion
        }

        switch decisionType {
        case .multiAssetRanking:
            return .rankingDistance
        case .allocationSlider:
            return .portfolio
        case .binary, .timed:
            if phase == 2 && stage == 1 {
                return .valuationError(targetValue: 200_000_000)
            }
            return .correctness
        }
    }
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
    var simulationConfig: StageConfig { simulation.legacyConfig }
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

    init(
        phase: Int,
        stage: Int,
        scenarioTitle: String,
        scenarioDescription: String,
        decisionType: DecisionType,
        simulationConfig: StageConfig,
        optimalDecision: PlayerDecision,
        timeoutSeconds: Double,
        insightText: String,
        hintText: String,
        conceptExplanation: String
    ) {
        let assetIDs = StageDefinition.legacyAssetIDs(for: decisionType, assetCount: simulationConfig.assetCount)
        let assetLabels = StageDefinition.legacyAssetLabels(for: decisionType, assetIDs: assetIDs)
        let decision = DecisionSpec.fromLegacy(
            decisionType: decisionType,
            timeoutSeconds: timeoutSeconds,
            assetIDs: assetIDs,
            assetLabels: assetLabels
        )

        self.init(
            address: StageAddress(phase: phase, stage: stage),
            scenario: StageScenario.legacy(phase: phase, stage: stage, title: scenarioTitle, description: scenarioDescription),
            decision: decision,
            simulation: StageSimulation.fromLegacy(
                config: simulationConfig,
                phase: phase,
                stage: stage,
                assetIDs: assetIDs,
                assetLabels: assetLabels
            ),
            scoring: StageScoringRule.infer(phase: phase, stage: stage, decisionType: decisionType),
            optimalDecision: optimalDecision,
            insightText: insightText,
            hintText: hintText,
            conceptExplanation: conceptExplanation
        )
    }

    private static func legacyAssetIDs(for decisionType: DecisionType, assetCount: Int) -> [String] {
        switch decisionType {
        case .binary:
            if assetCount == 1 { return ["core"] }
            return (0..<assetCount).map { $0 == 0 ? "A" : ($0 == 1 ? "B" : "asset\($0)") }
        case .allocationSlider(let assets, _):
            return assets
        case .multiAssetRanking(let assets):
            return assets
        case .timed(let underlying, _):
            switch underlying {
            case .binary:
                if assetCount == 1 { return ["core"] }
                return (0..<assetCount).map { $0 == 0 ? "A" : ($0 == 1 ? "B" : "asset\($0)") }
            case .allocationSlider(let assets, _):
                return assets
            }
        }
    }

    private static func legacyAssetLabels(for decisionType: DecisionType, assetIDs: [String]) -> [String] {
        switch decisionType {
        case .binary(let optionA, let optionB):
            if assetIDs.count == 1 { return [optionA] }
            return [optionA, optionB] + Array(assetIDs.dropFirst(2))
        case .allocationSlider(let assets, _):
            return assets
        case .multiAssetRanking(let assets):
            return assets
        case .timed(let underlying, _):
            switch underlying {
            case .binary(let optionA, let optionB):
                if assetIDs.count == 1 { return [optionA] }
                return [optionA, optionB] + Array(assetIDs.dropFirst(2))
            case .allocationSlider(let assets, _):
                return assets
            }
        }
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

// MARK: - Legacy Simulation Conversion

extension StageSimulation {
    static func fromLegacy(
        config: StageConfig,
        phase: Int,
        stage: Int,
        assetIDs: [String],
        assetLabels: [String]
    ) -> StageSimulation {
        let replayCount: Int
        switch (phase, stage) {
        case (3, 1): replayCount = 10
        case (6, 2): replayCount = 20
        default: replayCount = 1
        }

        let preferredAssetIndex: Int?
        switch config.outcomeWeight.description {
        case "diversified", "savings-heavy", "inflation-bond-heavy", "balanced", "low-fee":
            preferredAssetIndex = min(max(config.assetCount - 1, 0), 1)
        default:
            preferredAssetIndex = nil
        }

        let assets = (0..<config.assetCount).map { index in
            let id = index < assetIDs.count ? assetIDs[index] : "asset\(index)"
            let label = index < assetLabels.count ? assetLabels[index] : id
            let role: LessonRole
            if preferredAssetIndex == index {
                role = .preferred
            } else if preferredAssetIndex != nil {
                role = .penalized
            } else {
                role = .neutral
            }

            return SimAssetConfig(
                id: id,
                label: label,
                drift: config.drift + StageSimulation.legacyDriftOffset(for: phase, stage: stage, index: index),
                volatility: max(0.001, config.volatility + StageSimulation.legacyVolatilityOffset(for: phase, stage: stage, index: index)),
                annualFee: StageSimulation.legacyAnnualFee(for: phase, stage: stage, index: index),
                correlationGroup: StageSimulation.legacyCorrelationGroup(for: phase, stage: stage, index: index),
                correlationStrength: StageSimulation.legacyCorrelationStrength(for: phase, stage: stage, index: index),
                lessonRole: role,
                kind: StageSimulation.legacyKind(for: label)
            )
        }

        let events = config.eventInjections.map { event in
            let affected: [String]?
            if event.assetIndex == -1 {
                affected = nil
            } else if event.assetIndex < assets.count {
                affected = [assets[event.assetIndex].id]
            } else {
                affected = nil
            }

            return SimulationEvent(
                period: event.period,
                assetIDs: affected,
                kind: event.magnitudeFactor <= 0.05
                    ? .bankruptcy(event.magnitudeFactor)
                    : .multiplier(event.magnitudeFactor)
            )
        }

        return StageSimulation(
            seed: config.seed,
            assets: assets,
            periodCount: config.timePeriods,
            replayCount: replayCount,
            events: events,
            lessonBias: max(0, config.outcomeWeight.correctStrategyWeight - 0.5)
        )
    }

    var legacyConfig: StageConfig {
        StageConfig(
            seed: seed,
            assetCount: assets.count,
            timePeriods: periodCount,
            volatility: assets.first?.volatility ?? 0.1,
            drift: assets.first?.drift ?? 0,
            eventInjections: events.map { event in
                let assetIndex: Int
                if let firstID = event.assetIDs?.first,
                   let index = assets.firstIndex(where: { $0.id == firstID }) {
                    assetIndex = index
                } else {
                    assetIndex = -1
                }

                let magnitudeFactor: Double
                switch event.kind {
                case .multiplier(let factor),
                     .bankruptcy(let factor):
                    magnitudeFactor = factor
                case .driftShift,
                     .volatilityShift,
                     .feeDrag,
                     .stopLossFloor:
                    magnitudeFactor = 1.0
                }

                return StageConfig.EventInjection(
                    period: event.period,
                    assetIndex: assetIndex,
                    magnitudeFactor: magnitudeFactor
                )
            },
            outcomeWeight: StageConfig.OutcomeWeight(
                correctStrategyWeight: 0.5 + lessonBias,
                description: "legacy"
            )
        )
    }

    private static func legacyKind(for label: String) -> SimAssetKind {
        let text = label.lowercased()
        if text.contains("cash") { return .cash }
        if text.contains("saving") { return .savings }
        if text.contains("bond") { return .bond }
        if text.contains("fund") || text.contains("index") { return .fund }
        if text.contains("divers") { return .diversified }
        if text.contains("tech") { return .sector }
        if text.contains("business") || text.contains("fruit") || text.contains("bakery") || text.contains("café") {
            return .business
        }
        if text.contains("fomo") || text.contains("leaderboard") || text.contains("review") {
            return .behavioral
        }
        return .equity
    }

    private static func legacyDriftOffset(for phase: Int, stage: Int, index: Int) -> Double {
        switch (phase, stage, index) {
        case (1, 2, 1): return 0.02
        case (1, 3, 1): return 0.02
        case (1, 3, 2): return 0.05
        case (1, 4, 1): return 0.02
        case (1, 4, 2): return 0.05
        case (4, 1, 1): return 0.02
        case (4, 2, 1): return -0.03
        case (4, 3, 1): return -0.015
        case (6, 1, 1): return 0.01
        default: return 0
        }
    }

    private static func legacyVolatilityOffset(for phase: Int, stage: Int, index: Int) -> Double {
        switch (phase, stage, index) {
        case (3, 1, 0): return -0.03
        case (3, 1, 1): return 0.06
        case (3, 1, 2): return 0.18
        case (6, 4, 0): return 0.08
        default: return 0
        }
    }

    private static func legacyAnnualFee(for phase: Int, stage: Int, index: Int) -> Double {
        switch (phase, stage, index) {
        case (4, 3, 0): return 0.005
        case (4, 3, 1): return 0.02
        default: return 0
        }
    }

    private static func legacyCorrelationGroup(for phase: Int, stage: Int, index: Int) -> String? {
        switch (phase, stage) {
        case (6, 4):
            return index == 0 ? "tech" : nil
        default:
            return nil
        }
    }

    private static func legacyCorrelationStrength(for phase: Int, stage: Int, index: Int) -> Double {
        switch (phase, stage) {
        case (6, 4):
            return index == 0 ? 0.85 : 0.1
        default:
            return 0
        }
    }
}
