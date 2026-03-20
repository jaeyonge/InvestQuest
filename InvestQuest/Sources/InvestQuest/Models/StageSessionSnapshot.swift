import Foundation

enum StageFlowSnapshotState: String, Codable, Equatable {
    case briefing
    case decision
    case simulation
    case result
    case insight
}

struct StageSessionSnapshot: Codable, Equatable {
    let address: StageAddress
    let flowState: StageFlowSnapshotState
    let currentPeriod: Int
    let failureCount: Int
    let pendingDecision: PlayerDecision?
    let timeRemaining: Double
}
