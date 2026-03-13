import Foundation
import SwiftData

@MainActor
final class PhaseCompletionViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var completedPhaseConfig: PhaseConfig
    @Published private(set) var nextPhaseConfig: PhaseConfig?
    @Published private(set) var badge: Badge?
    @Published private(set) var performanceData: [PerformanceDataPoint] = []
    @Published private(set) var averageScore: Int = 0
    @Published private(set) var isPersisted: Bool = false

    // MARK: - Init

    init(phaseId: Int, stageResults: [StageResult]) {
        guard let config = PhaseConfig.all.first(where: { $0.id == phaseId }) else {
            fatalError("Invalid phaseId: \(phaseId)")
        }
        self.completedPhaseConfig = config
        self.nextPhaseConfig = PhaseConfig.all.first(where: { $0.id == phaseId + 1 })
        self.badge = Badge.all.first(where: { $0.phaseId == phaseId })

        // Build performance data: player score per stage vs optimal (100)
        let phaseResults = stageResults.filter { $0.phase == phaseId }
            .sorted { $0.stage < $1.stage }
        self.performanceData = phaseResults.map { result in
            PerformanceDataPoint(
                stageNumber: result.stage,
                playerScore: result.score,
                optimalScore: 100
            )
        }
        self.averageScore = phaseResults.isEmpty ? 0 :
            phaseResults.map(\.score).reduce(0, +) / phaseResults.count
    }

    // MARK: - Persist

    /// Saves the phase completion record to SwiftData for Phase 7 retrieval.
    func persistCompletion(modelContext: ModelContext) {
        guard let badge = badge else { return }

        // Encode decision summary as simple JSON
        let summaryDict = performanceData.reduce(into: [String: Int]()) { dict, point in
            dict["stage\(point.stageNumber)"] = point.playerScore
        }
        let json = (try? String(data: JSONEncoder().encode(summaryDict), encoding: .utf8)) ?? "{}"

        let record = PhaseCompletionRecord(
            phaseId: completedPhaseConfig.id,
            conceptName: completedPhaseConfig.concept,
            averageScore: averageScore,
            badgeIdentifier: badge.id,
            decisionSummaryJSON: json
        )
        modelContext.insert(record)
        try? modelContext.save()
        isPersisted = true
    }
}
