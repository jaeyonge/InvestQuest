import Foundation
import SwiftData

/// Persisted record of a completed phase — used by Phase 7 behavioural review.
@Model
final class PhaseCompletionRecord {
    var phaseId: Int
    var conceptName: String
    var completedAt: Date
    var averageScore: Int
    var badgeIdentifier: String   // e.g. "badge.phase1"

    /// Serialised summary of decisions made during this phase (JSON-encodable).
    var decisionSummaryJSON: String

    init(phaseId: Int, conceptName: String, completedAt: Date = .now,
         averageScore: Int, badgeIdentifier: String, decisionSummaryJSON: String = "{}") {
        self.phaseId = phaseId
        self.conceptName = conceptName
        self.completedAt = completedAt
        self.averageScore = averageScore
        self.badgeIdentifier = badgeIdentifier
        self.decisionSummaryJSON = decisionSummaryJSON
    }
}

/// A single data point for the performance dashboard: player vs optimal.
struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let stageNumber: Int
    let playerScore: Int
    let optimalScore: Int       // always 100 by definition
}

/// Badge metadata.
struct Badge: Identifiable {
    let id: String              // e.g. "badge.phase1"
    let title: String
    let symbolName: String      // SF Symbol name
    let phaseId: Int
    let color: String           // hex string for colorblind-safe palette

    static let all: [Badge] = [
        Badge(id: "badge.phase1", title: "Inflation Fighter",   symbolName: "thermometer.sun", phaseId: 1, color: "#E07B39"),
        Badge(id: "badge.phase2", title: "Value Seeker",        symbolName: "magnifyingglass.circle", phaseId: 2, color: "#2E86AB"),
        Badge(id: "badge.phase3", title: "Risk Aware",          symbolName: "gauge.high", phaseId: 3, color: "#8338EC"),
        Badge(id: "badge.phase4", title: "Compound Master",     symbolName: "chart.line.uptrend.xyaxis", phaseId: 4, color: "#28A745"),
        Badge(id: "badge.phase5", title: "Exit Strategist",     symbolName: "arrow.down.circle", phaseId: 5, color: "#DC3545"),
        Badge(id: "badge.phase6", title: "Diversifier",         symbolName: "square.grid.2x2", phaseId: 6, color: "#17A2B8"),
        Badge(id: "badge.phase7", title: "Bias Buster",         symbolName: "brain.head.profile", phaseId: 7, color: "#FFC107")
    ]
}
