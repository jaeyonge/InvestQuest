import Foundation

enum LessonRole: String, Codable, Equatable {
    case preferred
    case neutral
    case penalized
}

enum SimAssetKind: String, Codable, Equatable {
    case cash
    case savings
    case bond
    case equity
    case business
    case fund
    case diversified
    case sector
    case behavioral
    case generic
}

struct SimAssetConfig: Codable, Equatable, Identifiable {
    let id: String
    let label: String
    let startingValue: Double
    let drift: Double
    let volatility: Double
    let annualFee: Double
    let correlationGroup: String?
    let correlationStrength: Double
    let lessonRole: LessonRole
    let kind: SimAssetKind

    init(
        id: String,
        label: String,
        startingValue: Double = 100.0,
        drift: Double,
        volatility: Double,
        annualFee: Double = 0,
        correlationGroup: String? = nil,
        correlationStrength: Double = 0,
        lessonRole: LessonRole = .neutral,
        kind: SimAssetKind = .generic
    ) {
        self.id = id
        self.label = label
        self.startingValue = startingValue
        self.drift = drift
        self.volatility = volatility
        self.annualFee = annualFee
        self.correlationGroup = correlationGroup
        self.correlationStrength = correlationStrength
        self.lessonRole = lessonRole
        self.kind = kind
    }
}

enum SimulationEventKind: Codable, Equatable {
    case multiplier(Double)
    case driftShift(Double)
    case volatilityShift(Double)
    case feeDrag(Double)
    case bankruptcy(Double)
    case stopLossFloor(Double)
}

struct SimulationEvent: Codable, Equatable, Identifiable {
    let id: String
    let period: Int
    let assetIDs: [String]?
    let kind: SimulationEventKind
    let narrative: String?

    init(
        id: String = UUID().uuidString,
        period: Int,
        assetIDs: [String]? = nil,
        kind: SimulationEventKind,
        narrative: String? = nil
    ) {
        self.id = id
        self.period = period
        self.assetIDs = assetIDs
        self.kind = kind
        self.narrative = narrative
    }
}

struct StageSimulation: Codable, Equatable {
    let seed: UInt64
    let assets: [SimAssetConfig]
    let periodCount: Int
    let replayCount: Int
    let events: [SimulationEvent]
    let lessonBias: Double
}

// MARK: - Simulation Result

struct AssetPriceHistory: Codable, Equatable, Identifiable {
    let assetIndex: Int
    let assetID: String
    let prices: [Double]

    var id: String { assetID }
}

struct SimulationRun: Codable, Equatable, Identifiable {
    let seed: UInt64
    let assetHistories: [AssetPriceHistory]

    var id: UInt64 { seed }
}

struct SimulationResult: Codable, Equatable {
    let runs: [SimulationRun]
    let durationSeconds: Double

    var seed: UInt64 {
        runs.first?.seed ?? 0
    }

    var assetHistories: [AssetPriceHistory] {
        runs.first?.assetHistories ?? []
    }
}

// MARK: - Protocol

protocol MarketSimulationEngineProtocol {
    func simulate(stage: StageSimulation) -> SimulationResult
}
