import Foundation
import SwiftData

/// Persists the player's overall phase/stage progress.
@Model
final class GameProgress {
    var currentPhase: Int
    var currentStage: Int
    var completedPhases: [Int]
    var lastPlayedDate: Date
    var hasSeenIntro: Bool

    init(currentPhase: Int = 1,
         currentStage: Int = 1,
         completedPhases: [Int] = [],
         lastPlayedDate: Date = .now,
         hasSeenIntro: Bool = false) {
        self.currentPhase = currentPhase
        self.currentStage = currentStage
        self.completedPhases = completedPhases
        self.lastPlayedDate = lastPlayedDate
        self.hasSeenIntro = hasSeenIntro
    }
}

/// Records a single decision made by the player for Phase 7 behavioural review.
@Model
final class DecisionRecord {
    var phase: Int
    var stage: Int
    var decisionType: String
    var value: Double
    var optimalValue: Double
    var timestamp: Date

    init(phase: Int, stage: Int, decisionType: String,
         value: Double, optimalValue: Double, timestamp: Date = .now) {
        self.phase = phase
        self.stage = stage
        self.decisionType = decisionType
        self.value = value
        self.optimalValue = optimalValue
        self.timestamp = timestamp
    }
}
