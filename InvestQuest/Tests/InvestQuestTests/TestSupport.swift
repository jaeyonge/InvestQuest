import Foundation
import SwiftData
@testable import InvestQuest

enum TestDataFactory {
    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: GameProgress.self,
            DecisionRecord.self,
            StageCompletionRecord.self,
            StageSessionRecord.self,
            PhaseCompletionRecord.self,
            configurations: config
        )
    }

    @MainActor
    static func makeService(
        progress: GameProgress = GameProgress()
    ) throws -> (container: ModelContainer, context: ModelContext, service: GameProgressService) {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(progress)
        try context.save()
        let service = GameProgressService(modelContext: context, progress: progress)
        return (container, context, service)
    }

    static func makeOutcome(
        score: Int,
        decision: PlayerDecision = .binary(choice: "A"),
        optimal: PlayerDecision = .binary(choice: "A"),
        portfolioFinalValue: Double = 120,
        optimalFinalValue: Double = 130,
        biasTags: [String] = []
    ) -> StageOutcome {
        StageOutcome(
            playerDecision: decision,
            portfolioFinalValue: portfolioFinalValue,
            optimalFinalValue: optimalFinalValue,
            score: score,
            starRating: StageOutcome.starRating(for: score),
            passed: decision == optimal || score >= 60,
            replayStats: nil,
            biasTags: biasTags
        )
    }

    static func binaryOptions(from definition: StageDefinition) -> (String, String)? {
        switch definition.decisionType {
        case .binary(let first, let second):
            return (first, second)
        case .timed(let underlying, _):
            guard case .binary(let first, let second) = underlying else { return nil }
            return (first, second)
        case .allocationSlider, .multiAssetRanking:
            return nil
        }
    }

    static func allocationOptions(from definition: StageDefinition) -> ([String], Double)? {
        switch definition.decisionType {
        case .allocationSlider(let assets, let budget):
            return (assets, budget)
        case .timed(let underlying, _):
            guard case .allocationSlider(let assets, let budget) = underlying else { return nil }
            return (assets, budget)
        case .binary, .multiAssetRanking:
            return nil
        }
    }

    static func rankingAssets(from definition: StageDefinition) -> [String]? {
        guard case .multiAssetRanking(let assets) = definition.decisionType else { return nil }
        return assets
    }
}
