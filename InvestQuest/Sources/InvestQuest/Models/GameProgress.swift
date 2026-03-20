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
    var playerDecisionJSON: String
    var optimalDecisionJSON: String
    var score: Int
    var decisionLatencyMs: Int
    var outcomeJSON: String
    var biasTags: [String]
    var timestamp: Date

    init(
        phase: Int,
        stage: Int,
        decisionType: String,
        playerDecisionJSON: String,
        optimalDecisionJSON: String,
        score: Int,
        decisionLatencyMs: Int,
        outcomeJSON: String,
        biasTags: [String] = [],
        timestamp: Date = .now
    ) {
        self.phase = phase
        self.stage = stage
        self.decisionType = decisionType
        self.playerDecisionJSON = playerDecisionJSON
        self.optimalDecisionJSON = optimalDecisionJSON
        self.score = score
        self.decisionLatencyMs = decisionLatencyMs
        self.outcomeJSON = outcomeJSON
        self.biasTags = biasTags
        self.timestamp = timestamp
    }
}

@Model
final class StageCompletionRecord {
    var phase: Int
    var stage: Int
    var latestScore: Int
    var bestScore: Int
    var latestStars: Int
    var bestStars: Int
    var isPassed: Bool
    var completedAt: Date

    init(
        phase: Int,
        stage: Int,
        latestScore: Int,
        bestScore: Int,
        latestStars: Int,
        bestStars: Int,
        isPassed: Bool,
        completedAt: Date = .now
    ) {
        self.phase = phase
        self.stage = stage
        self.latestScore = latestScore
        self.bestScore = bestScore
        self.latestStars = latestStars
        self.bestStars = bestStars
        self.isPassed = isPassed
        self.completedAt = completedAt
    }
}

@Model
final class StageSessionRecord {
    var phase: Int
    var stage: Int
    var flowState: String
    var currentPeriod: Int
    var failureCount: Int
    var pendingDecisionJSON: String?
    var timeRemaining: Double
    var savedAt: Date

    init(
        phase: Int,
        stage: Int,
        flowState: String,
        currentPeriod: Int,
        failureCount: Int,
        pendingDecisionJSON: String?,
        timeRemaining: Double,
        savedAt: Date = .now
    ) {
        self.phase = phase
        self.stage = stage
        self.flowState = flowState
        self.currentPeriod = currentPeriod
        self.failureCount = failureCount
        self.pendingDecisionJSON = pendingDecisionJSON
        self.timeRemaining = timeRemaining
        self.savedAt = savedAt
    }
}
