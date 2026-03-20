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

    init(phaseId: Int) {
        guard let config = PhaseConfig.all.first(where: { $0.id == phaseId }) else {
            fatalError("Invalid phaseId: \(phaseId)")
        }
        self.completedPhaseConfig = config
        self.nextPhaseConfig = PhaseConfig.all.first(where: { $0.id == phaseId + 1 })
        self.badge = Badge.all.first(where: { $0.phaseId == phaseId })
    }

    func loadPerformance(modelContext: ModelContext) {
        let phaseID = completedPhaseConfig.id
        let descriptor = FetchDescriptor<StageCompletionRecord>(
            predicate: #Predicate { $0.phase == phaseID },
            sortBy: [SortDescriptor(\.stage, order: .forward)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        performanceData = records.map {
            PerformanceDataPoint(stageNumber: $0.stage, playerScore: $0.latestScore, optimalScore: 100)
        }
        averageScore = records.isEmpty ? 0 : records.map(\.latestScore).reduce(0, +) / records.count
    }

    // MARK: - Persist

    /// Saves the phase completion record to SwiftData for Phase 7 retrieval.
    func persistCompletion(modelContext: ModelContext) {
        guard let badge = badge else { return }
        let phaseID = completedPhaseConfig.id
        let descriptor = FetchDescriptor<PhaseCompletionRecord>(
            predicate: #Predicate { $0.phaseId == phaseID }
        )
        if (try? modelContext.fetch(descriptor).isEmpty) == false {
            isPersisted = true
            return
        }

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
